import 'package:flutter/material.dart';
import 'product_screen.dart';

class InventoryActionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inventory')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildCard(context, 'Details', Icons.info_outline, () {
            // Navigate to AdjustmentsScreen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductsScreen()),
            );
          }),
          _buildCard(context, 'Adjustments', Icons.tune, () {
            // Navigate to AdjustmentsScreen or another screen
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
              Icon(icon, size: 48, color: Colors.orange),
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
