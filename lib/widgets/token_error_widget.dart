import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../widgets/refresh_token.dart';
import '../screens/login_screen.dart';

class TokenErrorWidget extends ConsumerWidget {
  const TokenErrorWidget({super.key});

  Future<void> _tryRefresh(BuildContext context, WidgetRef ref) async {
    final interceptor = TokenInterceptor(ref);

    final newToken = await interceptor.manualRefresh();

    if (newToken != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Token refreshed successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Refresh failed. Please log in again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),

              const Text(
                "Session Expired",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () => _tryRefresh(context, ref),
                child: const Text("Refresh Token"),
              ),

              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text("Log In Again"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
