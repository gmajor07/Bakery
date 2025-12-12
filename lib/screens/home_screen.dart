// lib/screens/bakery_home_screen.dart
import 'package:bak/screens/customer_list_screen.dart';
import 'package:bak/screens/pos_screens/pos_screen.dart';
import 'package:bak/screens/reports_action_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../auth/auth_provider.dart';
import '../provider/user_provider.dart';
import 'product_screen.dart';
import 'purchases_screens/purchases_order_screen.dart';
import 'sales_screens/payment_actions_screen.dart';
import 'production_screen.dart';
import 'purchases_screens/purchases_actions_screen.dart';
import 'inventory_actions_screen.dart';
import 'sales_screens/sales_history_screen.dart';

const String customHomeIconPath = 'assets/icons/bakery_icon.png';
const Color lightBrownColor = Color(0xFFD7CCC8); // Light brown color

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
        backgroundColor: colorScheme.primary,
        title: Text(
          'APOTEk Bakery',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
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
      // 🆕 ROUNDED LIGHT BROWN BOTTOM NAVIGATION BAR WITH 5 ITEMS
      // ----------------------------------------------------------------------
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ), // Adds space at bottom
        decoration: BoxDecoration(
          color: lightBrownColor, // Light brown color
          borderRadius: BorderRadius.circular(30), // Fully rounded
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
          borderRadius: BorderRadius.circular(30), // Match container radius
          child: SizedBox(
            height: 65, // Slightly shorter height
            child: Row(
              children: [
                // Home
                Expanded(
                  child: _buildNavItem(
                    icon: LucideIcons.home,
                    label: 'Home',
                    index: 0,
                  ),
                ),

                // Payments
                Expanded(
                  child: _buildNavItem(
                    icon: LucideIcons.badgeInfo,
                    label: 'Payments',
                    index: 1,
                  ),
                ),

                // Purchases
                Expanded(
                  child: _buildNavItem(
                    icon: LucideIcons.shoppingCart,
                    label: 'Purchases',
                    index: 2,
                  ),
                ),

                // Inventory
                Expanded(
                  child: _buildNavItem(
                    icon: LucideIcons.box,
                    label: 'Inventory',
                    index: 3,
                  ),
                ),

                // Production
                Expanded(
                  child: _buildNavItem(
                    icon: LucideIcons.printer,
                    label: 'Report',
                    index: 4,
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
                    color: isSelected
                        ? primaryColor
                        : Colors.brown[700]?.withOpacity(0.7),
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
                  color: isSelected
                      ? primaryColor
                      : Colors.brown[800]?.withOpacity(0.7),
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
                  // Search bar (Enhanced)
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions Grid (Enhanced/Enlarged)
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
                    _ActionCard(
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
                    ),

                    _ActionCard(
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
                    ),

                    _ActionCard(
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
                    ),

                    _ActionCard(
                      color: primaryColor,
                      label: 'Products',
                      subtitle: 'Manage produce',
                      icon: LucideIcons.box,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProductsScreen(),
                          ),
                        );
                      },
                    ),

                    _ActionCard(
                      color: primaryColor,
                      label: 'Productions',
                      subtitle: 'View production',
                      icon: LucideIcons.factory,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProductionScreen()),
                        );
                      },
                    ),

                    _ActionCard(
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

// Action card widget
class _ActionCard extends StatelessWidget {
  final Color color;
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.color,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textBodyColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: textBodyColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: textBodyColor?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
