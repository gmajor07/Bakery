import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import '../../models/sale_item.dart';
import '../../provider/sales_provider.dart';
import '../../provider/settings_provider.dart';
import '../../widgets/print_receipt.dart';
import '../../widgets/token_error_widget.dart';

class SaleDetailScreen extends ConsumerWidget {
  final int saleId;
  const SaleDetailScreen({super.key, required this.saleId});

  // --- Formatting Helpers ---

  String _formatNumber(double amount) {
    final absoluteAmount = amount.abs();
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(absoluteAmount);
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy • HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // --- Actions ---

  void _printReceipt(SaleItem sale, BuildContext context, WidgetRef ref) async {
    try {
      final bakeryInfo = await ref.read(bakeryInfoProvider.future);
      final bytes = await generateSaleReceiptPdf(sale, bakeryInfo: bakeryInfo);
      await Printing.layoutPdf(onLayout: (format) => bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt sent to printer.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareReceipt(SaleItem sale, BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating receipt for sharing...')),
    );

    final bakeryInfo = await ref.read(bakeryInfoProvider.future);
    final bytes = await generateSaleReceiptPdf(sale, bakeryInfo: bakeryInfo);

    final file = XFile.fromData(
      bytes,
      name: 'receipt_${sale.receiptNumber}.pdf',
      mimeType: 'application/pdf',
    );

    await Share.shareXFiles(
      [file],
      text: 'Please find the receipt for Sale #${sale.receiptNumber} attached.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(saleDetailProvider(saleId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Sale Details',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          if (saleAsync.hasValue) ...[
            IconButton(
              icon: const Icon(Icons.print_outlined),
              onPressed: () => _printReceipt(saleAsync.value!, context, ref),
              tooltip: 'Print',
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _shareReceipt(saleAsync.value!, context, ref),
              tooltip: 'Share',
            ),
          ],
        ],
      ),
      body: saleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildErrorState(err, ref, context),
        data: (sale) => _buildSaleDetails(context, sale),
      ),
    );
  }

  // --- Main Content Builder ---

  Widget _buildSaleDetails(BuildContext context, SaleItem sale) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER RECEIPT CARD
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border(
                top: BorderSide(color: theme.colorScheme.primary, width: 8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RECEIPT NO',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            '#${sale.receiptNumber}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      _buildStatusChip(
                        sale.displayStatus,
                        sale.statusColor,
                        context,
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(thickness: 1),
                  ),
                  _buildDetailRow(
                    Icons.calendar_today_outlined,
                    'Date',
                    _formatDate(sale.date),
                    context,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.person_outline,
                    'Customer',
                    sale.customer,
                    context,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.payments_outlined,
                    'Method',
                    sale.paymentMethod,
                    context,
                  ),
                  if (sale.isCredit) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.calendar_month_outlined,
                      'Due Date',
                      _formatDate(
                        DateTime.parse(
                          sale.date,
                        ).add(const Duration(days: 30)).toIso8601String(),
                      ),
                      context,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 2. ITEMS LIST SECTION
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'ITEMS SOLD (${sale.items.fold<int>(0, (sum, item) => sum + item.quantity)} units)',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                letterSpacing: 1.2,
              ),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sale.items.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final item = sale.items[index];
                return _buildItemTile(item, context);
              },
            ),
          ),

          const SizedBox(height: 24),

          // 3. PAYMENT SUMMARY
          _buildPaymentSummary(sale, context, cardColor),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // --- Sub-Widgets ---

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemTile(SaleProduct item, BuildContext context) {
    final total = item.price * item.quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} units × TSh ${_formatNumber(item.price.toDouble())}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            'TSh ${_formatNumber(total.toDouble())}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(
    SaleItem sale,
    BuildContext context,
    Color cardBgColor,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final subtotal = sale.items.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final total = sale.amount;
    final tax = (total - subtotal).clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.primaryContainer.withOpacity(0.1)
            : theme.colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', subtotal, false, context),
          if (tax > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('VAT / Markup', tax, false, context),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(thickness: 1),
          ),
          _buildSummaryRow('Total Amount', total, true, context),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount,
    bool isTotal,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          'TSh ${_formatNumber(amount)}',
          style: TextStyle(
            fontSize: isTotal ? 22 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, WidgetRef ref, BuildContext context) {
    final errorMsg = error.toString().toLowerCase();
    if (errorMsg.contains('token') || errorMsg.contains('401')) {
      return const TokenErrorWidget();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(saleDetailProvider(saleId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
