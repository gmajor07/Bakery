// outstanding_payment_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/outstanding_payment.dart';
import '../../provider/payment_provider.dart';
import 'record_payment_dialog.dart';

class OutstandingPaymentDetailsScreen extends ConsumerWidget {
  final OutstandingPayment payment;

  const OutstandingPaymentDetailsScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverdue = payment.dueDate.isBefore(DateTime.now());
    final progress = payment.paidAmount / payment.totalAmount;
    final isFullyPaid = payment.balance <= 0; // Check if fully paid

    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt #${payment.receiptNumber}'),
        actions: [
          if (!isFullyPaid) // Only show payment button if not fully paid
            IconButton(
              icon: const Icon(Icons.payment),
              onPressed: () => _showRecordPaymentDialog(context, ref),
              tooltip: 'Record Payment',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              elevation: 2,
              color: isFullyPaid
                  ? Colors.green.withOpacity(0.05)
                  : isOverdue
                  ? Colors.red.withOpacity(0.05)
                  : Colors.orange.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isFullyPaid
                          ? Icons.check_circle
                          : isOverdue
                          ? Icons.warning
                          : Icons.pending,
                      color: isFullyPaid
                          ? Colors.brown
                          : isOverdue
                          ? Colors.red
                          : Colors.blueGrey,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFullyPaid
                                ? 'PAYMENT COMPLETED'
                                : isOverdue
                                ? 'OVERDUE PAYMENT'
                                : 'PENDING PAYMENT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isFullyPaid
                                  ? Colors.brown
                                  : isOverdue
                                  ? Colors.red
                                  : Colors.blueGrey,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isFullyPaid
                                ? 'Fully paid on ${DateFormat('MMM dd, yyyy').format(payment.dueDate)}'
                                : 'Due: ${DateFormat('MMM dd, yyyy').format(payment.dueDate)}',
                            style: TextStyle(
                              color: isFullyPaid
                                  ? Colors.brown
                                  : isOverdue
                                  ? Colors.red
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Payment Progress
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Progress',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      color: isFullyPaid ? Colors.brown : Colors.orange,
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${(progress * 100).toStringAsFixed(1)}% Paid'),
                        Text(
                          '${(100 - progress * 100).toStringAsFixed(1)}% Remaining',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Payment Details
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Receipt Number',
                      payment.receiptNumber.toString(),
                    ),
                    _buildDetailRow('Customer', payment.customer),
                    _buildDetailRow(
                      'Total Amount',
                      'TSh ${NumberFormat('#,##0').format(payment.totalAmount)}',
                    ),
                    _buildDetailRow(
                      'Paid Amount',
                      'TSh ${NumberFormat('#,##0').format(payment.paidAmount)}',
                    ),
                    _buildDetailRow(
                      'Outstanding Balance',
                      'TSh ${NumberFormat('#,##0').format(payment.balance)}',
                      valueColor: isFullyPaid ? Colors.brown : Colors.orange,
                      isBold: true,
                    ),
                    _buildDetailRow(
                      isFullyPaid ? 'Payment Date' : 'Due Date',
                      DateFormat('MMM dd, yyyy').format(payment.dueDate),
                      valueColor: isFullyPaid
                          ? Colors.brown
                          : isOverdue
                          ? Colors.red
                          : null,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Button - Only show if not fully paid
            if (!isFullyPaid)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showRecordPaymentDialog(context, ref),
                  icon: const Icon(Icons.payment),
                  label: const Text('Record Payment'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              )
            else
              // Show success message when fully paid
              Card(
                elevation: 2,
                color: Colors.green.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.brown, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Payment completed successfully!',
                          style: TextStyle(
                            color: Colors.brown[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => RecordPaymentDialog(
        saleId: payment.saleId,
        receiptNumber: payment.receiptNumber,
        outstanding: payment.balance,
      ),
    ).then((success) {
      if (success == true) {
        // Refresh data and pop to main screen
        ref.invalidate(outstandingPaymentsProvider);
        Navigator.pop(context); // Close details screen
      }
    });
  }
}
