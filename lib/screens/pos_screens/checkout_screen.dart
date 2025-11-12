import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_provider.dart';
import '../../models/customer.dart';
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
  String? _selectedDueDays;
  final List<String> _dueDaysOptions = ['7', '14', '21', '30'];

  @override
  Widget build(BuildContext context) {
    final cartNotifier = ref.read(cartProvider.notifier);
    final cart = ref.watch(cartProvider);
    final customersAsync = ref.watch(customerListProvider);

    final subtotal = cartNotifier.totalPrice;
    const vat = 0.0;

    final isCredit = paymentMethod == 'Credit';
    final creditInterest = isCredit ? subtotal * 0.18 : 0.0;
    final total = isCredit ? (subtotal + creditInterest) : (subtotal + vat);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Order Summary
            _buildOrderSummary(cart, subtotal),
            const SizedBox(height: 24),

            // 🔹 Customer Selection
            _buildCustomerSection(customersAsync),
            const SizedBox(height: 24),

            // 🔹 Payment Method
            _buildPaymentMethodSection(),
            const SizedBox(height: 24),

            // 🔹 Credit Due Days (Only for Credit)
            if (paymentMethod == 'Credit') ...[
              _buildCreditDueDaysSection(),
              const SizedBox(height: 24),
            ],

            // 🔹 Totals Section
            _buildTotalsSection(subtotal, vat, creditInterest, total, isCredit),
            const SizedBox(height: 32),

            // 🔹 Complete Sale Button
            _buildCompleteSaleButton(cart, total),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(Map<int, CartItem> cart, double subtotal) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Summary',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    '${cart.length} ${cart.length == 1 ? 'item' : 'items'}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...cart.values
                .take(3)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.product.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${item.quantity} × TSh ${item.product.price.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ),
                ),
            if (cart.length > 3) ...[
              const SizedBox(height: 8),
              Text(
                '+ ${cart.length - 3} more items...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection(AsyncValue<List<Customer>> customersAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        customersAsync.when(
          data: (customers) {
            final selectedCustomer = ref.watch(selectedCustomerProvider);
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Customer>(
                  isExpanded: true,
                  value: selectedCustomer,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Select Customer (Optional for Cash)'),
                  ),
                  items: [
                    const DropdownMenuItem<Customer>(
                      value: null,
                      child: Text('No Customer (Walk-in)'),
                    ),
                    ...customers.map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(c.name),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    ref.read(selectedCustomerProvider.notifier).state = value;
                  },
                ),
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error loading customers',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(customerListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: _buildPaymentMethodRadio(
                    value: 'Cash',
                    icon: Icons.attach_money,
                    title: 'Cash',
                    subtitle: 'Pay with cash',
                  ),
                ),
                Expanded(
                  child: _buildPaymentMethodRadio(
                    value: 'Credit',
                    icon: Icons.credit_card,
                    title: 'Credit',
                    subtitle: 'Customer credit (+18%)',
                  ),
                ),
              ],
            ),
          ),
        ),
        if (paymentMethod == 'Credit') ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Customer selection is required for credit sales',
                    style: TextStyle(color: Colors.orange[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentMethodRadio({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 0,
      color: paymentMethod == value
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : Colors.transparent,
      child: RadioListTile<String>(
        dense: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        value: value,
        groupValue: paymentMethod,
        onChanged: (value) {
          setState(() {
            paymentMethod = value!;
            // Reset due days when switching payment method
            if (paymentMethod == 'Cash') {
              _selectedDueDays = null;
            }
          });
        },
      ),
    );
  }

  Widget _buildCreditDueDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Credit Due Days',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedDueDays,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Select due days'),
              ),
              items: _dueDaysOptions
                  .map(
                    (days) => DropdownMenuItem(
                      value: days,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('$days days'),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDueDays = value;
                });
              },
            ),
          ),
        ),
        if (_selectedDueDays == null && paymentMethod == 'Credit') ...[
          const SizedBox(height: 8),
          Text(
            'Please select due days for credit sale',
            style: TextStyle(color: Colors.red[600], fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildTotalsSection(
    double subtotal,
    double vat,
    double creditInterest,
    double total,
    bool isCredit,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildTotalRow('Subtotal:', subtotal),
            if (isCredit)
              _buildTotalRow('Credit Interest (18%):', creditInterest),
            _buildTotalRow('VAT:', vat),
            const Divider(),
            _buildTotalRow('Total Amount:', total, isBold: true),
            if (isCredit && _selectedDueDays != null) ...[
              const SizedBox(height: 8),
              Text(
                'Due in $_selectedDueDays days',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Theme.of(context).primaryColor : null,
            ),
          ),
          Text(
            'TSh ${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: isBold ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteSaleButton(Map<int, CartItem> cart, double total) {
    final selectedCustomer = ref.watch(selectedCustomerProvider);
    final isCredit = paymentMethod == 'Credit';

    // Validate form
    bool isValid = cart.isNotEmpty;
    if (isCredit) {
      if (selectedCustomer == null) {
        isValid = false;
      }
      if (_selectedDueDays == null) {
        isValid = false;
      }
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: (isValid && !_isProcessing)
            ? () => _showConfirmDialog(total)
            : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Theme.of(context).primaryColor,
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
            : Text(
                'Complete Sale - TSh ${total.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
      ),
    );
  }

  void _showConfirmDialog(double total) {
    final selectedCustomer = ref.watch(selectedCustomerProvider);
    final isCredit = paymentMethod == 'Credit';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Sale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to complete this sale?'),
            const SizedBox(height: 16),
            _buildTotalRow('Total Amount:', total, isBold: true),
            const SizedBox(height: 8),
            _buildTextRow('Payment Method:', paymentMethod),
            if (selectedCustomer != null)
              _buildTextRow('Customer:', selectedCustomer.name),
            if (isCredit && _selectedDueDays != null)
              _buildTextRow('Due Days:', '$_selectedDueDays days'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
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

  Widget _buildTextRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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

  Future<void> _completeSale(WidgetRef ref, double total) async {
    setState(() => _isProcessing = true);

    try {
      final cart = ref.read(cartProvider);
      if (cart.isEmpty) throw Exception("Cart is empty");

      final customer = ref.read(selectedCustomerProvider);
      final isCredit = paymentMethod == 'Credit';

      // ✅ Validate credit requirements
      if (isCredit) {
        if (customer == null)
          throw Exception("Customer is required for credit sales");
        if (_selectedDueDays == null)
          throw Exception("Select due days for credit sale");
      }

      // 🔹 Prepare items for API
      final items = cart.entries.map((e) {
        return {
          "product_id": e.value.product.id,
          "quantity": e.value.quantity,
          "price": e.value.product.price,
        };
      }).toList();

      // 🔹 Create sale (no payment recorded here)
      final sale = await ref
          .read(salesProvider.notifier)
          .createSale(
            customerId: customer?.id,
            isCredit: isCredit,
            total: total,
            items: items,
            dueDays: isCredit ? int.parse(_selectedDueDays!) : null,
          );

      print("🟢 Sale created: $sale");

      // 🔹 Clear cart and show success
      ref.read(cartProvider.notifier).clearCart();
      _showSuccessDialog(sale, isCredit);
    } catch (err, stack) {
      print("❌ ERROR DURING SALE:");
      print(err);
      print(stack);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sale failed: ${err.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> sale, bool isCredit) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Sale Completed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sale ID: ${sale['id'] ?? 'N/A'}'),
            const SizedBox(height: 4),
            Text('Total: TSh ${sale['total']?.toStringAsFixed(0) ?? '0'}'),
            const SizedBox(height: 8),
            Text(
              'Payment Method: $paymentMethod',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (isCredit) ...[
              const SizedBox(height: 4),
              Text(
                'Status: Credit Sale (Due in $_selectedDueDays days)',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Recorded as outstanding payment',
                style: TextStyle(color: Colors.blue[700], fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Print Receipt'),
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back to POS screen
            },
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back to POS screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
