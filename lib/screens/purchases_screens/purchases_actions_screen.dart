import 'package:bak/screens/purchases_screens/purchases_order_screen.dart';
import 'package:flutter/material.dart';
import '../materials_received_screen.dart';

class PurchasesActionsScreen extends StatelessWidget {
  const PurchasesActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchases Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildCard(
            context,
            'Purchase Orders',
            Icons.receipt_long,
            Colors.blue,
            'Create & manage orders',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PurchaseOrdersScreen()),
              );
            },
          ),
          _buildCard(
            context,
            'Material Receiving',
            Icons.move_to_inbox,
            Colors.green,
            'Receive purchased items',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MaterialsReceivedScreen(),
                ),
              );
            },
          ),
          _buildCard(
            context,
            'Suppliers',
            Icons.business,
            Colors.orange,
            'Manage vendor list',
            () {
              // TODO: Navigate to SuppliersScreen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Suppliers screen coming soon')),
              );
            },
          ),
          _buildCard(
            context,
            'Purchase History',
            Icons.history,
            Colors.purple,
            'View past purchases',
            () {
              // TODO: Navigate to PurchaseHistoryScreen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Purchase history screen coming soon'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
