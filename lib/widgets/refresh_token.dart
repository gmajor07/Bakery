import 'package:bak/widgets/token_storage.dart';
import 'package:dio/dio.dart';
import '../auth/token_provider.dart';

class TokenInterceptor extends Interceptor {
  final dynamic ref;

  TokenInterceptor(this.ref);

  /// 🔄 MANUAL REFRESH (used by TokenErrorWidget)
  Future<String?> manualRefresh() async {
    final refreshToken = await TokenStorage.getRefreshToken();

    if (refreshToken == null) return null;

    try {
      final dio = Dio();
      final response = await dio.post(
        'https://pastry-pros-backend.vercel.app/api',
        data: {"refresh_token": refreshToken},
      );

      final newToken = response.data["access_token"];

      await TokenStorage.saveTokens(newToken, refreshToken);
      ref.read(tokenProvider.notifier).updateToken(newToken);

      return newToken;
    } catch (e) {
      return null;
    }
  }

  /// Auto request refresh (for 401 errors)
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final newToken = await manualRefresh();

    if (newToken == null) {
      return handler.next(err);
    }

    // retry request with new token
    final req = err.requestOptions;
    req.headers["Authorization"] = "Bearer $newToken";
    final retryResponse = await Dio().fetch(req);

    return handler.resolve(retryResponse);
  }
}
