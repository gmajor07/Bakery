import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Using Lucide Icons for consistency
// Note: Ensure adjustment_screen.dart and material_screen.dart are correctly named
import 'adjustment_screen.dart';
import 'material_screen.dart';
import 'product_screen.dart';
import 'inventory_screen.dart'; // Assuming this is the Supplies screen

class InventoryActionsScreen extends StatelessWidget {
  const InventoryActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ⭐️ Get the theme colors
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final onPrimary = colorScheme.onPrimary;
    final background = colorScheme.background;
    final textBodyColor = Theme.of(context).textTheme.bodyMedium?.color;

    // Define break point for 2 or 3 columns
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth >= 768 ? 3 : 2;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          'Inventory Management',
          style: TextStyle(color: onPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Control',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: textBodyColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage finished goods, raw ingredients, and supplies.',
                      style: TextStyle(
                        fontSize: 14,
                        color: textBodyColor?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // ⭐️ REVISED: Unified GridView for all sizes (Responsive)
              Expanded(
                child: GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  // Use a small aspect ratio for density in the grid
                  childAspectRatio: 1.2,
                  padding: const EdgeInsets.only(bottom: 16),
                  children: _buildAllCards(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Card Definitions ---

  List<Widget> _buildAllCards(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    // Using a different accent for Supplies for visual distinction
    final accentColor = Colors.orange;

    return [
      // 1. Products (Finished Goods)
      _ActionCard(
        color: primaryColor,
        label: 'Products',
        subtitle: 'Manage finished baked goods stock levels.',
        icon: LucideIcons.cake, // Updated Icon
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductsScreen()),
          );
        },
      ),

      // 2. Materials (Raw Ingredients)
      _ActionCard(
        color: primaryColor.withOpacity(0.8), // Slight variation
        label: 'Materials',
        subtitle: 'Track flour, sugar, eggs, and other ingredients.',
        icon: LucideIcons.package, // Updated Icon
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MaterialsScreen()),
          );
        },
      ),

      // 3. Supplies (Non-raw items)
      _ActionCard(
        // ⭐️ CHANGE: Using a distinct accent color for better visual separation
        color: primaryColor.withOpacity(0.8), // Slight variation
        label: 'Supplies',
        subtitle: 'Manage packaging, uniforms, and non-consumables.',
        icon: LucideIcons.box, // Updated Icon
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InventoryScreen()),
          );
        },
      ),

      // 4. Stock Adjustments (If this is a direct inventory action)
      // Added a separate card for Adjustments for completeness, if not handled elsewhere
      _ActionCard(
        color: primaryColor.withOpacity(0.8), // Slight variation
        label: 'Stock Adjustments',
        subtitle: 'Record gains, losses, or waste in inventory.',
        icon: LucideIcons.history,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdjustmentsScreen()),
          );
        },
      ),
    ];
  }
}

// ⭐️ REVISED _ActionCard for Responsiveness ⭐️
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
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceColor = colorScheme.surface;
    final onSurfaceColor = colorScheme.onSurface;
    final onColor = colorScheme.onPrimary;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: color.withOpacity(0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          // ⭐️ FIX 1: Reduced padding from 16 to 12
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // ⭐️ FIX 2: Removed mainAxisAlignment.spaceBetween
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Icon section
              Container(
                // Reduced padding
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.9),
                  // Reduced radius
                  borderRadius: BorderRadius.circular(12),
                ),
                // ⭐️ FIX 3: Reduced icon size from 28 to 24
                child: Icon(icon, color: onColor, size: 24),
              ),

              // ⭐️ FIX 4: Added fixed spacing
              const SizedBox(height: 12),

              // Text section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      // ⭐️ FIX 5: Reduced font size from 16 to 14
                      fontSize: 14,
                      color: onSurfaceColor,
                    ),
                  ),
                  // ⭐️ FIX 6: Reduced spacing between label and subtitle
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      // ⭐️ FIX 7: Reduced font size from 12 to 11
                      fontSize: 11,
                      color: onSurfaceColor.withOpacity(0.6),
                    ),
                    maxLines: 2, // Helps prevent overflow
                    overflow: TextOverflow.ellipsis,
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