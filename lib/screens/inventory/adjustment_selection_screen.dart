import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/action_card.dart';
import 'adjustment_screen.dart';
import 'product_adjustment_screen.dart';

class AdjustmentTypeSelectionScreen extends StatelessWidget {
  const AdjustmentTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final onPrimary = colorScheme.onPrimary;
    final background = colorScheme.surface;

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth >= 768 ? 3 : 2;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          'Select Adjustment',
          style: TextStyle(color: onPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    // 1. Material Adjustments
                    ActionCard(
                      color: primaryColor,
                      label: 'Materials',
                      subtitle: 'Adjust Materials',
                      icon: LucideIcons.cakeSlice,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MaterialAdjustmentsScreen(
                              type: 'raw_material',
                            ),
                          ),
                        );
                      },
                      contentAlignment: CrossAxisAlignment.center,
                      textAlignment: TextAlign.center,
                    ),

                    // 2. Supply Adjustments (uses same screen as Materials)
                    ActionCard(
                      color: primaryColor,
                      label: 'Supplies',
                      subtitle: 'Adjust Supplies',
                      icon: LucideIcons.cake,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MaterialAdjustmentsScreen(
                              type: 'supplies',
                            ),
                          ),
                        );
                      },
                      contentAlignment: CrossAxisAlignment.center,
                      textAlignment: TextAlign.center,
                    ),

                    // 3. Product Adjustments
                    ActionCard(
                      color: primaryColor,
                      label: 'Products',
                      subtitle: 'Adjust Products',
                      icon: LucideIcons.box,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProductAdjustmentsScreen(),
                          ),
                        );
                      },
                      contentAlignment: CrossAxisAlignment.center,
                      textAlignment: TextAlign.center,
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
