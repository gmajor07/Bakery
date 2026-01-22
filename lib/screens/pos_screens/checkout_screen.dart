import 'package:bak/screens/pos_screens/pos_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../provider/pos_provider.dart';
import '../../provider/customer_provider.dart';
import '../../provider/sales_provider.dart';
import '../../provider/sell_provider.dart';
import '../../provider/settings_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/print_receipt.dart';
import 'package:printing/printing.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  // ⬅️ UPDATED: Changed default payment to Cash (VAT)
  String paymentMethod = 'Cash (VAT)';
  bool _isProcessing = false;
  String? _selectedDueDays;
  final List<String> _dueDaysOptions = ['7', '14', '21', '30'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cartNotifier = ref.read(cartProvider.notifier);
    final cart = ref.watch(cartProvider);
    final customersAsync = ref.watch(customerListProvider);
    final settingsAsync = ref.watch(settingsProvider);

    final subtotal = cartNotifier.totalPrice;

    final vatRate = settingsAsync.maybeWhen(
      data: (settings) {
        if (kDebugMode) print("Settings data: $settings");
        final config = settings['data']?['configuration'];
        final vatValue = config?['vat'];
        if (kDebugMode) print("VAT value from settings: $vatValue");
        if (vatValue is num) {
          final val = vatValue.toDouble();
          // If val > 1, assume it's percentage * 10, divide by 100; else use as is
          return val > 1 ? val / 100 : val;
        }
        return 0.18;
      },
      orElse: () => 0.18,
    );
    if (kDebugMode) print("Final VAT rate: $vatRate");

    // ⬅️ UPDATED LOGIC FOR VAT
    final isCredit = paymentMethod == 'Credit';
    final isVatApplied = isCredit || paymentMethod == 'Cash (VAT)';

    // VAT is calculated on the subtotal only if it's Credit or Cash (VAT)
    final vatAmount = isVatApplied ? subtotal * vatRate : 0.0;

    final total = subtotal + vatAmount; // Total includes VAT if applied

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Sale'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(cart, subtotal, colorScheme),
            const SizedBox(height: 24),
            _buildPaymentMethodSection(colorScheme),
            const SizedBox(height: 24),
            // Customer selection depends on payment method
            if (isCredit) ...[
              _buildCreditDueDaysSection(colorScheme),
              const SizedBox(height: 24),
              _buildCustomerSection(customersAsync, colorScheme),
              const SizedBox(height: 24),
            ] else ...[
              // Put customer section after payment if it's Cash/Walk-in
              _buildCustomerSection(customersAsync, colorScheme),
              const SizedBox(height: 24),
            ],

            _buildTotalsSection(
              subtotal,
              vatAmount, // ⬅️ UPDATED
              total,
              isCredit,
              colorScheme,
              vatRate,
            ),
            const SizedBox(height: 32),
            _buildCompleteSaleButton(cart, total, colorScheme, vatRate),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(
    Map<int, CartItem> cart,
    double subtotal,
    ColorScheme colorScheme,
  ) {
    // ... (No changes here)
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Chip(
                  label: Text(
                    '${cart.length} ${cart.length == 1 ? 'item' : 'items'}',
                  ),
                  backgroundColor: colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
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
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          '${item.quantity} × ${formatCurrency(item.product.price)}',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
            if (cart.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${cart.length - 3} more items...',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection(
    AsyncValue<List<Customer>> customersAsync,
    ColorScheme colorScheme,
  ) {
    // ... (No changes here)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        customersAsync.when(
          data: (customers) {
            final selectedCustomer = ref.watch(selectedCustomerProvider);
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Customer?>(
                  isExpanded: true,
                  value: selectedCustomer,
                  hint: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Select Customer (Optional for Cash)',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<Customer?>(
                      value: null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Walk-in Customer (Default)',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    ...customers.map(
                      (c) => DropdownMenuItem<Customer?>(
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
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.error),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error loading customers',
                    style: TextStyle(color: colorScheme.error),
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

  Widget _buildPaymentMethodSection(ColorScheme colorScheme) {
    final selectedCustomer = ref.watch(selectedCustomerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          // ⬅️ UPDATED: Added a third payment method option
          children: [
            Expanded(
              child: _buildPaymentMethodCard(
                value: 'Cash (VAT)',
                icon: Icons.money,
                title: 'Cash',
                subtitle: 'Payment',
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentMethodCard(
                value: 'Credit',
                icon: Icons.credit_card_outlined,
                title: 'Credit',
                subtitle: 'Later Payment',
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
        if (paymentMethod == 'Credit' && selectedCustomer == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    color: colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You must select a customer for credit sales.',
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
  }) {
    final isSelected = paymentMethod == value;
    return InkWell(
      onTap: () {
        setState(() {
          paymentMethod = value;
          // Only clear due days if switching AWAY from Credit
          if (paymentMethod != 'Credit') _selectedDueDays = null;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: isSelected ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        color: isSelected
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 30,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditDueDaysSection(ColorScheme colorScheme) {
    // ... (No changes here)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Credit Due Days',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedDueDays == null
                  ? colorScheme.error
                  : colorScheme.outline,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedDueDays,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select due days',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
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
              onChanged: (val) => setState(() => _selectedDueDays = val),
            ),
          ),
        ),
        if (_selectedDueDays == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'A due date is required for credit sale.',
              style: TextStyle(color: colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildTotalsSection(
    double subtotal,
    double vatAmount, // ⬅️ UPDATED
    double total,
    bool isCredit,
    ColorScheme colorScheme,
    double vatRate,
  ) {
    // ⬅️ UPDATED: Check for Cash (VAT) as well
    final isVatApplied = isCredit || paymentMethod == 'Cash (VAT)';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const Divider(),
            _buildTotalRow('Subtotal:', subtotal, colorScheme),
            if (isVatApplied) // ⬅️ UPDATED: Show VAT if credit OR Cash (VAT)
              _buildTotalRow(
                'VAT (${(vatRate * 100).toInt()}%):',
                vatAmount, // ⬅️ Use vatAmount
                colorScheme,
              ),
            const Divider(height: 20, thickness: 2),
            _buildTotalRow('Total Amount:', total, colorScheme, isBold: true),
            if (isCredit && _selectedDueDays != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Due on: ${DateFormat('EEE, MMM d').format(DateTime.now().add(Duration(days: int.parse(_selectedDueDays!))))}',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double value,
    ColorScheme colorScheme, {
    bool isBold = false,
  }) {
    // ... (No changes here)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 16,
              color: isBold ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          Text(
            formatCurrency(value),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              fontSize: isBold ? 18 : 16,
              color: isBold ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteSaleButton(
    Map<int, CartItem> cart,
    double total,
    ColorScheme colorScheme,
    double vatRate,
  ) {
    final selectedCustomer = ref.watch(selectedCustomerProvider);
    final isCredit = paymentMethod == 'Credit';

    bool isValid = cart.isNotEmpty;
    if (isCredit) {
      if (selectedCustomer == null) isValid = false;
      if (_selectedDueDays == null) isValid = false;
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.payment_rounded),
        label: Text(
          'Complete Sale - ${formatCurrency(total)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onPressed: (isValid && !_isProcessing)
            ? () => _showConfirmDialog(total, colorScheme, vatRate)
            : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showConfirmDialog(
    double total,
    ColorScheme colorScheme,
    double vatRate,
  ) {
    final selectedCustomer = ref.read(selectedCustomerProvider);
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
            _buildTotalRow('Total Amount:', total, colorScheme, isBold: true),
            const SizedBox(height: 8),
            _buildTextRow('Payment Method:', paymentMethod),
            _buildTextRow(
              'Customer:',
              selectedCustomer?.name ?? 'Walk-in Customer',
            ),
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
              _completeSale(ref, total, vatRate);
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Confirm Sale'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextRow(String label, String value, {bool isBold = false}) {
    // ... (No changes here)
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

  Future<void> _completeSale(
    WidgetRef ref,
    double total,
    double vatRate,
  ) async {
    setState(() => _isProcessing = true);

    try {
      final cart = ref.read(cartProvider);
      if (cart.isEmpty) throw Exception("Cart is empty");

      final customer = ref.read(selectedCustomerProvider);
      final isCredit = paymentMethod == 'Credit';
      // ⬅️ NEW: Determine if VAT should be applied (Credit or Cash (VAT))
      final isVatApplied = isCredit || paymentMethod == 'Cash (VAT)';

      if (isCredit) {
        if (customer == null) {
          throw Exception("Customer is required for credit sales");
        }
        if (_selectedDueDays == null) {
          throw Exception("Select due days for credit sale");
        }
      }

      // 1. Calculate items list and subtotal
      double subtotal = 0.0;
      final items = cart.entries.map((e) {
        final itemPrice = e.value.product.price;
        final itemQuantity = e.value.quantity;

        // Accumulate subtotal
        subtotal += (itemPrice * itemQuantity);

        return {
          "product_id": e.value.product.id,
          "quantity": itemQuantity,
          "price": itemPrice,
        };
      }).toList();

      // 2. Calculate VAT amount
      // ⬅️ UPDATED: Calculate VAT based on isVatApplied
      final vatAmount = isVatApplied ? subtotal * vatRate : 0.0;

      final sale = await ref
          .read(salesProvider.notifier)
          .createSale(
            customerId: customer?.id,
            isCredit: isCredit,
            subtotal: subtotal,
            vatAmount: vatAmount,
            total: total,
            items: items,
            dueDays: isCredit ? int.parse(_selectedDueDays!) : null,
            // You may want to send the exact paymentMethod string to the backend as well
            paymentMethod: paymentMethod,
          );

      if (kDebugMode) print("🟢 Sale created: $sale");

      ref.read(cartProvider.notifier).clearCart();
      if (context.mounted) {
        _showSuccessDialog(sale, isCredit, vatRate);
      }
    } catch (err, stack) {
      if (kDebugMode) {
        print("❌ ERROR DURING SALE:");
        print(err);
        print(stack);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sale failed: ${err.toString().split(':').last.trim()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(
    Map<String, dynamic> sale,
    bool isCredit,
    double vatRate,
  ) {
    final selectedCustomer = ref.read(selectedCustomerProvider);
    final total = (sale['total'] is num)
        ? (sale['total'] as num).toDouble()
        : 0.0;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Sale Completed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total: ${formatCurrency(total)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildTextRow('Payment Method:', paymentMethod),
            _buildTextRow(
              'Customer:',
              selectedCustomer?.name ?? 'Walk-in Customer',
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.print, color: colorScheme.onSurface),
            label: Text(
              'Print Receipt',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            onPressed: () async {
              Navigator.pop(context);
              // ⬅️ UPDATED: Call the new, separated utility function
              try {
                if (kDebugMode) {
                  print("Starting print receipt for sale: ${sale['id']}");
                }
                final bakeryInfo = await ref.read(bakeryInfoProvider.future);
                final bytes = await generateSaleReceiptPdf(
                  sale,
                  bakeryInfo: bakeryInfo,
                );
                await Printing.layoutPdf(onLayout: (format) => bytes);
                if (kDebugMode) print("Print receipt completed successfully");

                // Navigate to POS after receipt is closed
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => PosScreen()),
                    (route) => false,
                  );
                }
              } catch (e, stack) {
                if (kDebugMode) {
                  print("Error printing receipt: $e");
                  print(stack);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to print receipt: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          FilledButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text('Done'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PosScreen()),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
