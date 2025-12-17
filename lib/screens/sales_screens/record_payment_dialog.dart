import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/payment_provider.dart';
// ⬅️ Assuming this path for your currency formatter utility
import '../../utils/formatters.dart';

class RecordPaymentDialog extends ConsumerStatefulWidget {
  final int saleId;
  final int receiptNumber;
  final double outstanding;

  const RecordPaymentDialog({
    super.key,
    required this.saleId,
    required this.receiptNumber,
    required this.outstanding,
  });

  @override
  ConsumerState<RecordPaymentDialog> createState() =>
      _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends ConsumerState<RecordPaymentDialog> {
  final controller = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = controller.text.trim();

    if (raw.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter amount')),
        );
      }
      return;
    }

    // Replace comma with dot if locale uses comma as decimal separator,
    // although generally we rely on keyboardType: TextInputType.number
    final amount = double.tryParse(raw);

    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount')),
        );
      }
      return;
    }

    if (amount > widget.outstanding) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amount exceeds outstanding balance')),
        );
      }
      return;
    }

    setState(() => loading = true);

    try {
      final api = ref.read(paymentApiProvider);
      await api.recordPayment(saleId: widget.saleId, amount: amount);

      if (kDebugMode) {
        print('📤 Submitting payment: saleId=${widget.saleId}, amount=$amount');
      }
      // Pass 'true' to indicate success and possibly trigger a data refresh
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (kDebugMode) {
        print('❌ record payment failed: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record payment: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog( // ⬅️ Using Dialog for better customization
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section
            Row(
              children: [
                Icon(Icons.receipt_long, color: colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Record Payment',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Summary Section
            Text(
              'Receipt: #${widget.receiptNumber}',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),

            // Outstanding Balance
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    // ⬅️ PRICE FORMATTING
                    formatCurrency(widget.outstanding),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Input Field
            TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              // ⬅️ MODERN INPUT DECORATION
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.attach_money),
                labelText: 'Amount Paid',
                hintText: 'e.g., 50000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton( // ⬅️ Modern FilledButton
                  onPressed: loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: colorScheme.primary,
                  ),
                  child: loading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Record Payment',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}