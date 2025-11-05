import 'package:bak/screens/sales_screens/payment_history_screen.dart';
import 'package:flutter/material.dart';
import '../pos_screens/pos_screen.dart';
import 'outstanding_payment_screen.dart';
import 'sales_history_ui.dart';

class SalesActionsScreen extends StatelessWidget {
  const SalesActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sales')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildCard(context, 'Sales History', Icons.history, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SalesHistoryScreen()),
            );
          }),
          _buildCard(context, 'Point of Sale', Icons.point_of_sale, () {
            // Navigate to PointOfSaleScreen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PosScreen()),
            );
          }),
          _buildCard(context, 'Outstanding Payment', Icons.cable_sharp, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OutstandingPaymentsScreen()),
            );
          }),
          _buildCard(context, 'Payment History ', Icons.payment, () {
            // Navigate to PointOfSaleScreen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PaymentHistoryScreen()),
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
              Icon(icon, size: 48, color: Colors.blue),
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
