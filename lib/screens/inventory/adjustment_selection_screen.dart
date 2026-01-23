import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/action_card.dart';
import 'adjustment_screen.dart';
import 'product_adjustment_screen.dart';

class AdjustmentTypeSelectionScreen extends StatelessWidget {
  const AdjustmentTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final textOnPrimary = colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // 1. TITLE (Outside the card)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adjustments',
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 2. BIG COLORED CARD (with top radius) - extends to bottom
          Padding(
            padding: const EdgeInsets.only(top: 90),
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
                                        builder: (_) =>
                                            const MaterialAdjustmentsScreen(
                                              type: 'raw_material',
                                            ),
                                      ),
                                    );
                                  },
                                  contentAlignment: CrossAxisAlignment.center,
                                  textAlignment: TextAlign.center,
                                ),

                                // 2. Supply Adjustments
                                ActionCard(
                                  color: primaryColor,
                                  label: 'Supplies',
                                  subtitle: 'Adjust Supplies',
                                  icon: LucideIcons.cake,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const MaterialAdjustmentsScreen(
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
                                        builder: (_) =>
                                            const ProductAdjustmentsScreen(),
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
                            // Back
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        LucideIcons.arrowLeft,
                                        color: textOnPrimary.withOpacity(0.5),
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Back',
                                        style: TextStyle(
                                          color: textOnPrimary.withOpacity(0.5),
                                          fontSize: 10,
                                          fontWeight: FontWeight.normal,
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
