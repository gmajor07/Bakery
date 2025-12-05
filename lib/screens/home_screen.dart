// lib/screens/bakery_home_screen.dart
import 'package:bak/screens/customer_list_screen.dart';
import 'package:bak/screens/pos_screens/pos_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../auth/auth_provider.dart';
import '../provider/user_provider.dart';
import 'product_screen.dart';
import 'purchases_screens/purchases_order_screen.dart';
import 'sales_screens/sales_actions_screen.dart';
import 'production_screen.dart';
import 'purchases_screens/purchases_actions_screen.dart';
import 'inventory_actions_screen.dart';
import 'sales_screens/sales_history_screen.dart';

const String customHomeIconPath = 'assets/icons/bakery_icon.png';
const Color lightBrownBackground = Color(
  0xFFEEE3D7,
); // A light, warm brown/beige

class BakeryHomeScreen extends ConsumerStatefulWidget {
  const BakeryHomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _BakeryHomeScreenState();
}

class _BakeryHomeScreenState extends ConsumerState<BakeryHomeScreen> {
  int _selectedIndex = 0;

  // The pages list remains the same
  final List<Widget> _pages = [
    const _DashboardBody(), // 0: Home (Dashboard)
    const SalesActionsScreen(), // 1: Sales
    const PurchasesActionsScreen(), // 2: Purchases
    const SizedBox.shrink(), // 3: POS (handled separately by FAB) - NOT USED BY NAV BAR
    const InventoryActionsScreen(), // 4: Inventory (Correct screen for nav bar index 4)
    const ProductionScreen(), // 5: Production/More (If you had a nav bar item for this)
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    ref.listen(authProvider, (previous, next) {
      if (!next.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: Text(
          'APOTEk Bakery',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            child: Icon(
              Icons.credit_card_rounded,
              size: 30,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      ),

      // ----------------------------------------------------------------------
// 🛠️ FIXED BOTTOM NAVIGATION BAR
// ----------------------------------------------------------------------
      bottomNavigationBar: Builder(
        builder: (context) {
          // Get theme colors dynamically
          final colorScheme = Theme.of(context).colorScheme;
          final primaryColor = colorScheme.primary;
          final isDarkMode = colorScheme.brightness == Brightness.dark;

          // Use a light background for Light mode, and surfaceDark for Dark mode
          // (You can access surfaceDark/surfaceLight through colorScheme.surface)
          final navBarContainerColor = isDarkMode
              ? colorScheme.surface // Use surfaceDark from your theme
              : const Color(0xFFEEE3D7); // Custom light brown background for light mode

          return Padding(
            // RETAINED PADDING
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                color: navBarContainerColor, // ✅ FIXED: Use dynamic color
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    // Use primary color for the shadow
                    color: primaryColor.withOpacity(isDarkMode ? 0.3 : 0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BottomAppBar(
                  // Use transparent color since the container handles the background
                  color: Colors.transparent,
                  elevation: 0,
                  // RETAINED SHAPE AND MARGIN
                  shape: const CircularNotchedRectangle(),
                  notchMargin: 8,
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Home (custom asset) - Assuming _buildCustomNavItem uses primaryColor
                        _buildCustomNavItem(
                          primaryColor: primaryColor, // ✅ FIXED: Pass dynamic primaryColor
                          label: 'Home',
                          index: 0,
                          imagePath: customHomeIconPath,
                        ),

                        // Sales
                        _buildNavItem(
                          primaryColor: primaryColor, // ✅ FIXED: Pass dynamic primaryColor
                          icon: LucideIcons.badgeInfo,
                          label: 'Payments',
                          index: 1,
                        ),

                        // SLIGHTLY REDUCED SPACE FOR FAB
                        const SizedBox(width: 40),

                        // Purchases
                        _buildNavItem(
                          primaryColor: primaryColor, // ✅ FIXED: Pass dynamic primaryColor
                          icon: LucideIcons.shoppingCart,
                          label: 'Purchases',
                          index: 2,
                        ),

                        // Inventory
                        _buildNavItem(
                          primaryColor: primaryColor, // ✅ FIXED: Pass dynamic primaryColor
                          icon: LucideIcons.box,
                          label: 'Inventory',
                          index: 4, // Nav bar index is 4
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      body: _pages[_selectedIndex],
    );
  }

  // Helper widget for standard Material Icons (Sales, Purchases, Inventory)
  Widget _buildNavItem({
    required Color primaryColor,
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;
    final defaultIconColor = Theme.of(context).brightness == Brightness.light
        ? Colors.grey[600]
        : Colors.white54;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // This ensures that when index 4 (Inventory) is tapped, it goes to page 4
          setState(() => _selectedIndex = index);
        },
        child: SizedBox(
          // REDUCED WIDTH FROM 60 TO 50 FOR NARROW SCREENS
          width: 50,
          height: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? primaryColor : defaultIconColor,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  // SLIGHTLY REDUCED FONT SIZE
                  fontSize: 9,
                  color: isSelected ? primaryColor : defaultIconColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                // ENSURE TEXT CLIPS IF TOO LONG
                overflow: TextOverflow.clip,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ⭐️ NEW Helper widget for Custom Asset Icon (Home)
  Widget _buildCustomNavItem({
    required Color primaryColor,
    required String imagePath,
    required String label,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;
    final defaultIconColor = Theme.of(context).brightness == Brightness.light
        ? Colors.grey[600]
        : Colors.white54;

    // Use a ColorFilter to tint the asset image for the selected state
    final Color iconColor = isSelected ? primaryColor : defaultIconColor!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _selectedIndex = index);
        },
        child: SizedBox(
          // REDUCED WIDTH FROM 60 TO 50 FOR NARROW SCREENS
          width: 50,
          height: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                imagePath,
                color: iconColor, // Apply color tinting
                height: 24,
                width: 24,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback icon if the asset is not found
                  return Icon(
                    Icons.bakery_dining_rounded,
                    color: iconColor,
                    size: 24,
                  );
                },
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  // SLIGHTLY REDUCED FONT SIZE
                  fontSize: 9,
                  color: isSelected ? primaryColor : defaultIconColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                // ENSURE TEXT CLIPS IF TOO LONG
                overflow: TextOverflow.clip,
                maxLines: 1,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    // 4. Use theme colors
    final primaryColor = colorScheme.primary;
    final textOnPrimary = colorScheme.onPrimary;
    final background = colorScheme.surface;
    final textBodyColor =
        textTheme.bodyMedium?.color; // Get body text color for contrast

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
            decoration: BoxDecoration(
              // 5. Use primary color
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
                            greeting, // DISPLAY THE GREETING WITH USERNAME
                            style: textTheme.headlineMedium?.copyWith(
                              // 6. Use colorScheme.onPrimary for text on primary background
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
                  // MAINTAIN childAspectRatio: 1.2 to keep cards slightly taller than wide
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
                      subtitle: 'Review past transactions',
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
                      label: 'Products',
                      subtitle: 'Manage products',
                      icon: LucideIcons.badgeCheck,
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
                      label: 'Purchases',
                      subtitle: 'Order raw materials',
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
                      label: 'Production',
                      subtitle: 'Plan & track baking',
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
                      label: 'Customer',
                      subtitle: 'Create & view customers',
                      icon: LucideIcons.userCircle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomerScreen(),
                          ),
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

// Action card widget (RESPONSIVENESS FIX APPLIED HERE)
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
    // 8. Use the theme's surface color for the card background
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textBodyColor = Theme.of(
      context,
    ).textTheme.bodyMedium?.color; // Use theme text color

    return Material(
      color: surfaceColor,
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
            // ⭐️ FIX: Removed mainAxisAlignment: MainAxisAlignment.spaceBetween
            // to allow content to fit without overflow on small screens.
            children: [
              Container(
                padding: const EdgeInsets.all(10), // Reduced padding
                decoration: BoxDecoration(
                  color: color.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12), // Reduced radius
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 24, // Reduced icon size
                ),
              ),
              // Added fixed spacing
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14, // Reduced font size
                      color: textBodyColor, // Use theme text color
                    ),
                  ),
                  const SizedBox(height: 2), // Reduced spacing
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11, // Reduced font size
                      color: textBodyColor?.withOpacity(0.6),
                    ), // Use theme text color
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