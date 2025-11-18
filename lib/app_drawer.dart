import 'package:flutter/material.dart';
import '../theme.dart';
import 'screens/inventory_actions_screen.dart';
import 'screens/pos_screens/pos_screen.dart';
import 'screens/production_screen.dart';
import 'screens/purchases_screens/purchases_actions_screen.dart';
import 'screens/purchases_screens/purchases_order_screen.dart';
import 'screens/sales_screens/outstanding_payment_screen.dart';
import 'screens/sales_screens/payment_history_screen.dart';
import 'screens/sales_screens/sales_actions_screen.dart';
import 'screens/home_screen.dart';
import 'screens/sales_screens/sales_history_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _salesExpanded = false;
  bool _inventoryExpanded = false;
  bool _purchasesExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(16),
        ),
      ),
      elevation: 8,
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: AppTheme.primaryBrown,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Icon and Name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_cafe,
                          color: AppTheme.primaryBrown,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'APOTEk System',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Bakery Manager',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick Stats (Optional)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(value: '24', label: 'Sales'),
                        _StatItem(value: '156', label: 'Products'),
                        _StatItem(value: '89', label: 'Orders'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // Dashboard
                _buildDrawerTile(
                  context,
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  selected: true,
                  gradient: const [
                    AppTheme.primaryBrown,
                    Color(0xFF8B6B4D),
                  ],
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1),
                ),

                // Sales Section
                _buildExpansionTile(
                  context,
                  icon: Icons.point_of_sale_rounded,
                  title: 'Sales',
                  expanded: _salesExpanded,
                  onExpansionChanged: (val) {
                    setState(() => _salesExpanded = val);
                  },
                  children: [
                    _buildSubItem(
                      context,
                      title: 'Point of Sale',
                      icon: Icons.shopping_cart_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PosScreen()),
                      ),
                    ),
                    _buildSubItem(
                      context,
                      title: 'Sales History',
                      icon: Icons.history_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SalesHistoryScreen()),
                      ),
                    ),
                    _buildSubItem(
                      context,
                      title: 'Outstanding Payment',
                      icon: Icons.pending_actions_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OutstandingPaymentsScreen(),
                        ),
                      ),
                    ),
                    _buildSubItem(
                      context,
                      title: 'Payment History',
                      icon: Icons.payment_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PaymentHistoryScreen()),
                      ),
                    ),
                  ],
                ),

                // Purchases Section
                _buildExpansionTile(
                  context,
                  icon: Icons.shopping_cart_rounded,
                  title: 'Purchases',
                  expanded: _purchasesExpanded,
                  onExpansionChanged: (val) {
                    setState(() => _purchasesExpanded = val);
                  },
                  children: [
                    _buildSubItem(
                      context,
                      title: 'Purchase Orders',
                      icon: Icons.list_alt_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PurchaseOrdersScreen()),
                      ),
                    ),
                    _buildSubItem(
                      context,
                      title: 'Material Receiving',
                      icon: Icons.inventory_2_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PurchasesActionsScreen()),
                      ),
                    ),
                  ],
                ),

                // Inventory Section
                _buildExpansionTile(
                  context,
                  icon: Icons.inventory_2_rounded,
                  title: 'Inventory',
                  expanded: _inventoryExpanded,
                  onExpansionChanged: (val) {
                    setState(() => _inventoryExpanded = val);
                  },
                  children: [
                    _buildSubItem(
                      context,
                      title: 'Materials',
                      icon: Icons.construction_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => InventoryActionsScreen()),
                      ),
                    ),
                    _buildSubItem(
                      context,
                      title: 'Supplies',
                      icon: Icons.local_shipping_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SalesActionsScreen()),
                      ),
                    ),
                    _buildSubItem(
                      context,
                      title: 'Products',
                      icon: Icons.inventory_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SalesActionsScreen()),
                      ),
                    ),
                  ],
                ),

                // Production
                _buildDrawerTile(
                  context,
                  icon: Icons.factory_rounded,
                  title: 'Production',
                  gradient: const [
                    Color(0xFF4CAF50),
                    Color(0xFF45A049),
                  ],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductionScreen()),
                  ),
                ),

                const SizedBox(height: 20),

                // Footer Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBrown.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.settings_rounded,
                            color: AppTheme.primaryBrown,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Log out',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        bool selected = false,
        List<Color>? gradient,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected && gradient != null
            ? null
            : selected
            ? AppTheme.primaryBrown
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: selected && gradient != null
                ? BoxDecoration(
              gradient: LinearGradient(
                colors: gradient!,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            )
                : null,
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? Colors.white : Colors.grey[700],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.grey[800],
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.circle_rounded,
                    color: Colors.white,
                    size: 8,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpansionTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required bool expanded,
        required Function(bool) onExpansionChanged,
        required List<Widget> children,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ExpansionTile(
        leading: Icon(
          icon,
          color: Colors.grey[700],
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            color: Colors.grey[600],
            size: 16,
          ),
        ),
        onExpansionChanged: onExpansionChanged,
        children: children,
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        collapsedBackgroundColor: Colors.transparent,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  Widget _buildSubItem(
      BuildContext context, {
        required String title,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.only(left: 44, right: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}