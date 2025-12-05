import 'package:bak/widgets/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../auth/token_provider.dart';
import '../auth/auth_provider.dart';
import '../utils/network_helper.dart';
import '../exceptions.dart';

class TokenInterceptor extends Interceptor {
  final dynamic ref;
  static bool _isRefreshing = false;
  static final List<Function> _pendingRequests = [];

  TokenInterceptor(this.ref);

  /// 🔄 MANUAL REFRESH with retry logic and proper error handling
  Future<String?> manualRefresh({int retryCount = 0}) async {
    // Prevent concurrent refresh attempts
    if (_isRefreshing) {
      if (kDebugMode) {
        print("⏳ Token refresh already in progress, waiting...");
      }
      // Wait for ongoing refresh to complete
      await Future.delayed(const Duration(milliseconds: 500));
      return await TokenStorage.getAccessToken();
    }

    _isRefreshing = true;

    try {
      final refreshToken = await TokenStorage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        if (kDebugMode) {
          print("❌ No refresh token available");
        }
        return null;
      }

      if (kDebugMode) {
        print("🔄 Attempting token refresh (attempt ${retryCount + 1}/3)");
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://pastry-pros-backend.vercel.app/api',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await dio.post(
        '/auth/refresh-token',
        data: {"refreshToken": refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final newAccessToken = response.data["token"];
        final newRefreshToken = response.data["refreshToken"] ?? refreshToken;

        if (newAccessToken == null || newAccessToken.isEmpty) {
          throw Exception("Invalid token received from server");
        }

        // Save to both storage systems for consistency
        await TokenStorage.saveTokens(newAccessToken, newRefreshToken);
        await ref
            .read(authProvider.notifier)
            .saveTokens(newAccessToken, newRefreshToken);
        ref.read(tokenProvider.notifier).updateToken(newAccessToken);

        if (kDebugMode) {
          print("✅ Token refresh successful");
        }

        // Process any pending requests
        _processPendingRequests();

        return newAccessToken;
      } else {
        throw Exception("Invalid response from refresh endpoint");
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print("❌ Token refresh failed: ${e.message}");
        print("   Status: ${e.response?.statusCode}");
        print("   Data: ${e.response?.data}");
      }

      // Check for network connectivity issues
      final hasNetwork = await NetworkHelper.hasConnection();
      if (!hasNetwork) {
        if (kDebugMode) {
          print("❌ No network connection available");
        }
        throw NetworkException(NetworkHelper.getNetworkErrorMessage());
      }

      // Retry with exponential backoff for network errors
      if (retryCount < 2 && _shouldRetry(e)) {
        final delayMs = (retryCount + 1) * 1000; // 1s, 2s
        if (kDebugMode) {
          print("⏳ Retrying in ${delayMs}ms...");
        }
        await Future.delayed(Duration(milliseconds: delayMs));
        _isRefreshing = false;
        return await manualRefresh(retryCount: retryCount + 1);
      }

      // Throw user-friendly error for auth failures
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw AuthException("Your session has expired. Please log in again.");
      }

      // Throw user-friendly error for server errors
      if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        throw ServerException(
          "Server is temporarily unavailable. Please try again later.",
        );
      }

      throw NetworkException(
        "Unable to refresh session. Please check your connection and try again.",
      );
    } catch (e) {
      if (kDebugMode) {
        print("❌ Unexpected error during token refresh: $e");
      }

      // Re-throw if it's already a custom exception
      if (e is NetworkException || e is AuthException || e is ServerException) {
        rethrow;
      }

      throw NetworkException("An unexpected error occurred. Please try again.");
    } finally {
      _isRefreshing = false;
    }
  }

  /// Determine if error is retryable
  bool _shouldRetry(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.response?.statusCode != null && e.response!.statusCode! >= 500);
  }

  /// Process pending requests after successful refresh
  void _processPendingRequests() {
    for (var callback in _pendingRequests) {
      callback();
    }
    _pendingRequests.clear();
  }

  /// Auto request refresh (for 401 errors)
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    if (kDebugMode) {
      print("🔐 401 Unauthorized - attempting token refresh");
    }

    // If already refreshing, queue this request
    if (_isRefreshing) {
      if (kDebugMode) {
        print("⏳ Queueing request until refresh completes");
      }
      _pendingRequests.add(() async {
        final token = await TokenStorage.getAccessToken();
        if (token != null) {
          err.requestOptions.headers["Authorization"] = "Bearer $token";
          try {
            final retryResponse = await Dio().fetch(err.requestOptions);
            handler.resolve(retryResponse);
          } catch (e) {
            handler.next(err);
          }
        } else {
          handler.next(err);
        }
      });
      return;
    }

    final newToken = await manualRefresh();

    if (newToken == null) {
      if (kDebugMode) {
        print("❌ Token refresh failed, propagating 401 error");
      }
      return handler.next(err);
    }

    // Retry the original request with new token
    try {
      if (kDebugMode) {
        print("🔄 Retrying original request with new token");
      }
      final req = err.requestOptions;
      req.headers["Authorization"] = "Bearer $newToken";

      final retryDio = Dio(
        BaseOptions(
          baseUrl: req.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final retryResponse = await retryDio.fetch(req);
      return handler.resolve(retryResponse);
    } catch (e) {
      if (kDebugMode) {
        print("❌ Retry failed: $e");
      }
      return handler.next(err);
    }
  }
}
