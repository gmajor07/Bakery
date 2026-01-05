// lib/screens/customer_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
// Import your theme or use Theme.of(context)

// ⭐️ Formatting Helpers (Can be shared with CustomerScreen)
String formatCurrencyNoDecimal(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_TZ',
    symbol: 'TSh',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

class CustomerDetailScreen extends ConsumerWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = customer.status == 'active' ? Colors.brown : Colors.red;
    final isDefaultIcon = customer.isDefault
        ? const Icon(Icons.star, color: Colors.amber, size: 20)
        : const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Name and Default Icon
                Row(
                  children: [
                    Text(
                      customer.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    isDefaultIcon,
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),

                // Contact and Basic Info
                _buildInfoRow(
                  context,
                  Icons.email,
                  'Email',
                  customer.email,
                ),
                _buildInfoRow(
                  context,
                  Icons.phone,
                  'Phone',
                  customer.phone,
                ),

                // ⭐️ ADDED: Address Info
                _buildInfoRow(
                  context,
                  Icons.location_on,
                  'Address',
                  customer.address, // ⬅️ ASSUMED FIELD: Must exist on your Customer model
                ),


                const Divider(height: 24),
                // ⭐️ NEW: Total Credit/Loan/Outstanding Balance (Assuming 'totalCredit' is a property on your Customer model)
                // If 'totalCredit' is not a field, you must add it to your Customer model.
                _buildFinancialRow(
                  context,
                  'Total Credit',
                  customer.currentCredit, // ⬅️ ASSUMED FIELD
                  Icons.money,
                ),

                // Financial and Status Info
                _buildFinancialRow(
                  context,
                  'Credit Limit',
                  customer.creditLimit,
                  Icons.account_balance_wallet,
                ),

                const Divider(height: 24),

                _buildStatusRow(context, 'Status', customer.status, statusColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context,
      IconData icon,
      String label,
      String value,
      ) {
    // Handle empty or null values gracefully for display
    final displayValue = value.isEmpty ? 'N/A' : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(
      BuildContext context,
      String label,
      double amount,
      IconData icon,
      ) {
    final formattedAmount = formatCurrencyNoDecimal(amount);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedAmount,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: amount > 0 ? Colors.brown : Colors.brown.shade700, // Highlight outstanding credit
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
      BuildContext context,
      String label,
      String value,
      Color color,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 20, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}