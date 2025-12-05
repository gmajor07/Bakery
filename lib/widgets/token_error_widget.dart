import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../widgets/refresh_token.dart'; // Assuming TokenInterceptor is here
import '../screens/login_screen.dart';
import '../theme.dart'; // Assuming AppTheme is available

class TokenErrorWidget extends ConsumerWidget {
  const TokenErrorWidget({super.key});

  // --- Helper function for Refreshing Token ---
  Future<void> _tryRefresh(BuildContext context, WidgetRef ref) async {
    // Show a loading dialog instead of snackbar for better UX
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Refreshing session..."),
              ],
            ),
          ),
        ),
      ),
    );

    final interceptor = TokenInterceptor(ref);
    final newToken = await interceptor.manualRefresh();

    // Close loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (!context.mounted) return;

    if (newToken != null && newToken.isNotEmpty) {
      // ✅ Success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text("Session restored! Reloading data...")),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 2),
        ),
      );

      // Give a moment for the snackbar to show, then close dialog
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } else {
      // ❌ Failure feedback - show error but keep dialog open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Session refresh failed. Please log in again to continue.",
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // --- Helper function for Logout ---
  void _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).logout();

    // Navigate to Login and clear the navigation stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the theme's color scheme
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Card(
          // Use a slightly larger border radius for a modern feel
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons
              children: [
                // 1. Icon and Title
                Icon(
                  Icons
                      .person_off_outlined, // A slightly more modern, neutral icon
                  size: 64,
                  color: colorScheme.error, // Use error color for severity
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  "Session Expired",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle/Instructions
                Text(
                  "Your authentication session has expired. Try refreshing to restore your session, or log in again if that doesn't work.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 32),

                // 2. Primary Action: Refresh Token
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppTheme.primaryBrown, // Use a custom primary color
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _tryRefresh(context, ref),
                  child: const Text(
                    "Try Auto-Refresh",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 12),

                // 3. Secondary Action: Log In Again
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBrown,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppTheme.primaryBrown, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _logout(context, ref),
                  child: const Text(
                    "Log In Again",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
