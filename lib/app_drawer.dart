import 'package:flutter/material.dart';
// import '../theme.dart'; // We'll rely on Theme.of(context) instead of a static AppTheme class
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

// Assuming your theme file defines colors:
// You should ensure this exists and your main app uses it.
// Example: const Color primaryColor = Color(0xFF6D4C41); // Example Brown

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  // Assuming a currently selected index/route for dashboard
  int _selectedIndex = 0;
  bool _salesExpanded = false;
  bool _inventoryExpanded = false;
  bool _purchasesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;

    // Define a map of all menu items and their corresponding screens/actions
    final menuItems = [
      {
        'title': 'Dashboard',
        'icon': Icons.dashboard_rounded,
        'screen': const HomeScreen(),
        'id': 0,
      },
      // Expansion Tiles
      // Children will be handled within the expansion tile builder
    ];

    return Drawer(
      // Modern: Use a subtle background, keep rounded shape
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
      ),
      elevation: 4,
      child: Column(
        children: [
          // Header Section (Modernized)
          DrawerHeader(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme
                  .primaryContainer, // Use primaryContainer for a light, themed header
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_cafe,
                      color: colorScheme.primaryContainer,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // App Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'APOTEk System',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Bakery Manager',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer.withOpacity(
                              0.7,
                            ),
                            fontSize: 12,
                          ),
                        ),
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // 1. Dashboard
                _buildDrawerTile(
                  context,
                  icon: menuItems[0]['icon'] as IconData,
                  title: menuItems[0]['title'] as String,
                  // Use ID to determine selection
                  selected: _selectedIndex == (menuItems[0]['id'] as int),
                  onTap: () {
                    setState(
                      () => _selectedIndex = (menuItems[0]['id'] as int),
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => menuItems[0]['screen'] as Widget,
                      ),
                    );
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1),
                ),

                // 2. Sales Section (Expansion)
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
                      onTap: () => _navigateTo(context, PosScreen()),
                    ),
                    _buildSubItem(
                      context,
                      title: 'Sales History',
                      icon: Icons.history_rounded,
                      onTap: () => _navigateTo(context, SalesHistoryScreen()),
                    ),
                    _buildSubItem(
                      context,
                      title: 'Outstanding Payment',
                      icon: Icons.pending_actions_rounded,
                      onTap: () =>
                          _navigateTo(context, OutstandingPaymentsScreen()),
                    ),
                    _buildSubItem(
                      context,
                      title: 'Payment History',
                      icon: Icons.payment_rounded,
                      onTap: () => _navigateTo(context, PaymentHistoryScreen()),
                    ),
                  ],
                ),

                // 3. Purchases Section (Expansion)
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
                      onTap: () => _navigateTo(context, PurchaseOrdersScreen()),
                    ),
                    _buildSubItem(
                      context,
                      title: 'Material Receiving',
                      icon: Icons.inventory_2_rounded,
                      onTap: () =>
                          _navigateTo(context, PurchasesActionsScreen()),
                    ),
                  ],
                ),

                // 4. Inventory Section (Expansion)
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
                      onTap: () =>
                          _navigateTo(context, InventoryActionsScreen()),
                    ),
                    _buildSubItem(
                      context,
                      title: 'Supplies',
                      icon: Icons.local_shipping_rounded,
                      onTap: () => _navigateTo(context, SalesActionsScreen()),
                    ),
                    _buildSubItem(
                      context,
                      title: 'Products',
                      icon: Icons.inventory_rounded,
                      onTap: () => _navigateTo(context, SalesActionsScreen()),
                    ),
                  ],
                ),

                // 5. Production
                _buildDrawerTile(
                  context,
                  icon: Icons.factory_rounded,
                  title: 'Production',
                  selected: _selectedIndex == 5,
                  onTap: () {
                    setState(() => _selectedIndex = 5);
                    _navigateTo(context, ProductionScreen());
                  },
                ),

                const SizedBox(height: 20),
                const Divider(height: 1),

                // 6. Logout Section (Modernized)
                _buildDrawerTile(
                  context,
                  icon: Icons.logout_rounded,
                  title: 'Log out',
                  selected: false, // Never selected
                  onTap: () {
                    // Implement your actual logout logic here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logging out...')),
                    );
                    // Example: Navigator.of(context).pushReplacementNamed('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function for clean navigation
  void _navigateTo(BuildContext context, Widget screen) {
    // Check if the current route is the target screen to avoid pushing the same screen multiple times
    // For nested screens, you might use Navigator.popAndPushNamed
    Navigator.pop(context); // Close the drawer first
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  // 1. MODERNIZED Drawer Tile
  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        selected: selected,
        // Modern: Use theme colors for selection state
        selectedTileColor: primaryColor.withOpacity(0.1),
        selectedColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),

        leading: Icon(
          icon,
          // Use primary color if selected, or a subtle color otherwise
          color: selected ? primaryColor : colorScheme.onSurfaceVariant,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? primaryColor : colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        // Modern: Use a subtle trailing icon for selected state
        trailing: selected
            ? Icon(Icons.chevron_right_rounded, color: primaryColor)
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  // 2. MODERNIZED Expansion Tile
  Widget _buildExpansionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool expanded,
    required Function(bool) onExpansionChanged,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: expanded ? primaryColor.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExpansionTile(
        leading: Icon(
          icon,
          // Use primary color when expanded
          color: expanded ? primaryColor : colorScheme.onSurfaceVariant,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: expanded ? primaryColor : colorScheme.onSurface,
            fontWeight: expanded ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          color: expanded ? primaryColor : colorScheme.onSurfaceVariant,
          size: 20,
        ),
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        // Important for modern look: keep background clean
        collapsedBackgroundColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        children: children,
      ),
    );
  }

  // 3. MODERNIZED Sub-Item
  Widget _buildSubItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
      child: ListTile(
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.only(left: 48, right: 16),
        // Modern: Subtle hover and shape
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        hoverColor: primaryColor.withOpacity(0.05),

        leading: Icon(
          icon,
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          size: 16,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.85),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
