import 'package:flutter/material.dart';
import 'adjustment_screen.dart';
import 'material_screen.dart';


// Define colors locally for consistency
const Color primaryColor = Color(0xFFC8A2C8);
const Color textDark = Color(0xFF3C3C3C);
const Color creamBackground = Color(0xFFFAF7F0);
const Color cardOne = Color(0xFF85C1E9); // Light Blue

class MaterialActionScreen extends StatelessWidget {
  const MaterialActionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 768;
    // We will use 2 columns for all mobile and tablet layouts for a consistent, larger card look
    final crossAxisCount = 2;

    return Scaffold(
      backgroundColor: creamBackground,
      appBar: AppBar(
        title: const Text(
          'Raw Materials Actions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
      ),

      body: SafeArea(
        child: Padding(
          // Using slightly less vertical padding to prevent overflow
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Material Management',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'View, categorize, and adjust ingredient stock.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Cards Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2, // Consistent card aspect ratio
                  children: [
                    // 1. Material List (View all raw ingredients)
                    _ActionCard(
                      color: primaryColor,
                      label: 'Material List',
                      subtitle: 'View current ingredient stock and details.',
                      icon: Icons.list_alt_rounded,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MaterialsScreen()));
                      },
                    ),

                    // 2. Adjustments (Waste/Correction)
                    _ActionCard(
                      color: Colors.orange,
                      label: 'Stock Adjustments',
                      subtitle: 'Record materials.',
                      icon: Icons.edit_note_rounded,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdjustmentsScreen()));
                      },
                    ),

                    // 3. Categories (New action for structured management)
                    _ActionCard(
                      color: cardOne,
                      label: 'Categories',
                      subtitle: 'Organize materials (e.g., Flours, Dairy, Spices).',
                      icon: Icons.folder_open_rounded,
                      onTap: () {
                        // Placeholder for a dedicated screen
                        // Navigator.push(context, MaterialPageRoute(builder: (_) => const MaterialCategoryScreen()));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusing the modern _ActionCard structure from other screens
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
    // Defined text color locally for consistency
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