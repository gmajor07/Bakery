import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkHelper {
  static final Connectivity _connectivity = Connectivity();

  /// Check if device has network connectivity
  static Future<bool> hasConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      // Check if any connection type is available
      final hasConnection =
          connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet);

      if (kDebugMode) {
        print(
          "🌐 Network status: ${hasConnection ? 'Connected' : 'Disconnected'}",
        );
        print("   Connection types: $connectivityResult");
      }

      return hasConnection;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error checking network connectivity: $e");
      }
      // Assume connected if we can't check (fail open)
      return true;
    }
  }

  /// Get user-friendly network error message
  static String getNetworkErrorMessage() {
    return "No internet connection. Please check your network settings and try again.";
  }

  /// Get connectivity stream for real-time monitoring
  static Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }

  /// Check if specific connectivity result indicates connection
  static bool isConnected(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
  }
}
