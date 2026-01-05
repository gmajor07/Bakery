import 'package:bak/theme.dart';
import 'package:flutter/material.dart';
import '../widgets/action_card.dart';

// Secondary accent colors for distinct report sections
class ReportsActionScreen extends StatelessWidget {
  const ReportsActionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme; // Use textTheme

    const crossAxisCount = 2;
    final primaryColor = colorScheme.primary;
    final backgroundColor = colorScheme.background; // Use background color
    final onPrimary = colorScheme.onPrimary;
    final textBodyColor = textTheme.bodyMedium?.color; // Get body text color

    return Scaffold(
      backgroundColor: backgroundColor, // Apply background color to Scaffold
      appBar: AppBar(
        title: Text(
          'Reports & Analytics',
          style: TextStyle(color: onPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
        // The iconTheme should typically use colorScheme.onPrimary for consistency with the title color on a primary background
        iconTheme: IconThemeData(color: onPrimary),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Use consistent padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Quick Actions Heading
              Text(
                'Quick Reports', // Changed to 'Quick Reports' to fit context
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textBodyColor,
                ),
              ),
              const SizedBox(height: 16), // Spacing after the title
              // 2. Action Cards Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    // 1. Sales Reports
                    ActionCard(
                      color: primaryColor,
                      label: 'Sales ',
                      subtitle: 'Sales Reports',
                      icon: Icons.ssid_chart_rounded,
                      onTap: () {
                        // TODO: Navigate to Sales Reports screen
                      },
                      contentAlignment: CrossAxisAlignment.center,
                      textAlignment: TextAlign.center,
                    ),

                    // 2. Purchases Reports
                    ActionCard(
                      color: primaryColor,
                      label: 'Purchases',
                      subtitle: 'Purchases Reports',
                      icon: Icons.shopping_bag_rounded,
                      onTap: () {
                        // TODO: Navigate to Purchases Reports screen
                      },
                      contentAlignment: CrossAxisAlignment.center,
                      textAlignment: TextAlign.center,
                    ),

                    // 3. Inventory Reports
                    ActionCard(
                      color: primaryColor,
                      label: 'Inventory ',
                      subtitle: 'Inventory Reports',
                      icon: Icons.assessment_rounded,
                      onTap: () {
                        // TODO: Navigate to Inventory Reports screen
                      },
                      contentAlignment: CrossAxisAlignment.center,
                      textAlignment: TextAlign.center,
                    ),

                    // 4. Production Reports
                    ActionCard(
                      color: primaryColor,
                      label: 'Production ',
                      subtitle: 'Production Reports',
                      icon: Icons.precision_manufacturing_rounded,
                      onTap: () {
                        // TODO: Navigate to Production Reports screen
                      },
                      contentAlignment: CrossAxisAlignment.center,
                      textAlignment: TextAlign.center,
                    ),

                    // 5. Accounting Reports
                    ActionCard(
                      color: primaryColor,
                      label: 'Accounting ',
                      subtitle: 'Accounting Reports',
                      icon: Icons.account_balance_rounded,
                      onTap: () {
                        // TODO: Navigate to Accounting Reports screen
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
