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
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryBrown),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 26,
                  child: Icon(Icons.local_cafe, color: AppTheme.primaryBrown),
                ),
                SizedBox(height: 8),
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
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Dashboard
          _buildDrawerTile(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            selected: true,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            ),
          ),

          // Sales Section
          ExpansionTile(
            leading: const Icon(Icons.point_of_sale),
            title: const Text('Sales'),
            trailing: Icon(
              _salesExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
            ),
            onExpansionChanged: (val) {
              setState(() => _salesExpanded = val);
            },
            children: [
              _buildSubItem(
                context,
                title: 'Point of Sale',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PosScreen()),
                ),
              ),
              _buildSubItem(
                context,
                title: 'Sales History',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SalesHistoryScreen()),
                ),
              ),
              _buildSubItem(
                context,
                title: 'Outstanding Payment',
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PaymentHistoryScreen()),
                ),
              ),
            ],
          ),

          // Purchases Section
          ExpansionTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Purchases'),
            trailing: Icon(
              _purchasesExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
            ),
            onExpansionChanged: (val) {
              setState(() => _purchasesExpanded = val);
            },
            children: [
              _buildSubItem(
                context,
                title: 'Purchase Orders',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PurchaseOrdersScreen()),
                ),
              ),
              _buildSubItem(
                context,
                title: 'Material Receiving',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PurchasesActionsScreen()),
                ),
              ),
            ],
          ),

          // Inventory Section
          ExpansionTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Inventory'),
            trailing: Icon(
              _inventoryExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
            ),
            onExpansionChanged: (val) {
              setState(() => _inventoryExpanded = val);
            },
            children: [
              _buildSubItem(
                context,
                title: 'Materials',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => InventoryActionsScreen()),
                ),
              ),
              _buildSubItem(
                context,
                title: 'Supplies',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SalesActionsScreen()),
                ),
              ),
              _buildSubItem(
                context,
                title: 'Products',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SalesActionsScreen()),
                ),
              ),
            ],
          ),

          _buildDrawerTile(
            context,
            icon: Icons.factory,
            title: 'Production',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductionScreen()),
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
  }) {
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.white : Colors.black87),
      title: Text(title),
      selected: selected,
      selectedTileColor: AppTheme.primaryBrown,
      selectedColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }

  Widget _buildSubItem(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      onTap: onTap,
    );
  }
}
