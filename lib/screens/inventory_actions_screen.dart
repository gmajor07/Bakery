import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/action_card.dart';
import 'adjustment_screen.dart';
import 'material_screen/material_screen.dart';
import 'product_screen.dart';
import 'inventory_screen.dart';

class InventoryActionsScreen extends StatelessWidget {
  const InventoryActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final onPrimary = colorScheme.onPrimary;
    final background = colorScheme.background;

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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    // 2. Materials (Raw Ingredients)
                    ActionCard(
                      color: primaryColor,
                      label: 'Materials',
                      subtitle: 'Track ingredients',
                      icon: LucideIcons.cakeSlice,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MaterialsScreen(),
                          ),
                        );
                      },
                      contentAlignment: CrossAxisAlignment.center,
                      textAlignment: TextAlign.center,
                    ),

                    // 3. Supplies (Non-raw items)
                    ActionCard(
                      color: primaryColor,
                      label: 'Supplies',
                      subtitle: 'Manage supplies',
                      icon: LucideIcons.cake,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InventoryScreen(),
                          ),
                        );
                      },
                      contentAlignment: CrossAxisAlignment.center,
                      textAlignment: TextAlign.center,
                    ),
                    // 1. Products (Finished Goods)
                    ActionCard(
                      color: primaryColor,
                      label: 'Products',
                      subtitle: 'Manage stock levels',
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

                    // 4. Stock Adjustments
                    ActionCard(
                      color: primaryColor,
                      label: 'Stock Adjustments',
                      subtitle: 'Record stock',
                      icon: LucideIcons.history,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdjustmentsScreen(),
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
