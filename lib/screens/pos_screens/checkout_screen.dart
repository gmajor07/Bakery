import 'package:bak/screens/pos_screens/pos_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Used here for date formatting in print
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/customer.dart';
import '../../provider/pos_provider.dart';
import '../../provider/customer_provider.dart';
import '../../provider/sales_provider.dart';
import '../../provider/sell_provider.dart';
// ⬅️ NEW: Import the currency formatter utility
import '../../utils/formatters.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final cartNotifier = ref.read(cartProvider.notifier);
    final cart = ref.watch(cartProvider);
    final customersAsync = ref.watch(customerListProvider);

    final subtotal = cartNotifier.totalPrice;

    final isCredit = paymentMethod == 'Credit';
    // VAT is calculated on the subtotal (18% in this example)
    final vatCredit = isCredit ? subtotal * 0.18 : 0.0;
    final total = subtotal + vatCredit;

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
            if (paymentMethod == 'Credit') ...[
              _buildCreditDueDaysSection(colorScheme),
              const SizedBox(height: 24),
              _buildCustomerSection(customersAsync, colorScheme),
              const SizedBox(height: 24),
            ] else ...[
              // Put customer section after payment if it's Cash/Walk-in
              _buildCustomerSection(customersAsync, colorScheme),
              const SizedBox(height: 24),
            ],

            _buildTotalsSection(subtotal, vatCredit, total, isCredit, colorScheme),
            const SizedBox(height: 32),
            _buildCompleteSaleButton(cart, total, colorScheme),
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
            ...cart.values.take(3).map(
                  (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    Text(
                      '${item.quantity} × ${formatCurrency(item.product.price)}', // ⬅️ FORMATTED
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
                    color: colorScheme.onSurfaceVariant.withValues(),
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
          children: [
            Expanded(
              child: _buildPaymentMethodCard(
                value: 'Cash',
                icon: Icons.money,
                title: 'Cash',
                subtitle: 'Immediate payment',
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
                  Icon(Icons.person_off_outlined, color: colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You must select a customer for credit sales.',
                      style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 13, fontWeight: FontWeight.w500),
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
          if (paymentMethod == 'Cash') _selectedDueDays = null;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: isSelected ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        color: isSelected ? colorScheme.primaryContainer.withOpacity(0.3) : colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
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
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditDueDaysSection(ColorScheme colorScheme) {
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
              color: _selectedDueDays == null ? colorScheme.error : colorScheme.outline,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedDueDays,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Select due days', style: TextStyle(color: colorScheme.onSurfaceVariant)),
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
      double vatCredit,
      double total,
      bool isCredit,
      ColorScheme colorScheme,
      ) {
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
            if (isCredit)
              _buildTotalRow('VAT (18%):', vatCredit, colorScheme),
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
            formatCurrency(value), // ⬅️ FORMATTED
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
          'Complete Sale - ${formatCurrency(total)}', // ⬅️ FORMATTED
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onPressed: (isValid && !_isProcessing)
            ? () => _showConfirmDialog(total, colorScheme)
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

  void _showConfirmDialog(double total, ColorScheme colorScheme) {
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
              _completeSale(ref, total);
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
      const vatRate = 0.18;
      final vatAmount = isCredit ? subtotal * vatRate : 0.0;


      final sale = await ref
          .read(salesProvider.notifier)
          .createSale(
        customerId: customer?.id,
        isCredit: isCredit,
        subtotal: subtotal,    // ⬅️ NEW: Pass calculated subtotal
        vatAmount: vatAmount,  // ⬅️ NEW: Pass calculated VAT amount
        total: total,          // Pass the already calculated Grand Total
        items: items,
        dueDays: isCredit ? int.parse(_selectedDueDays!) : null,
      );

      if (kDebugMode) print("🟢 Sale created: $sale");

      ref.read(cartProvider.notifier).clearCart();
      if (context.mounted) {
        _showSuccessDialog(sale, isCredit);
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
            content: Text('Sale failed: ${err.toString().split(':').last.trim()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }
  void _showSuccessDialog(Map<String, dynamic> sale, bool isCredit) {
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
              'Total: ${formatCurrency(total)}', // ⬅️ FORMATTED
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
            label: Text('Print Receipt', style: TextStyle(color: colorScheme.onSurface)),
            onPressed: () {
              Navigator.pop(context);
              _printSaleMap(sale);
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
              );            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // PRINT: generate a PDF from the returned sale map
  Future<void> _printSaleMap(Map<String, dynamic> sale) async {
    final pdf = pw.Document();
    final dateRaw = sale['date'] ?? DateTime.now().toIso8601String();
    DateTime date;
    try {
      date = DateTime.parse(dateRaw.toString());
    } catch (_) {
      date = DateTime.now();
    }
    final dateFormatted = DateFormat('yyyy-MM-dd HH:mm').format(date);
    final customerName =
    (sale['customer'] == null || (sale['customer'] as String).isEmpty)
        ? 'Walk-in Customer'
        : sale['customer'].toString();

    // Build items list, tolerant of various shapes
    final List items = sale['items'] is List ? sale['items'] as List : [];
    final subtotal = (sale['subtotal'] is num)
        ? (sale['subtotal'] as num).toDouble()
        : items.fold<double>(0, (s, it) {
      final price = (it['price'] ?? it['unit_price'] ?? 0);
      final qty = (it['quantity'] ?? it['qty'] ?? 0);
      return s + ((price as num).toDouble() * (qty as num).toDouble());
    });

    final vat = (sale['vat'] is num)
        ? (sale['vat'] as num).toDouble()
        : ((sale['isCredit'] == true) ? subtotal * 0.18 : 0.0);
    final grandTotal = (sale['total'] is num)
        ? (sale['total'] as num).toDouble()
        : subtotal + vat;

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          // Inner function to format currency for PDF
          String formatPdfCurrency(double amount) {
            return 'TSh ${NumberFormat('#,##0.00').format(amount)}';
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '🧾 SALES RECEIPT',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Receipt #: ${sale['id'] ?? ''}'),
              pw.Text('Customer: $customerName'),
              pw.Text('Date: $dateFormatted'),
              pw.Text(
                'Payment Type: ${sale['isCredit'] == true ? "Credit" : "Cash"}',
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Items',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['Product', 'Qty', 'Unit Price', 'Subtotal'],
                data: items.map((it) {
                  final name = it['name'] ?? it['product_name'] ?? '';
                  final qty = (it['quantity'] ?? it['qty'] ?? 0).toString();
                  final price = ((it['price'] ?? it['unit_price'] ?? 0) as num)
                      .toDouble();
                  final sub = (((it['price'] ?? it['unit_price'] ?? 0) as num)
                      .toDouble() *
                      ((it['quantity'] ?? it['qty'] ?? 0) as num)
                          .toDouble());
                  return [name.toString(), qty, formatPdfCurrency(price), formatPdfCurrency(sub)];
                }).toList(),
              ),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Subtotal:", style: pw.TextStyle(fontSize: 14)),
                  pw.Text(
                    formatPdfCurrency(subtotal),
                    style: pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
              if (vat > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("VAT (18%):", style: pw.TextStyle(fontSize: 14)),
                    pw.Text(
                      formatPdfCurrency(vat),
                      style: pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "TOTAL:",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    formatPdfCurrency(grandTotal),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Text(
                  'Thank you for your purchase!',
                  style: pw.TextStyle(fontSize: 14),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
}