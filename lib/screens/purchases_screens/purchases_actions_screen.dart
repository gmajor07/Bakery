import 'package:bak/screens/purchases_screens/purchases_order_screen.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../materials_received_screen.dart';

class PurchasesActionsScreen extends StatelessWidget {
  const PurchasesActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final primaryColor = colorScheme.primary;
    final backgroundColor = colorScheme.background;
    final onPrimary = colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Purchases',
          style: TextStyle(color: onPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            // The GridView setup remains the same, forcing the responsiveness into the card
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              // 1. Purchase Orders
              _ActionCard(
                color: primaryColor,
                label: 'Purchase Orders',
                subtitle: 'Manage new orders to suppliers',
                icon: LucideIcons.receipt,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PurchaseOrdersScreen(),
                    ),
                  );
                },
              ),

              // 2. Material Receiving
              _ActionCard(
                color: primaryColor,
                label: 'Material Receiving',
                subtitle: 'Confirm items and update',
                icon: LucideIcons.flaskConical,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MaterialsReceivedScreen(),
                    ),
                  );
                },
              ),

              // 3. Suppliers
              _ActionCard(
                color: primaryColor,
                label: 'Suppliers',
                subtitle: 'Manage vendor details and contacts',
                icon: LucideIcons.box,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final cardSurfaceColor = colorScheme.surface;
    final textBodyColor = textTheme.bodyMedium?.color;

    return Material(
      color: cardSurfaceColor,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: color.withOpacity(0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          // ⭐️ FIX 1: Reduced overall padding to save vertical space
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: textBodyColor,
                    ),
                  ),
                  // ⭐️ FIX 2: Reduced spacing between label and subtitle
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: textBodyColor?.withOpacity(0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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