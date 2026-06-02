import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/action_card.dart';
import '../material_screen/material_screen.dart';
import '../product_screen.dart';
import 'adjustment_selection_screen.dart';
import 'inventory_screen.dart';

class InventoryActionsScreen extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavItemTapped;

  const InventoryActionsScreen({
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory',
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage materials, supplies, products, and stock levels',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 110),
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
                                ActionCard(
                                  color: primaryColor,
                                  label: 'Materials',
                                  subtitle: 'Raw ingredients',
                                  icon: LucideIcons.cakeSlice,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const MaterialsScreen(),
                                      ),
                                    );
                                  },
                                ),
                                ActionCard(
                                  color: primaryColor,
                                  label: 'Supplies',
                                  subtitle: 'Packaging & items',
                                  icon: LucideIcons.box,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const InventoryScreen(),
                                      ),
                                    );
                                  },
                                ),
                                ActionCard(
                                  color: primaryColor,
                                  label: 'Products',
                                  subtitle: 'Finished goods',
                                  icon: LucideIcons.shoppingBag,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ProductsScreen(),
                                      ),
                                    );
                                  },
                                ),
                                ActionCard(
                                  color: primaryColor,
                                  label: 'Adjustments',
                                  subtitle: 'Fix stock levels',
                                  icon: LucideIcons.sliders,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AdjustmentTypeSelectionScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _InventoryNavBar(
                    selectedIndex: selectedIndex,
                    onTap: onNavItemTapped,
                    textOnPrimary: textOnPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final Color textOnPrimary;

  const _InventoryNavBar({
    required this.selectedIndex,
    required this.onTap,
    required this.textOnPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: textOnPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              _InventoryNavItem(
                icon: LucideIcons.home,
                label: 'Home',
                index: 0,
                isSelected: selectedIndex == 0,
                textOnPrimary: textOnPrimary,
                onTap: onTap,
              ),
              _InventoryNavItem(
                icon: LucideIcons.badgeInfo,
                label: 'Payments',
                index: 1,
                isSelected: selectedIndex == 1,
                textOnPrimary: textOnPrimary,
                onTap: onTap,
              ),
              _InventoryNavItem(
                icon: LucideIcons.shoppingCart,
                label: 'Purchases',
                index: 2,
                isSelected: selectedIndex == 2,
                textOnPrimary: textOnPrimary,
                onTap: onTap,
              ),
              _InventoryNavItem(
                icon: LucideIcons.box,
                label: 'Inventory',
                index: 3,
                isSelected: selectedIndex == 3,
                textOnPrimary: textOnPrimary,
                onTap: onTap,
              ),
              _InventoryNavItem(
                icon: LucideIcons.printer,
                label: 'Expenses',
                index: 4,
                isSelected: selectedIndex == 4,
                textOnPrimary: textOnPrimary,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool isSelected;
  final Color textOnPrimary;
  final Function(int) onTap;

  const _InventoryNavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.isSelected,
    required this.textOnPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? textOnPrimary
        : textOnPrimary.withValues(alpha: 0.5);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
