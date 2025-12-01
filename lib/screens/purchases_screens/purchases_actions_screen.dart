import 'package:bak/screens/purchases_screens/purchases_order_screen.dart';
import 'package:flutter/material.dart';
import '../materials_received_screen.dart';

// Define colors locally for consistency
const Color primaryColor = Color(0xFFC8A2C8);
const Color textDark = Color(0xFF3C3C3C);
const Color creamBackground = Color(0xFFFAF7F0);
const Color cardOne = Color(0xFF85C1E9); // Light Blue

class PurchasesActionsScreen extends StatelessWidget {
  const PurchasesActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBackground, // Use the cream background
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Purchases',
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
            childAspectRatio: 1.2, // Consistent card size
            children: [
              // 1. Purchase Orders (Create/Manage)
              _ActionCard(
                color: primaryColor,
                label: 'Purchase Orders',
                subtitle: 'Manage new orders to suppliers',
                icon: Icons.receipt_long_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PurchaseOrdersScreen()),
                  );
                },
              ),

              // 2. Material Receiving (Check-in stock)
              _ActionCard(
                color: Colors.green,
                label: 'Material Receiving',
                subtitle: 'Confirm items and update',
                icon: Icons.check_box_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MaterialsReceivedScreen(),
                    ),
                  );
                },
              ),


              // 4. Supplier Management (Example Placeholder)
              _ActionCard(
                color: Colors.amber[700]!,
                label: 'Suppliers',
                subtitle: 'Manage vendor details and contacts',
                icon: Icons.groups_rounded,
                onTap: () {
                  // Placeholder for a dedicated screen
                  // Navigator.push(...);
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