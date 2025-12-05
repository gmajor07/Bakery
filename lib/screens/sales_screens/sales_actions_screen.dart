import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Import Lucide Icons
import 'outstanding_payment_screen.dart';
import 'payment_history_screen.dart';


class SalesActionsScreen extends StatelessWidget {
  const SalesActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Access theme colors
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    return Scaffold(
      // 2. Use the Theme's background color
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        // Set AppBar theme explicitly here if needed, or rely on root theme
        backgroundColor: primaryColor,
        title: Text(
          'Payment',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary),
        ),
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2, // Use the same ratio as the dashboard cards
            children: [
              // 1. Outstanding Payments
              _ActionCard(
                color: primaryColor,
                label: 'Outstanding',
                subtitle: 'Manage credit and pending balances',
                // ⭐️ NEW: Use Lucide Icon
                icon: LucideIcons.creditCard,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OutstandingPaymentsScreen(),
                    ),
                  );
                },
              ),

              // 2. Payment History
              _ActionCard(
                color: primaryColor.withOpacity(0.9), // Slightly reduced opacity for distinction
                label: 'Payment History', // Renamed for clarity
                subtitle: 'Track incoming payments',
                // ⭐️ NEW: Use Lucide Icon
                icon: LucideIcons.clock,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentHistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Updated _ActionCard to use Lucide IconData and apply responsiveness fixes
class _ActionCard extends StatelessWidget {
  final Color color;
  final String label;
  final String subtitle;
  // ⭐️ CHANGE: Switched from String assetPath to IconData icon
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.color,
    required this.label,
    required this.subtitle,
    // ⭐️ CHANGE: Updated parameter name
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final textBodyColor = textTheme.bodyMedium?.color;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: color.withOpacity(0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          // ⭐️ RESPONSIVENESS FIX 1: Reduced padding from 16 to 12
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // ⭐️ RESPONSIVENESS FIX 2: Removed mainAxisAlignment: MainAxisAlignment.spaceBetween
            // Rely on fixed spacing instead.
            children: [
              Container(
                // Reduced internal padding
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.9),
                  // Reduced border radius
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  // ⭐️ USAGE: Use the IconData
                  icon,
                  color: colorScheme.onPrimary,
                  // ⭐️ RESPONSIVENESS FIX 3: Reduced icon size from 28 to 24
                  size: 24,
                ),
              ),
              // Added fixed spacing after icon
              const SizedBox(height: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      // ⭐️ RESPONSIVENESS FIX 4: Reduced font size from 16 to 14
                      fontSize: 14,
                      color: textBodyColor,
                    ),
                  ),
                  // ⭐️ RESPONSIVENESS FIX 5: Reduced spacing between label and subtitle
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      // ⭐️ RESPONSIVENESS FIX 6: Reduced font size from 12 to 11
                      fontSize: 11,
                      color: textBodyColor?.withOpacity(0.6),
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