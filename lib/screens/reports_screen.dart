import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/action_card.dart';
import 'reports/purchase_report_screen.dart';
import 'reports/sales_report_screen.dart';
import 'reports/inventory_report_screen.dart';
import 'reports/production_report_screen.dart';
import 'reports/accounting_report_screen.dart';

class ReportsScreen extends StatefulWidget {
  final int selectedIndex;
  final Function(int)? onNavItemTapped;

  const ReportsScreen({
    super.key,
    this.selectedIndex = 0,
    this.onNavItemTapped,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final primaryColor = colorScheme.primary;
    final textOnPrimary = colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Reports',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Greeting
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Business Reports',
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'View detailed reports for each module',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // Big Colored Card with Reports
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
                  // --- Report Cards ---
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Report Type',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textOnPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Grid of report cards
                            GridView.count(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.2,
                              children: [
                                // Sales Report
                                ActionCard(
                                  color: primaryColor,
                                  label: 'Sales',
                                  subtitle: 'View sales data and history',
                                  icon: LucideIcons.barChart3,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const SalesReportScreen(),
                                      ),
                                    );
                                  },
                                  contentAlignment: CrossAxisAlignment.center,
                                  textAlignment: TextAlign.center,
                                ),

                                // Purchases Report
                                ActionCard(
                                  color: primaryColor,
                                  label: 'Purchases',
                                  subtitle: 'Manage purchase orders and data',
                                  icon: LucideIcons.shoppingCart,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const PurchaseReportScreen(),
                                      ),
                                    );
                                  },
                                  contentAlignment: CrossAxisAlignment.center,
                                  textAlignment: TextAlign.center,
                                ),

                                // Inventory Report
                                ActionCard(
                                  color: primaryColor,
                                  label: 'Inventory',
                                  subtitle: 'Track inventory information',
                                  icon: LucideIcons.box,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const InventoryReportScreen(),
                                      ),
                                    );
                                  },
                                  contentAlignment: CrossAxisAlignment.center,
                                  textAlignment: TextAlign.center,
                                ),

                                // Production Report
                                ActionCard(
                                  color: primaryColor,
                                  label: 'Production',
                                  subtitle: 'View production details',
                                  icon: LucideIcons.factory,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ProductionReportScreen(),
                                      ),
                                    );
                                  },
                                  contentAlignment: CrossAxisAlignment.center,
                                  textAlignment: TextAlign.center,
                                ),

                                // Accounting Report
                                ActionCard(
                                  color: primaryColor,
                                  label: 'Accounting',
                                  subtitle:
                                      'Access expense and accounting data',
                                  icon: LucideIcons.calculator,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AccountingReportScreen(),
                                      ),
                                    );
                                  },
                                  contentAlignment: CrossAxisAlignment.center,
                                  textAlignment: TextAlign.center,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // --- Navigation Bar Menu ---
                  Container(
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
                            // Home
                            Expanded(
                              child: _buildNavItemWidget(
                                icon: LucideIcons.home,
                                label: 'Home',
                                index: 0,
                                unselectedIconColor: textOnPrimary.withValues(
                                  alpha: 0.5,
                                ),
                                unselectedTextColor: textOnPrimary.withValues(
                                  alpha: 0.5,
                                ),
                                isSelected: false,
                                context: context,
                                textOnPrimary: textOnPrimary,
                                primaryColor: primaryColor,
                                onTap: () {
                                  Navigator.pushNamed(context, '/home');
                                },
                              ),
                            ),

                            // Payments
                            Expanded(
                              child: _buildNavItemWidget(
                                icon: LucideIcons.badgeInfo,
                                label: 'Payments',
                                index: 1,
                                unselectedIconColor: textOnPrimary.withValues(
                                  alpha: 0.5,
                                ),
                                unselectedTextColor: textOnPrimary.withValues(
                                  alpha: 0.5,
                                ),
                                isSelected: false,
                                context: context,
                                textOnPrimary: textOnPrimary,
                                primaryColor: primaryColor,
                                onTap: () {
                                  Navigator.pushNamed(context, '/home');
                                },
                              ),
                            ),

                            // Purchases
                            Expanded(
                              child: _buildNavItemWidget(
                                icon: LucideIcons.shoppingCart,
                                label: 'Purchases',
                                index: 2,
                                unselectedIconColor: textOnPrimary.withValues(
                                  alpha: 0.5,
                                ),
                                unselectedTextColor: textOnPrimary.withValues(
                                  alpha: 0.5,
                                ),
                                isSelected: false,
                                context: context,
                                textOnPrimary: textOnPrimary,
                                primaryColor: primaryColor,
                                onTap: () {
                                  Navigator.pushNamed(context, '/home');
                                },
                              ),
                            ),

                            // Inventory
                            Expanded(
                              child: _buildNavItemWidget(
                                icon: LucideIcons.box,
                                label: 'Inventory',
                                index: 3,
                                unselectedIconColor: textOnPrimary.withValues(
                                  alpha: 0.5,
                                ),
                                unselectedTextColor: textOnPrimary.withValues(
                                  alpha: 0.5,
                                ),
                                isSelected: false,
                                context: context,
                                textOnPrimary: textOnPrimary,
                                primaryColor: primaryColor,
                                onTap: () {
                                  Navigator.pushNamed(context, '/home');
                                },
                              ),
                            ),

                            // Expenses
                            Expanded(
                              child: _buildNavItemWidget(
                                icon: LucideIcons.printer,
                                label: 'Expenses',
                                index: 4,
                                unselectedIconColor: textOnPrimary.withValues(
                                  alpha: 0.5,
                                ),
                                unselectedTextColor: textOnPrimary.withValues(
                                  alpha: 0.5,
                                ),
                                isSelected: false,
                                context: context,
                                textOnPrimary: textOnPrimary,
                                primaryColor: primaryColor,
                                onTap: () {
                                  Navigator.pushNamed(context, '/home');
                                },
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

  static Widget _buildNavItemWidget({
    required IconData icon,
    required String label,
    required int index,
    required Color? unselectedIconColor,
    required Color? unselectedTextColor,
    required bool isSelected,
    required BuildContext context,
    required Color textOnPrimary,
    required Color primaryColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? textOnPrimary : unselectedIconColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? textOnPrimary : unselectedTextColor,
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
