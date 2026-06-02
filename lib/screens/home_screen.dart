import 'package:bak/screens/pos_screens/pos_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../auth/auth_provider.dart';
import '../provider/user_provider.dart';
import '../widgets/action_card.dart';
import 'customer/customer_list_screen.dart';
import 'expense_screen.dart';
import 'product_screen.dart';
import 'purchases_screens/purchases_order_screen.dart';
import 'sales_screens/payment_actions_screen.dart';
import 'production_screen.dart';
import 'purchases_screens/purchases_actions_screen.dart';
import 'inventory/inventory_actions_screen.dart';
import 'sales_screens/sales_history_screen.dart';
import 'reports_screen.dart';

class BakeryHomeScreen extends ConsumerStatefulWidget {
  const BakeryHomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _BakeryHomeScreenState();
}

class _BakeryHomeScreenState extends ConsumerState<BakeryHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userState = ref.watch(userProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ref.listen(authProvider, (previous, next) {
      if (!next.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        title: Text(
          'APOTEk Bakery',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<_HomeAction>(
              tooltip: 'Account actions',
              offset: const Offset(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onSelected: (action) {
                switch (action) {
                  case _HomeAction.profile:
                    _showProfileDialog(context, userState);
                    break;
                  case _HomeAction.reports:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportsScreen(
                          selectedIndex: _selectedIndex,
                          onNavItemTapped: (newIndex) {
                            Navigator.pop(context);
                            setState(() => _selectedIndex = newIndex);
                          },
                        ),
                      ),
                    );
                    break;
                  case _HomeAction.refresh:
                    ref.invalidate(userProvider);
                    break;
                  case _HomeAction.logout:
                    _showLogoutDialog(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _HomeAction.profile,
                  child: _AccountMenuItem(
                    icon: LucideIcons.userCircle,
                    label: 'View Profile',
                  ),
                ),
                const PopupMenuItem(
                  value: _HomeAction.reports,
                  child: _AccountMenuItem(
                    icon: LucideIcons.barChart3,
                    label: 'Reports',
                  ),
                ),
                const PopupMenuItem(
                  value: _HomeAction.refresh,
                  child: _AccountMenuItem(
                    icon: LucideIcons.refreshCw,
                    label: 'Refresh',
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: _HomeAction.logout,
                  child: _AccountMenuItem(
                    icon: LucideIcons.logOut,
                    label: 'Logout',
                  ),
                ),
              ],
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.14),
                  ),
                ),
                child: Icon(
                  LucideIcons.userCircle,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildPageContent(_selectedIndex),
    );
  }

  Widget _buildPageContent(int index) {
    switch (index) {
      case 0:
        return _DashboardBody(
          selectedIndex: _selectedIndex,
          onNavItemTapped: (newIndex) =>
              setState(() => _selectedIndex = newIndex),
        );
      case 1:
        return SalesActionsScreen(
          selectedIndex: _selectedIndex,
          onNavItemTapped: (newIndex) =>
              setState(() => _selectedIndex = newIndex),
        );
      case 2:
        return PurchasesActionsScreen(
          selectedIndex: _selectedIndex,
          onNavItemTapped: (newIndex) =>
              setState(() => _selectedIndex = newIndex),
        );
      case 3:
        return _InventoryPage(
          selectedIndex: _selectedIndex,
          onNavItemTapped: (newIndex) =>
              setState(() => _selectedIndex = newIndex),
        );
      case 4:
        return ExpensesScreen(
          selectedIndex: _selectedIndex,
          onNavItemTapped: (newIndex) =>
              setState(() => _selectedIndex = newIndex),
        );
      default:
        return _DashboardBody(
          selectedIndex: _selectedIndex,
          onNavItemTapped: (newIndex) =>
              setState(() => _selectedIndex = newIndex),
        );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () {
              ref.read(authProvider.notifier).logout(clearCredentials: true);
              Navigator.pop(dialogContext);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context, UserState userState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = userState.user;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(LucideIcons.userCircle, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user?.name.isNotEmpty == true ? user!.name : 'User Profile',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileDetailRow(
              icon: LucideIcons.mail,
              label: 'Email',
              value: user?.email.isNotEmpty == true
                  ? user!.email
                  : 'Not available',
            ),
            const SizedBox(height: 12),
            _ProfileDetailRow(
              icon: LucideIcons.shieldCheck,
              label: 'Role',
              value: user?.role.isNotEmpty == true
                  ? user!.role
                  : 'Not available',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

enum _HomeAction { profile, reports, refresh, logout }

class _AccountMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AccountMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 18), const SizedBox(width: 12), Text(label)],
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onNavItemTapped;

  const _DashboardBody({
    required this.selectedIndex,
    required this.onNavItemTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final textOnPrimary = colorScheme.onPrimary;
    final userState = ref.watch(userProvider);

    String greeting = 'Hi, Baker!';
    if (userState.user != null) {
      greeting = 'Hi, ${userState.user!.name.split(' ').first}!';
    }

    return Stack(
      children: [
        // 1. GREETING (Outside the card)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formattedDate(),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),

        // 2. BIG COLORED CARD (with top rounded corners)
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
                                label: 'New Sale',
                                subtitle: 'Start a transaction',
                                icon: LucideIcons.creditCard,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PosScreen(),
                                  ),
                                ),
                              ),
                              ActionCard(
                                color: primaryColor,
                                label: 'Sales History',
                                subtitle: 'Review transactions',
                                icon: LucideIcons.barChart3,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SalesHistoryScreen(),
                                  ),
                                ),
                              ),
                              ActionCard(
                                color: primaryColor,
                                label: 'Purchase Orders',
                                subtitle: 'Manage PO',
                                icon: LucideIcons.shoppingCart,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const PurchaseOrdersScreen(),
                                  ),
                                ),
                              ),
                              ActionCard(
                                color: primaryColor,
                                label: 'Products',
                                subtitle: 'Manage products',
                                icon: LucideIcons.box,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProductsScreen(),
                                  ),
                                ),
                              ),
                              ActionCard(
                                color: primaryColor,
                                label: 'Production',
                                subtitle: 'View production',
                                icon: LucideIcons.factory,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductionScreen(),
                                  ),
                                ),
                              ),
                              ActionCard(
                                color: primaryColor,
                                label: 'Customers',
                                subtitle: 'Manage customers',
                                icon: LucideIcons.userCircle,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CustomerScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Navigation Bar Menu
                _FloatingNavBar(
                  selectedIndex: selectedIndex,
                  onTap: onNavItemTapped,
                  primaryColor: primaryColor,
                  textOnPrimary: textOnPrimary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _formattedDate() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final Color primaryColor;
  final Color textOnPrimary;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.onTap,
    required this.primaryColor,
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
              _NavItem(
                icon: LucideIcons.home,
                label: 'Home',
                index: 0,
                isSelected: selectedIndex == 0,
                onTap: onTap,
                textOnPrimary: textOnPrimary,
              ),
              _NavItem(
                icon: LucideIcons.badgeInfo,
                label: 'Payments',
                index: 1,
                isSelected: selectedIndex == 1,
                onTap: onTap,
                textOnPrimary: textOnPrimary,
              ),
              _NavItem(
                icon: LucideIcons.shoppingCart,
                label: 'Purchases',
                index: 2,
                isSelected: selectedIndex == 2,
                onTap: onTap,
                textOnPrimary: textOnPrimary,
              ),
              _NavItem(
                icon: LucideIcons.box,
                label: 'Inventory',
                index: 3,
                isSelected: selectedIndex == 3,
                onTap: onTap,
                textOnPrimary: textOnPrimary,
              ),
              _NavItem(
                icon: LucideIcons.printer,
                label: 'Expenses',
                index: 4,
                isSelected: selectedIndex == 4,
                onTap: onTap,
                textOnPrimary: textOnPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool isSelected;
  final Function(int) onTap;
  final Color textOnPrimary;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.textOnPrimary,
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

class _InventoryPage extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavItemTapped;

  const _InventoryPage({
    required this.selectedIndex,
    required this.onNavItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return InventoryActionsScreen(
        selectedIndex: selectedIndex,
        onNavItemTapped: onNavItemTapped,
      );
    } catch (e) {
      return const Center(child: Text('Inventory Error'));
    }
  }
}
