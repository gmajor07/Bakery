import 'package:bak/screens/pos_screens/pos_screen.dart';
import 'package:bak/screens/reports_action_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../auth/auth_provider.dart';
import '../provider/user_provider.dart';
import '../widgets/action_card.dart';
import 'app_restart.dart';
import 'customer/customer_list_screen.dart';
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

  // The pages list for bottom navigation items
  final List<Widget> _pages = [
    const _DashboardBody(), // 0: Home (Dashboard)
    const SalesActionsScreen(), // 1: Payments (Sales)
    const PurchasesActionsScreen(), // 2: Purchases
    const _InventoryPage(), // 3: Inventory (wrapped with debug)
    const ReportsActionScreen(), // 4: Production
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    ref.listen(authProvider, (previous, next) {
      if (!next.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Define bottom navigation colors based on theme
    final bottomNavColor = isDarkMode
        ? Colors.grey[900] // Dark gray for dark mode
        : const Color(0xFFD7CCC8); // Light brown for light mode

    final unselectedIconColor = isDarkMode
        ? Colors.grey[400] // Light gray for dark mode
        : Colors.brown[700]?.withOpacity(0.7); // Brown for light mode

    final unselectedTextColor = isDarkMode
        ? Colors.grey[400] // Light gray for dark mode
        : Colors.brown[800]?.withOpacity(0.7); // Brown for light mode

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: Text(
          'APOTEk Bakery',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            color: Colors.white38,
            tooltip: 'Refresh App',
            onPressed: () {
              AppRestart.restartApp(context);
            },
          ),

          // Logout button
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            color: Colors.white38,
            tooltip: 'Logout',
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),

      // ----------------------------------------------------------------------
      // 🆕 THEME-AWARE ROUNDED BOTTOM NAVIGATION BAR WITH 5 ITEMS
      // ----------------------------------------------------------------------
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: bottomNavColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
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
                    unselectedIconColor: unselectedIconColor,
                    unselectedTextColor: unselectedTextColor,
                  ),
                ),

                // Payments
                Expanded(
                  child: _buildNavItem(
                    icon: LucideIcons.badgeInfo,
                    label: 'Payments',
                    index: 1,
                    unselectedIconColor: unselectedIconColor,
                    unselectedTextColor: unselectedTextColor,
                  ),
                ),

                // Purchases
                Expanded(
                  child: _buildNavItem(
                    icon: LucideIcons.shoppingCart,
                    label: 'Purchases',
                    index: 2,
                    unselectedIconColor: unselectedIconColor,
                    unselectedTextColor: unselectedTextColor,
                  ),
                ),

                // Inventory
                Expanded(
                  child: _buildNavItem(
                    icon: LucideIcons.box,
                    label: 'Inventory',
                    index: 3,
                    unselectedIconColor: unselectedIconColor,
                    unselectedTextColor: unselectedTextColor,
                  ),
                ),

                // Production
                Expanded(
                  child: _buildNavItem(
                    icon: LucideIcons.printer,
                    label: 'Report',
                    index: 4,
                    unselectedIconColor: unselectedIconColor,
                    unselectedTextColor: unselectedTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }

  // Helper widget for bottom navigation items
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required Color? unselectedIconColor,
    required Color? unselectedTextColor,
  }) {
    final bool isSelected = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          height: 65,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with selection indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  // Selection background (only shows when selected)
                  if (isSelected)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                    ),

                  // Icon
                  Icon(
                    icon,
                    color: isSelected ? primaryColor : unselectedIconColor,
                    size: 22,
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Label
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected ? primaryColor : unselectedTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pop(context);
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
  const _InventoryPage();

  @override
  Widget build(BuildContext context) {
    try {
      return const InventoryActionsScreen();
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
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final textOnPrimary = colorScheme.onPrimary;
    final textBodyColor = textTheme.bodyMedium?.color;

    final userState = ref.watch(userProvider);

    String greeting = 'Hi, Baker!';
    if (userState.user != null) {
      greeting = 'Hi, ${userState.user!.name.split(' ').first}!';
    } else if (userState.isLoading) {
      greeting = 'Loading...';
    } else if (userState.error != null) {
      greeting = 'Welcome!';
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Rounded top header with greeting and search
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: textTheme.headlineMedium?.copyWith(
                              color: textOnPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formattedDate(),
                            style: textTheme.bodyMedium?.copyWith(
                              color: textOnPrimary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions Grid (Centered content)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Access',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textBodyColor,
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
                          MaterialPageRoute(builder: (_) => const PosScreen()),
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
                            builder: (_) => const SalesHistoryScreen(),
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
                            builder: (_) => const PurchaseOrdersScreen(),
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
                          MaterialPageRoute(builder: (_) => ProductionScreen()),
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
                          MaterialPageRoute(builder: (_) => CustomerScreen()),
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

          const SizedBox(height: 30),
        ],
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
