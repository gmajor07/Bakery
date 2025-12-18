// lib/screens/sales_screens/sales_actions_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/action_card.dart';
import 'outstanding_payment_screen.dart';
import 'payment_history_screen.dart';

class SalesActionsScreen extends StatelessWidget {
  const SalesActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Access theme colors
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final backgroundColor = colorScheme.background; // Changed from .surface
    final onPrimary = colorScheme.onPrimary;
    final textBodyColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: backgroundColor, // Now using background color
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Credit Payments',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: onPrimary),
        centerTitle: true,
        elevation: 0,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title for consistency with other screens
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textBodyColor,
                ),
              ),
              const SizedBox(height: 16),

              // Grid of action cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    // 1. Outstanding Payments
                    ActionCard(
                      color: primaryColor,
                      label: 'Outstanding Payments',
                      subtitle: 'Manage payments credits',
                      icon: LucideIcons.badgeInfo,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OutstandingPaymentsScreen(),
                          ),
                        );
                      },
                      contentAlignment: CrossAxisAlignment.center,
                      textAlignment: TextAlign.center,
                    ),

                    // 2. Payment History
                    ActionCard(
                      color: primaryColor,
                      label: 'Payments History',
                      subtitle: 'Track incoming payments',
                      icon: LucideIcons.clock,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentHistoryScreen(),
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
