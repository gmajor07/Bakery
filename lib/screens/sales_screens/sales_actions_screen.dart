import 'package:flutter/material.dart';
import '../pos_screens/pos_screen.dart';
import 'outstanding_payment_screen.dart';
import 'sales_history_screen.dart';
import 'payment_history_screen.dart'; // Already imported
// Define colors locally for consistency
const Color primaryColor = Color(0xFFC8A2C8);
const Color textDark = Color(0xFF3C3C3C);
const Color cardOne = Color(0xFF85C1E9);
const Color cardTwo = Color(0xFFF5B7B1);

class SalesActionsScreen extends StatelessWidget {
  const SalesActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0), // Use the cream background
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Sales Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2, // Use the same ratio as the dashboard cards
            children: [
              // 1. New Sale / POS (Primary Action)
              _ActionCard(
                color: primaryColor,
                label: 'New Sale (POS)',
                subtitle: 'Start a customer transaction',
                icon: Icons.point_of_sale_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PosScreen()),
                  );
                },
              ),

              // 2. Sales History
              _ActionCard(
                color: Colors.teal,
                label: 'Sales History',
                subtitle: 'View all completed orders',
                icon: Icons.receipt_long_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
                  );
                },
              ),

              // 3. Outstanding Payments
              _ActionCard(
                color: Colors.deepOrange,
                label: 'Outstanding',
                subtitle: 'Manage credit and pending balances',
                icon: Icons.pending_actions_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OutstandingPaymentsScreen(),
                    ),
                  );
                },
              ),

              // 4. Payment History
              _ActionCard(
                color: cardOne,
                label: 'Payment History',
                subtitle: 'Track all incoming payments',
                icon: Icons.payment_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusing the modern _ActionCard structure from BakeryHomeScreen
class _ActionCard extends StatelessWidget {
  final Color color;
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.color,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: color.withOpacity(0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}