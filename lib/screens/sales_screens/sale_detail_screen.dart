import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import '../../models/sale_item.dart';
import '../../provider/sales_provider.dart';
import '../../widgets/token_error_widget.dart';
import '../pos_screens/generate_pdf.dart'; // Assuming this function exists

class SaleDetailScreen extends ConsumerWidget {
  final int saleId;
  const SaleDetailScreen({super.key, required this.saleId});

  // 1. 🚨 NEW: Helper to format number with commas (NO TSh)
  String _formatNumber(double amount) {
    final absoluteAmount = amount.abs();
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(absoluteAmount);
  }

  // 2. 💡 MODIFIED: Helper to format currency (FOR EXTERNAL USE/PDF)
  String _formatCurrency(double amount) {
    final absoluteAmount = amount.abs();
    final formatter = NumberFormat('#,##0', 'en_US');
    return 'TSh ${formatter.format(absoluteAmount)}';
  }

  // Helper to format date
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy - HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _printReceipt(SaleItem sale, BuildContext context) async {
    final bytes = await generateSaleReceiptPdf(sale);
    if (bytes != null) {
      await Printing.layoutPdf(onLayout: (format) => bytes);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Receipt sent to printer.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate receipt.')),
      );
    }
  }

  void _shareReceipt(SaleItem sale, BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating receipt for sharing...')),
    );

    final bytes = await generateSaleReceiptPdf(sale);

    if (bytes != null) {
      // Use XFile.fromData to create XFile from bytes for sharing
      final file = XFile.fromData(
        bytes,
        name: 'receipt_${sale.receiptNumber}.pdf',
        mimeType: 'application/pdf', // Specify MIME type
      );

      await Share.shareXFiles(
        [file],
        text:
            'Please find the receipt for Sale #${sale.receiptNumber} attached.',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to generate receipt for sharing.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(saleDetailProvider(saleId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt #$saleId'),
        actions: [
          if (saleAsync.hasValue)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => _printReceipt(saleAsync.value!, context),
              tooltip: 'Print Receipt',
            ),
          if (saleAsync.hasValue)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareReceipt(saleAsync.value!, context),
              tooltip: 'Share Receipt',
            ),
        ],
      ),
      body: saleAsync.when(
        loading: () => _buildLoadingState(context),
        error: (err, _) => _buildErrorState(err, ref, context),
        data: (sale) => _buildSaleDetails(context, sale),
      ),
    );
  }

  // --- Widget Builders (Loading/Error States) ---

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading sale details...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, WidgetRef ref, BuildContext context) {
    final errorMsg = error.toString().toLowerCase();

    if (errorMsg.contains('token') ||
        errorMsg.contains('unauthorized') ||
        errorMsg.contains('401')) {
      return const TokenErrorWidget();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load sale details',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(saleDetailProvider(saleId)),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleDetails(BuildContext context, SaleItem sale) {
    final formattedDate = _formatDate(sale.date);
    // 🚨 FIX: Use _formatNumber (without TSh) for display
    final formattedAmount = _formatNumber(sale.amount);
    final totalItems = sale.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    // 🚨 FIX: Determine the background color based on theme brightness
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Use a very dark grey/black for contrast in dark mode
    final cardBgColor = isDarkMode
        ? Colors.grey[900]!
        : Theme.of(context).cardColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 2,
            // 🚨 FIX: Set explicit dark background color for dark theme contrast
            color: cardBgColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Receipt #${sale.receiptNumber}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // 🚨 FIX: Pass context to _buildStatusChip
                      _buildStatusChip(sale.status, context),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  // 🚨 FIX: Pass context to _buildInfoGrid
                  _buildInfoGrid(
                    sale,
                    formattedDate,
                    formattedAmount,
                    totalItems,
                    cardBgColor,
                    context,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Items List Header
          Text(
            'Items Sold ($totalItems items)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // 🚨 FIX: Use the list builder for mobile-friendly view
          _buildItemsList(sale.items, cardBgColor, context),

          const SizedBox(height: 20),

          // Payment Summary
          _buildPaymentSummary(sale, context, cardBgColor),
        ],
      ),
    );
  }

  // 🚨 FIX: Added BuildContext context argument
  Widget _buildStatusChip(String status, BuildContext context) {
    Color chipColor;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        chipColor = Colors.brown;
        break;
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'cancelled':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: chipColor,
    );
  }

  // 🚨 FIX: Added BuildContext context argument
  Widget _buildInfoGrid(
    SaleItem sale,
    String formattedDate,
    String formattedAmount,
    int totalItems,
    Color cardBgColor,
    BuildContext context, // 🚨 FIX: Added context here
  ) {
    // Determine the color for the inner info items
    final innerItemBgColor = cardBgColor.computeLuminance() > 0.5
        ? Colors.grey[50]
        : Colors.grey[800];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.8,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        // 🚨 FIX: Pass context to _buildInfoItem
        _buildInfoItem(
          'Date',
          formattedDate,
          Icons.calendar_today,
          innerItemBgColor,
          context,
        ),
        _buildInfoItem(
          'Customer',
          sale.customer,
          Icons.person,
          innerItemBgColor,
          context,
        ),
        _buildInfoItem(
          'Total Amount',
          formattedAmount,
          Icons.card_giftcard,
          innerItemBgColor,
          context,
        ),
        _buildInfoItem(
          'Total Items',
          totalItems.toString(),
          Icons.shopping_cart,
          innerItemBgColor,
          context,
        ),
      ],
    );
  }

  // 🚨 FIX: Added BuildContext context argument
  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon,
    Color? bgColor,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use onSurface for text color for theme consistency
    final textColor = theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        // 🚨 FIX: Use the passed background color
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: isDark ? Border.all(color: Colors.grey[800]!) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      // 🚨 FIX: Use onSurface color
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🚨 MODIFIED: _buildItemsList to use a mobile-friendly list-tile/card view (not table)
  Widget _buildItemsList(
    List<SaleProduct> items,
    Color cardBgColor,
    BuildContext context,
  ) {
    return Card(
      elevation: 2,
      // 🚨 FIX: Set explicit dark background color for dark theme contrast
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          // 🚨 FIX: Pass context to _buildItemTile
          children: items.map((item) => _buildItemTile(item, context)).toList(),
        ),
      ),
    );
  }

  // 🚨 FIX: Added BuildContext context argument
  Widget _buildItemTile(SaleProduct item, BuildContext context) {
    final itemTotal = item.price * item.quantity;
    // 🚨 FIX: Use _formatNumber (without TSh)
    final formattedPrice = _formatNumber(item.price.toDouble());
    final formattedTotal = _formatNumber(itemTotal.toDouble());
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Product Name and Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: theme.textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                // 🚨 FIX: Show TSh on the final total price only if needed, or stick to number format.
                // Keeping TSh for the total amount in this mobile view for clarity:
                'TSh $formattedTotal',
                style: theme.textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Row 2: Qty and Price per unit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Qty: ${item.quantity}',
                style: theme.textTheme.bodySmall!.copyWith(color: Colors.grey),
              ),
              Text(
                '$formattedPrice / unit', // Added TSh back for context on unit price
                style: theme.textTheme.bodySmall!.copyWith(color: Colors.grey),
              ),
            ],
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  // 🚨 MODIFIED: Payment Summary (using _formatNumber)
  Widget _buildPaymentSummary(
    SaleItem sale,
    BuildContext context,
    Color cardBgColor,
  ) {
    final subtotal = sale.items.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    final bool isCreditSale = sale.paymentMethod.toLowerCase() == 'credit';

    double tax = 0.0;
    if (isCreditSale) {
      tax = (sale.amount - subtotal).clamp(0.0, double.infinity);
    }

    if (tax < 0.01) {
      tax = 0.0;
    }

    final total = sale.amount;

    return Card(
      elevation: 2,
      // 🚨 FIX: Set explicit dark background color for dark theme contrast
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // 🚨 FIX: Pass context to _buildSummaryRow
            _buildSummaryRow('Subtotal', subtotal, context: context),
            if (isCreditSale && tax > 0)
              // 🚨 FIX: Pass context to _buildSummaryRow
              _buildSummaryRow('VAT (18%)', tax, context: context),
            const Divider(),
            // 🚨 FIX: Pass context to _buildSummaryRow
            _buildSummaryRow(
              'Total Amount',
              total,
              isTotal: true,
              context: context,
            ),
          ],
        ),
      ),
    );
  }

  // 🚨 FIX: Added BuildContext context argument
  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isTotal = false,
    required BuildContext context,
  }) {
    // 🚨 FIX: Use _formatNumber (without TSh)
    final formattedAmount = _formatNumber(amount);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            // 🚨 FIX: Add TSh back *only* here for the final display amount
            'TSh $formattedAmount',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
