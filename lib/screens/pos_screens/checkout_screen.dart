import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_provider.dart';
import '../../provider/pos_provider.dart';
import '../../provider/customer_provider.dart';
import '../../provider/sales_provider.dart';
import '../../provider/sell_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String paymentMethod = 'Cash';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final cartNotifier = ref.read(cartProvider.notifier);
    final cart = ref.watch(cartProvider);
    final customersAsync = ref.watch(customerListProvider);

    final subtotal = cartNotifier.totalPrice;
    const vat = 0.0;
    final total = subtotal + vat;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Customer Selection
            Text('Customer', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            customersAsync.when(
              data: (customers) {
                final selectedCustomer = ref.watch(selectedCustomerProvider);
                return DropdownButtonFormField(
                  value: selectedCustomer,
                  hint: const Text('Select Customer'),
                  items: customers
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.name)),
                  )
                      .toList(),
                  onChanged: (value) {
                    ref.read(selectedCustomerProvider.notifier).state = value;
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (err, _) => Text('Error loading customers: $err'),
            ),

            const SizedBox(height: 24),

            // 🔹 Payment Method
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Cash'),
                    value: 'Cash',
                    groupValue: paymentMethod,
                    onChanged: (value) =>
                        setState(() => paymentMethod = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Credit'),
                    value: 'Credit',
                    groupValue: paymentMethod,
                    onChanged: (value) =>
                        setState(() => paymentMethod = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 🔹 Totals Section
            Text('Totals', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildTotalRow('Subtotal:', subtotal),
            _buildTotalRow('VAT:', vat),
            const Divider(),
            _buildTotalRow('Total:', total, isBold: true),
            const SizedBox(height: 32),

            // 🔹 Complete Sale Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (cart.isEmpty || _isProcessing)
                    ? null
                    : () async {
                  _showConfirmDialog(total);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.pink,
                ),
                child: _isProcessing
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Complete Sale',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'TSh ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  _showConfirmDialog(double total) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Sale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to complete this sale?'),
            const SizedBox(height: 12),
            _buildTotalRow('Total Amount:', total, isBold: true),
            _buildTextRow('Payment Method:', paymentMethod),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeSale(ref, total);
            },
            child: const Text('Confirm Sale'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeSale(WidgetRef ref, double total) async {
    setState(() => _isProcessing = true);

    final cart = ref.read(cartProvider);
    final customer = ref.read(selectedCustomerProvider);
    final isCredit = paymentMethod == 'Credit';

    if (isCredit && customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a customer for credit sales')),
      );
      setState(() => _isProcessing = false);
      return;
    }

    final items = cart.entries.map((e) {
      return {
        "product_id": e.value.product.id,
        "quantity": e.value.quantity,
        "price": e.value.product.price,
      };
    }).toList();

    try {
      // 🔹 Create sale
      final sale = await ref
          .read(salesProvider.notifier)
          .createSale(
        customerId: customer?.id,
        isCredit: isCredit,
        total: total,
        items: items,
      );

      print("🟢 Sale Response: $sale");

      // 🔹 Record payment ONLY for credit payment
      if (isCredit) {
        final token = ref.read(authProvider).accessToken;
        await ref
            .read(salesProvider.notifier)
            .recordPayment(
          token: token!,
          saleId: sale['id'],
          amount: total,
          paymentMethod: 'credit',
          customerId: customer?.id,
        );
      }

      ref.read(cartProvider.notifier).clearCart();
      _showSuccessDialog(sale);
    } catch (err, stack) {
      print("❌ ERROR DURING SALE:");
      print(err);
      print(stack);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sale failed: $err')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> sale) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('✅ Sale Completed'),
        content: Text(
          'Sale ID: ${sale['id']}\n'
              'Total: TSh ${sale['total']}',
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back to POS screen
            },
          ),
        ],
      ),
    );
  }
}
