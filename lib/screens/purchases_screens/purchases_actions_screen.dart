import 'package:bak/screens/purchases_screens/purchases_order_screen.dart';
import 'package:flutter/material.dart';

class PurchasesActionsScreen extends StatelessWidget {
  const PurchasesActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Purchases')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildCard(context, 'Purchase Orders', Icons.receipt_long, () {
            // Navigate to PurchaseOrdersScreen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PurchaseOrdersScreen()),
            );
          }),
          _buildCard(context, 'Material Receiving', Icons.move_to_inbox, () {
            // Navigate to MaterialReceivingScreen
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
              Icon(icon, size: 48, color: Colors.green),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
