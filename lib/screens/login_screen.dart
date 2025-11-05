import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/login_api_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  bool isLoading = false;

  void handleLogin() async {
    final email = emailController.text.trim();
    final code = codeController.text.trim();

    if (email.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and code')),
      );
      return;
    }

    setState(() => isLoading = true);
    final api = LoginApiService(ref);

    try {
      await api.login(email, code);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      // Only show a generic message to the user
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Please try again.')),
      );

      // Detailed error stays in console
      print("❌ Login exception: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Login', style: TextStyle(fontSize: 24)),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Code')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : handleLogin,
              child: Text(isLoading ? 'Logging in...' : 'Login'),
            ),
          ],
        ),
      ),
    );
  }
}
