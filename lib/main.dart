import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/pos_screens/pos_screen.dart';
import 'theme.dart';
import 'utils/network_helper.dart';
import 'widgets/network_error_widget.dart';

void main() {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _hasNetwork = true;
  bool _isCheckingNetwork = true;

  @override
  void initState() {
    super.initState();
    _checkInitialNetwork();
    _listenToNetworkChanges();
  }

  Future<void> _checkInitialNetwork() async {
    final hasConnection = await NetworkHelper.hasConnection();
    if (mounted) {
      setState(() {
        _hasNetwork = hasConnection;
        _isCheckingNetwork = false;
      });
    }
  }

  void _listenToNetworkChanges() {
    NetworkHelper.onConnectivityChanged.listen((results) {
      final isConnected = NetworkHelper.isConnected(results);
      if (mounted && _hasNetwork != isConnected) {
        setState(() {
          _hasNetwork = isConnected;
        });

        // Show snackbar when network status changes
        if (isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.wifi, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Internet connection restored'),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Always return MaterialApp with theme to prevent purple flash
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pastry Pros',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routes: {
        '/home': (_) => const BakeryHomeScreen(),
        '/products': (_) => const PosScreen(),
        '/login': (_) => const LoginScreen(),
      },
      home: _buildHome(authState),
    );
  }

  Widget _buildHome(AuthState authState) {
    // Show loading with proper theme
    if (authState.isLoading || _isCheckingNetwork) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show network error if no connection
    if (!_hasNetwork) {
      return Scaffold(
        body: NetworkErrorWidget(
          onRetry: () async {
            setState(() => _isCheckingNetwork = true);
            await _checkInitialNetwork();
          },
        ),
      );
    }

    // Show appropriate screen based on auth state
    return authState.isAuthenticated
        ? const BakeryHomeScreen()
        : const LoginScreen();
  }
}
