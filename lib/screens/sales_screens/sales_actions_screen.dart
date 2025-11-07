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
      appBar: AppBar(
        title: const Text('Sales Management'),
        foregroundColor: Colors.brown,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildCard(
            context,
            'Point of Sale',
            Icons.point_of_sale,
            Colors.green,
            'Process new sales',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PosScreen()),
              );
            },
          ),
          _buildCard(
            context,
            'Sales History',
            Icons.history,
            Colors.blue,
            'View past sales',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SalesHistoryScreen()),
              );
            },
          ),
          _buildCard(
            context,
            'Outstanding',
            Icons.pending_actions,
            Colors.orange,
            'Pending payments',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OutstandingPaymentsScreen(),
                ),
              );
            },
          ),
          _buildCard(
            context,
            'Payment History',
            Icons.payment,
            Colors.purple,
            'Track all payments',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
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
            padding: const EdgeInsets.all(12), // Reduced padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(10), // Reduced padding
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: color), // Smaller icon
                ),
                const SizedBox(height: 8), // Reduced spacing
                // Title - Single line with ellipsis
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14, // Smaller font
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1, // Ensure single line
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4), // Reduced spacing
                // Subtitle - Smaller and limited to 2 lines
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11, // Smaller font
                    color: Colors.grey[600],
                    height: 1.2, // Tighter line height
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // Limit to 2 lines
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
