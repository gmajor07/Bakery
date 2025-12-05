import 'package:flutter/material.dart';
import '../utils/network_helper.dart';

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const NetworkErrorWidget({super.key, this.onRetry, this.customMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'No Internet Connection',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              customMessage ?? NetworkHelper.getNetworkErrorMessage(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Show a network error snackbar
void showNetworkErrorSnackbar(BuildContext context, {String? customMessage}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              customMessage ?? NetworkHelper.getNetworkErrorMessage(),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.red.shade700,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}
