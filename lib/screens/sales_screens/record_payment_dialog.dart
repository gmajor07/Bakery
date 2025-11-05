import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/payment_provider.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter amount')));
      return;
    }

    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    if (amount > widget.outstanding) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount exceeds outstanding balance')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // ✅ Use ref.read() safely (gets your global Ref from Riverpod)
      final api = ref.read(paymentApiProvider);
      await api.recordPayment(saleId: widget.saleId, amount: amount);

      print('📤 Submitting payment: saleId=${widget.saleId}, amount=$amount');
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      print('❌ record payment failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to record payment.')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Receipt #: ${widget.receiptNumber}'),
          const SizedBox(height: 8),
          Text(
            'Outstanding Balance: ${widget.outstanding.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount',
              hintText: 'Enter amount',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: loading ? null : _submit,
          child: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Record Payment'),
        ),
      ],
    );
  }
}
