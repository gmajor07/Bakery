// lib/screens/bakery_home_screen.dart
import 'package:bak/screens/customer_list_screen.dart';
import 'package:bak/screens/pos_screens/pos_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../provider/user_provider.dart'; // Ensure this file exists and exports userProvider
import 'sales_screens/sales_actions_screen.dart';
import 'production_screen.dart';
import 'purchases_screens/purchases_actions_screen.dart';
import 'inventory_actions_screen.dart';
import 'sales_screens/sales_history_screen.dart';

class BakeryHomeScreen extends ConsumerStatefulWidget {
  const BakeryHomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _BakeryHomeScreenState();
}

class _BakeryHomeScreenState extends ConsumerState<BakeryHomeScreen> {
  int _selectedIndex = 0;

  // Modern Bakery Theme Colors
  static const Color primaryColor = Color(0xFFC8A2C8); // Soft Lavender/Lilac
  static const Color secondaryColor = Color(0xFFF0E68C); // Khaki/Beige for Accent
  static const Color creamBackground = Color(0xFFFAF7F0); // Off-White/Cream

  final List<Widget> _pages = [
    const _DashboardBody(), // 0: Home (Dashboard)
    const SalesActionsScreen(), // 1: Sales
    const PurchasesActionsScreen(), // 2: Purchases
    const SizedBox.shrink(), // 3: POS (handled separately by FAB)
    const InventoryActionsScreen(), // 4: Inventory
    const ProductionScreen(), // 5: Production/More
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (!next.isAuthenticated) {
        // Redirect if not authenticated
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: creamBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: const Text(
          'APOTEk Bakery',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      // Floating POS centered
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 72,
        width: 72,
        child: FittedBox(
          child: FloatingActionButton(
            backgroundColor: primaryColor,
            elevation: 8,
            onPressed: () => _openPos(context),
            tooltip: 'Open POS',
            child: const Icon(Icons.shopping_cart, size: 30, color: Colors.white),
          ),
        ),
      ),

      // Custom Floating Round Card Bottom Navigation Bar
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16, // Adds space below the navigation bar
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30), // Increased radius for rounder card
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3), // Shadow matches primary color
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 8), // Lift the card higher
              ),
            ],
          ),
          child: ClipRRect(
            // Clip the content to match the rounded container
            borderRadius: BorderRadius.circular(30),
            child: BottomAppBar(
              color: Colors.transparent,
              elevation: 0,
              shape: const CircularNotchedRectangle(),
              notchMargin: 8,
              // Adjusted height to prevent overflow
              child: SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // 0: Home
                    _buildNavItem(
                      icon: Icons.bakery_dining_rounded,
                      label: 'Home',
                      index: 0,
                    ),
                    // 1: Sales (New Icon)
                    _buildNavItem(
                      icon: Icons.trending_up_rounded,
                      label: 'Sales',
                      index: 1,
                    ),
                    // Spacer for FAB
                    const SizedBox(width: 48),
                    // 2: Purchases (New Link)
                    _buildNavItem(
                      icon: Icons.local_shipping_rounded,
                      label: 'Purchases',
                      index: 2,
                    ),
                    // 4: Inventory (New Index/Icon)
                    _buildNavItem(
                      icon: Icons.storage_rounded,
                      label: 'Stock',
                      index: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      // The selected index logic adjusts to skip the placeholder index (3) for POS
      body: _pages[_selectedIndex > 2 ? _selectedIndex + 1 : _selectedIndex],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _selectedIndex = index);
        },
        child: SizedBox( // Use SizedBox instead of Padding for better control, preventing overflow
          width: 60,
          height: 56, // Match the BottomAppBar height
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? primaryColor : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(height: 2), // Reduced spacing
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? primaryColor : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPos(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PosScreen()),
    );
  }
}

/// Dashboard body with enhanced UI and layout
class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  // Define colors within this scope for access and consistency
  static const Color primaryColor = Color(0xFFC8A2C8);
  static const Color creamBackground = Color(0xFFFAF7F0);
  static const Color textDark = Color(0xFF3C3C3C);
  static const Color cardOne = Color(0xFF85C1E9);
  static const Color cardTwo = Color(0xFFF5B7B1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    // WATCH THE USER PROVIDER STATE HERE
    final userState = ref.watch(userProvider);

    String greeting = 'Hi, Baker!';
    if (userState.user != null) {
      // ACCESS USERNAME FROM THE USER STATE
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
            decoration: const BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.only(
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
                            greeting, // DISPLAY THE GREETING WITH USERNAME
                            style: textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formattedDate(),
                            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
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
                    color: textDark,
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
                    // 1. New Sale
                    _ActionCard(
                      color: primaryColor,
                      label: 'New Sale',
                      subtitle: 'Start a transaction',
                      icon: Icons.shopping_cart_checkout,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PosScreen()),
                        );
                      },
                    ),
                    // 3. Sales History
                    _ActionCard(
                      color: cardTwo,
                      label: 'Sales History',
                      subtitle: 'Review past transactions',
                      icon: Icons.history_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SalesHistoryScreen()),
                        );
                      },
                    ),
                    // 2. Inventory
                    _ActionCard(
                      color: Colors.amber[700]!,
                      label: 'Inventory',
                      subtitle: 'Manage stock levels',
                      icon: Icons.inventory_2_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const InventoryActionsScreen()),
                        );
                      },
                    ),

                    // 4. Purchase Orders
                    _ActionCard(
                      color: cardOne,
                      label: 'Purchases',
                      subtitle: 'Order raw materials',
                      icon: Icons.list_alt_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PurchasesActionsScreen()),
                        );
                      },
                    ),
                    // 5. Production
                    _ActionCard(
                      color: Colors.pinkAccent[200]!,
                      label: 'Production',
                      subtitle: 'Plan & track baking',
                      icon: Icons.microwave_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProductionScreen()),
                        );
                      },
                    ),
                    // 6. Settings/Reports
                    _ActionCard(
                      color: Colors.blueGrey,
                      label: 'Customer',
                      subtitle: 'create and View customer',
                      icon: Icons.person_3,
                      onTap: () {
                        // Navigate to a dedicated reports screen or a settings screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CustomerListScreen()),
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

// Action card widget (retains textDark definition fix)
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
    const Color textDark = Color(0xFF3C3C3C);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: color.withOpacity(0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
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