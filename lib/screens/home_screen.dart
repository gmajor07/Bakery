import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import 'sales_screens/sales_actions_screen.dart';
import 'production_screen.dart';
import 'purchases_screens/purchases_actions_screen.dart';
import 'inventory_actions_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authProvider, (previous, next) {
      if (!next.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });

    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!authState.isAuthenticated) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildCard(context, 'Sales', Icons.attach_money, () async {
            final token = await ref
                .read(authProvider.notifier)
                .getAccessToken();
            if (token == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Token not found. Please log in again.'),
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SalesActionsScreen()),
            );
          }),
          _buildCard(context, 'Purchases', Icons.shopping_cart, () async {
            final token = await ref
                .read(authProvider.notifier)
                .getAccessToken();
            if (token == null) return;

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PurchasesActionsScreen()),
            );
          }),
          _buildCard(context, 'Production', Icons.factory, () async {
            final token = await ref
                .read(authProvider.notifier)
                .getAccessToken();
            if (token == null) return;

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductionScreen()),
            );
          }),
          _buildCard(context, 'Inventory', Icons.inventory, () async {
            final token = await ref
                .read(authProvider.notifier)
                .getAccessToken();
            if (token == null) return;

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => InventoryActionsScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.pink),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
