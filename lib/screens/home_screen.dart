import 'package:bak/screens/pos_screens/pos_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../auth/auth_provider.dart';
import '../provider/user_provider.dart';
import '../widgets/action_card.dart';
import 'app_restart.dart';
import 'customer/customer_list_screen.dart';
import 'expense_screen.dart';
import 'product_screen.dart';
import 'purchases_screens/purchases_order_screen.dart';
import 'sales_screens/payment_actions_screen.dart';
import 'production_screen.dart';
import 'purchases_screens/purchases_actions_screen.dart';
import 'inventory/inventory_actions_screen.dart';
import 'sales_screens/sales_history_screen.dart';

const String customHomeIconPath = 'assets/icons/bakery_icon.png';

class BakeryHomeScreen extends ConsumerStatefulWidget {
  const BakeryHomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _BakeryHomeScreenState();
}

class _BakeryHomeScreenState extends ConsumerState<BakeryHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            onPressed: () => AppRestart.restartApp(context),
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () => _showLogoutDialog(context),
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
    final authRef = ref; // Capture ref in closure
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
              // Manual logout - clear credentials
              authRef
                  .read(authProvider.notifier)
                  .logout(clearCredentials: true);
              Navigator.pop(dialogContext);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

/// Wrapper for Inventory screen to handle potential issues
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
      // Fallback if InventoryActionsScreen has issues
      return Scaffold(
        appBar: AppBar(
          title: const Text('Inventory'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.box,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Inventory Management',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inventory features will be available soon',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate to Products screen as alternative
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductsScreen()),
                  );
                },
                child: const Text('Go to Products'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

/// Dashboard body with enhanced UI and layout
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
    } else if (userState.isLoading) {
      greeting = 'Loading...';
    } else if (userState.error != null) {
      greeting = 'Hi, Baker!';
    }

    return Stack(
      children: [
        // 1. GREETING & DATE (Outside the card)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formattedDate(),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),

        // 2. BIG COLORED CARD (with top radius) - extends to bottom
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
                              ActionCard(
                                color: primaryColor,
                                label: 'New Sale',
                                subtitle: 'Start a transaction',
                                icon: LucideIcons.creditCard,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PosScreen(),
                                    ),
                                  );
                                },
                                contentAlignment: CrossAxisAlignment.center,
                                textAlignment: TextAlign.center,
                              ),

                              ActionCard(
                                color: primaryColor,
                                label: 'Sales History',
                                subtitle: 'Review transactions',
                                icon: LucideIcons.barChart3,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const SalesHistoryScreen(),
                                    ),
                                  );
                                },
                                contentAlignment: CrossAxisAlignment.center,
                                textAlignment: TextAlign.center,
                              ),

                              ActionCard(
                                color: primaryColor,
                                label: 'Purchase Orders',
                                subtitle: 'Manage PO',
                                icon: LucideIcons.shoppingCart,
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

                              ActionCard(
                                color: primaryColor,
                                label: 'Products',
                                subtitle: 'Manage products',
                                icon: LucideIcons.box,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProductsScreen(),
                                    ),
                                  );
                                },
                                contentAlignment: CrossAxisAlignment.center,
                                textAlignment: TextAlign.center,
                              ),

                              ActionCard(
                                color: primaryColor,
                                label: 'Production',
                                subtitle: 'View production',
                                icon: LucideIcons.factory,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductionScreen(),
                                    ),
                                  );
                                },
                                contentAlignment: CrossAxisAlignment.center,
                                textAlignment: TextAlign.center,
                              ),

                              ActionCard(
                                color: primaryColor,
                                label: 'Customers',
                                subtitle: 'Manage customers',
                                icon: LucideIcons.userCircle,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CustomerScreen(),
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
                            child: _buildNavItemWidget(
                              icon: LucideIcons.home,
                              label: 'Home',
                              index: 0,
                              unselectedIconColor: textOnPrimary.withOpacity(
                                0.5,
                              ),
                              unselectedTextColor: textOnPrimary.withOpacity(
                                0.5,
                              ),
                              isSelected: selectedIndex == 0,
                              context: context,
                              textOnPrimary: textOnPrimary,
                              primaryColor: primaryColor,
                              onTap: onNavItemTapped,
                            ),
                          ),

                          // Payments
                          Expanded(
                            child: _buildNavItemWidget(
                              icon: LucideIcons.badgeInfo,
                              label: 'Payments',
                              index: 1,
                              unselectedIconColor: textOnPrimary.withOpacity(
                                0.5,
                              ),
                              unselectedTextColor: textOnPrimary.withOpacity(
                                0.5,
                              ),
                              isSelected: selectedIndex == 1,
                              context: context,
                              textOnPrimary: textOnPrimary,
                              primaryColor: primaryColor,
                              onTap: onNavItemTapped,
                            ),
                          ),

                          // Purchases
                          Expanded(
                            child: _buildNavItemWidget(
                              icon: LucideIcons.shoppingCart,
                              label: 'Purchases',
                              index: 2,
                              unselectedIconColor: textOnPrimary.withOpacity(
                                0.5,
                              ),
                              unselectedTextColor: textOnPrimary.withOpacity(
                                0.5,
                              ),
                              isSelected: selectedIndex == 2,
                              context: context,
                              textOnPrimary: textOnPrimary,
                              primaryColor: primaryColor,
                              onTap: onNavItemTapped,
                            ),
                          ),

                          // Inventory
                          Expanded(
                            child: _buildNavItemWidget(
                              icon: LucideIcons.box,
                              label: 'Inventory',
                              index: 3,
                              unselectedIconColor: textOnPrimary.withOpacity(
                                0.5,
                              ),
                              unselectedTextColor: textOnPrimary.withOpacity(
                                0.5,
                              ),
                              isSelected: selectedIndex == 3,
                              context: context,
                              textOnPrimary: textOnPrimary,
                              primaryColor: primaryColor,
                              onTap: onNavItemTapped,
                            ),
                          ),

                          // Production
                          Expanded(
                            child: _buildNavItemWidget(
                              icon: LucideIcons.printer,
                              label: 'Expenses',
                              index: 4,
                              unselectedIconColor: textOnPrimary.withOpacity(
                                0.5,
                              ),
                              unselectedTextColor: textOnPrimary.withOpacity(
                                0.5,
                              ),
                              isSelected: selectedIndex == 4,
                              context: context,
                              textOnPrimary: textOnPrimary,
                              primaryColor: primaryColor,
                              onTap: onNavItemTapped,
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
    );
  }

  // Static method to build nav items
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
    Function(int)? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null ? () => onTap(index) : null,
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

  static String _formattedDate() {
    final now = DateTime.now();
    final dayOfWeek = _dayShort(now.weekday);
    final month = _monthShort(now.month);
    return '$dayOfWeek, ${now.day} $month ${now.year}';
  }

  static String _monthShort(int m) {
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
    return months[m - 1];
  }

  static String _dayShort(int d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d - 1];
  }
}
