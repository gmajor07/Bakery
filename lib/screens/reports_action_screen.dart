import 'package:bak/theme.dart';
import 'package:flutter/material.dart';

// Secondary accent colors for distinct report sections

class ReportsActionScreen extends StatelessWidget {
  const ReportsActionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    const crossAxisCount = 2;
    final primaryColor = colorScheme.primary;
    final onPrimary = colorScheme.onPrimary;


    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reports & Analytics',
          style: TextStyle(color: onPrimary, fontWeight: FontWeight.bold),

        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Action Cards Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    // 1. Sales Reports
                    _ReportCard(
                      color: AppTheme.primaryBrown,
                      label: 'Sales ',
                      subtitle: 'Track revenue',
                      icon: Icons.ssid_chart_rounded,
                      onTap: () {
                        // TODO: Navigate to Sales Reports screen
                      },
                    ),

                    // 2. Purchases Reports
                    _ReportCard(
                      color: AppTheme.primaryBrown,
                      label: 'Purchases',
                      subtitle: 'Analyze procurement history.',
                      icon: Icons.shopping_bag_rounded,
                      onTap: () {
                        // TODO: Navigate to Purchases Reports screen
                      },
                    ),

                    // 3. Inventory Reports
                    _ReportCard(
                      color: AppTheme.primaryBrown,
                      label: 'Inventory ',
                      subtitle: 'Monitor stock and valuation.',
                      icon: Icons.assessment_rounded,
                      onTap: () {
                        // TODO: Navigate to Inventory Reports screen
                      },
                    ),

                    // 4. Production Reports
                    _ReportCard(
                      color: AppTheme.primaryBrown,
                      label: 'Production ',
                      subtitle: 'Review material usage.',
                      icon: Icons.precision_manufacturing_rounded,
                      onTap: () {
                        // TODO: Navigate to Production Reports screen
                      },
                    ),

                    // 5. Accounting Reports
                    _ReportCard(
                      color: AppTheme.primaryBrown,
                      label: 'Accounting ',
                      subtitle: 'View balance sheets and ledger.',
                      icon: Icons.account_balance_rounded,
                      onTap: () {
                        // TODO: Navigate to Accounting Reports screen
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

// Reusable Report Card Widget
class _ReportCard extends StatelessWidget {
  final Color color;
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ReportCard({
    required this.color,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final titleColor = colorScheme.onSurface;
    final cardColor = colorScheme.surface;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      // Shadow color derived from the accent color
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
                  // Using the specified accent color
                  color: color,
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
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: titleColor, // High contrast text
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      // Muted subtitle text color
                      color: colorScheme.onSurface.withOpacity(0.5),
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