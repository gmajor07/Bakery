import 'package:flutter/material.dart';
import 'inventory_screen.dart';
import 'material_action_screen.dart';
import 'product_screen.dart';

// Define colors locally for consistency
const Color primaryColor = Color(0xFFC8A2C8);
const Color textDark = Color(0xFF3C3C3C);
const Color creamBackground = Color(0xFFFAF7F0);
const Color cardOne = Color(0xFF85C1E9); // Light Blue
const Color cardTwo = Color(0xFFF5B7B1); // Light Pink

class InventoryActionsScreen extends StatelessWidget {
  const InventoryActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: creamBackground,
      appBar: AppBar(
        title: const Text(
          'Inventory Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage finished goods, raw ingredients, and supplies.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Cards - Replaced fixed card height with consistent grid/list
              Expanded(
                child: isTablet
                    ? _buildTabletLayout(context)
                    : _buildMobileLayout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Layout Builders ---

  Widget _buildTabletLayout(BuildContext context) {
    // Using the enlarged _ActionCard consistent with dashboard
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2, // Consistent card aspect ratio
      children: _buildAllCards(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    // Mobile layout now uses the full-width _ActionCard
    return ListView(
      padding: const EdgeInsets.only(bottom: 16), // Padding for end of list
      children: _buildAllCards(context)
          .map((card) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: card,
      ))
          .toList(),
    );
  }

  // --- Card Definitions ---

  List<Widget> _buildAllCards(BuildContext context) {
    return [
      // 1. Products (Finished Goods)
      _ActionCard(
        color: Colors.teal, // Use strong colors for visual separation
        label: 'Products',
        subtitle: 'Manage finished baked goods stock levels.',
        icon: Icons.cake_rounded, // Better bakery icon
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen()));
        },
      ),

      // 2. Materials (Raw Ingredients)
      _ActionCard(
        color: cardOne,
        label: 'Raw Materials',
        subtitle: 'Track flour, sugar, eggs, and other ingredients.',
        icon: Icons.kitchen_rounded, // Better ingredient icon
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => MaterialActionScreen()));
        },
      ),

      // 3. Supplies (Non-raw items)
      _ActionCard(
        color: Colors.purpleAccent,
        label: 'Supplies',
        subtitle: 'Manage packaging, uniforms, and non-consumables.',
        icon: Icons.format_paint_rounded,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()));
        },
      ),

      // 4. Stock Adjustments (New Action)
      _ActionCard(
        color: Colors.orange,
        label: 'Adjustments',
        subtitle: 'Record waste, breakage, or inventory corrections.',
        icon: Icons.edit_note_rounded,
        onTap: () {
          // Placeholder for a dedicated screen
        },
      ),
    ];
  }
}

// Reusing the modern _ActionCard structure, adapted for Inventory
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
              // Icon section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              // Text section
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