// lib/screens/purchases_screens/purchases_actions_screen.dart
import 'package:bak/screens/purchases_screens/purchases_order_screen.dart';
import 'package:bak/screens/supplier_screen.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/action_card.dart';
import '../material_screen/materials_received_screen.dart';

class PurchasesActionsScreen extends StatelessWidget {
  const PurchasesActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final primaryColor = colorScheme.primary;
    final backgroundColor = colorScheme.background; // Changed from .surface
    final onPrimary = colorScheme.onPrimary;
    final textBodyColor = textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: backgroundColor, // Now using background color
      appBar: AppBar(
        title: Text(
          'Purchases Management',
          style: TextStyle(color: onPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textBodyColor,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    // 1. Purchase Orders
                    ActionCard(
                      color: primaryColor,
                      label: 'Purchase Orders',
                      subtitle: 'Manage PO',
                      icon: LucideIcons.box,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PurchaseOrdersScreen(),
                          ),
                        );
                      },
                      contentAlignment: CrossAxisAlignment.center,
                      textAlignment: TextAlign.center,
                    ),

                    // 2. Material Receiving
                    ActionCard(
                      color: primaryColor,
                      label: 'Material Received',
                      subtitle: 'View Purchases ',
                      icon: LucideIcons.car,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MaterialsReceivedScreen(),
                          ),
                        );
                      },
                      contentAlignment: CrossAxisAlignment.center,
                      textAlignment: TextAlign.center,
                    ),

                    // 3. Suppliers
                    ActionCard(
                      color: primaryColor,
                      label: 'Suppliers',
                      subtitle: 'Manage suppliers',
                      icon: LucideIcons.userCog,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SupplierScreen(),
                          ),
                        );
                      },
                      contentAlignment: CrossAxisAlignment.center,
                      textAlignment: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
