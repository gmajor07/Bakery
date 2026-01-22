// lib/screens/purchases_screens/purchases_actions_screen.dart
import 'package:bak/screens/purchases_screens/purchases_order_screen.dart';
import 'package:bak/screens/supplier_screen.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/action_card.dart';
import '../material_screen/materials_received_screen.dart';

class PurchasesActionsScreen extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavItemTapped;

  const PurchasesActionsScreen({
    super.key,
    required this.selectedIndex,
    required this.onNavItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final textOnPrimary = colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // 1. TITLE (Outside the card)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Purchases',
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          // 2. BIG COLORED CARD (with top radius) - extends to bottom
          Padding(
            padding: const EdgeInsets.only(top: 90),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
              ),
              child: Column(
                children: [
                  // --- Quick Access Title + Grid ---
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Access',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textOnPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),

                            GridView.count(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
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
                                        builder: (_) =>
                                            const PurchaseOrdersScreen(),
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
                                  subtitle: 'View Purchases',
                                  icon: LucideIcons.car,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const MaterialsReceivedScreen(),
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
                          ],
                        ),
                      ),
                    ),
                  ),

                  // --- Navigation Bar Menu (Inside the card at bottom) ---
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    decoration: BoxDecoration(
                      color: textOnPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: SizedBox(
                        height: 65,
                        child: Row(
                          children: [
                            // Home
                            Expanded(
                              child: _buildNavItem(
                                icon: LucideIcons.home,
                                label: 'Home',
                                index: 0,
                                isSelected: selectedIndex == 0,
                                textOnPrimary: textOnPrimary,
                              ),
                            ),
                            // Payments
                            Expanded(
                              child: _buildNavItem(
                                icon: LucideIcons.badgeInfo,
                                label: 'Payments',
                                index: 1,
                                isSelected: selectedIndex == 1,
                                textOnPrimary: textOnPrimary,
                              ),
                            ),
                            // Purchases
                            Expanded(
                              child: _buildNavItem(
                                icon: LucideIcons.shoppingCart,
                                label: 'Purchases',
                                index: 2,
                                isSelected: selectedIndex == 2,
                                textOnPrimary: textOnPrimary,
                              ),
                            ),
                            // Inventory
                            Expanded(
                              child: _buildNavItem(
                                icon: LucideIcons.box,
                                label: 'Inventory',
                                index: 3,
                                isSelected: selectedIndex == 3,
                                textOnPrimary: textOnPrimary,
                              ),
                            ),
                            // Expenses
                            Expanded(
                              child: _buildNavItem(
                                icon: LucideIcons.printer,
                                label: 'Expenses',
                                index: 4,
                                isSelected: selectedIndex == 4,
                                textOnPrimary: textOnPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    required Color textOnPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onNavItemTapped(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? textOnPrimary
                  : textOnPrimary.withOpacity(0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? textOnPrimary
                    : textOnPrimary.withOpacity(0.5),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
