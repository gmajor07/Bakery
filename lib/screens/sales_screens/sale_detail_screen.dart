import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart'; // 📦 NEW: Import share_plus
import 'package:printing/printing.dart'; // 📦 NEW: Import printing
import 'dart:io'; // Needed for File/XFile if sharing
import '../../models/sale_item.dart';
import '../../provider/sales_provider.dart';
import '../../widgets/token_error_widget.dart';
import '../pos_screens/generate_pdf.dart';

class SaleDetailScreen extends ConsumerWidget {
  final int saleId;
  const SaleDetailScreen({super.key, required this.saleId});

  // 💡 Helper to format currency with TSh and commas
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return 'TSh ${formatter.format(amount)}';
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

  // 1. 🔄 MODIFIED: Print function now calls generate and shows feedback
  void _printReceipt(SaleItem sale, BuildContext context) async {
    final bytes = await generateSaleReceiptPdf(sale);
    if (bytes != null) {
      // Trigger printing with the generated PDF bytes
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

  // 2. ✅ IMPLEMENTED: Share functionality
  void _shareReceipt(SaleItem sale, BuildContext context) async {
    // 💡 Add await here to resolve the Future and get the Uint8List bytes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating receipt for sharing...')),
    );

    // Call the same generation function to get the PDF bytes
    final bytes = await generateSaleReceiptPdf(sale);

    if (bytes != null) {
      // Use XFile.fromData to create XFile from bytes for sharing
      final file = XFile.fromData(
        bytes,
        name: 'receipt_${sale.receiptNumber}.pdf',
      );

      // Use the share_plus package to open the native share dialog
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
        title: Text('Sale #$saleId'),
        actions: [
          // Add print/export functionality
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

  // --- Widget Builders ---

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
    final formattedAmount = _formatCurrency(sale.amount);
    final totalItems = sale.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 2,
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
                      _buildStatusChip(sale.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildInfoGrid(
                    sale,
                    formattedDate,
                    formattedAmount,
                    totalItems,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Items List
          Text(
            'Items Sold ($totalItems items)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildItemsList(sale.items),

          const SizedBox(height: 20),

          // Payment Summary
          _buildPaymentSummary(sale, context),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
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

  Widget _buildInfoGrid(
    SaleItem sale,
    String formattedDate,
    String formattedAmount,
    int totalItems,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _buildInfoItem('Date', formattedDate, Icons.calendar_today),
        _buildInfoItem('Customer', sale.customer, Icons.person),
        _buildInfoItem('Total Amount', formattedAmount, Icons.attach_money),
        _buildInfoItem(
          'Total Items',
          totalItems.toString(),
          Icons.shopping_cart,
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

  Widget _buildItemsList(List<SaleProduct> items) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Table Header
            const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Product',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Qty',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  // 💡 Added explicit flex to Price column
                  flex: 2,
                  child: Text(
                    'Price',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  // 💡 Added explicit flex to Total column
                  flex: 2,
                  child: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const Divider(),
            // Items
            ...items.map((item) => _buildItemRow(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(SaleProduct item) {
    final itemTotal = item.price * item.quantity;

    // 💡 Apply comma formatting to item price and total
    final formattedPrice = _formatCurrency(item.price.toDouble());
    final formattedTotal = _formatCurrency(itemTotal.toDouble());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.name,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              item.quantity.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            // 💡 Use flex: 2 to give more horizontal space
            flex: 2,
            child: Text(
              formattedPrice,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            // 💡 Use flex: 2 to give more horizontal space
            flex: 2,
            child: Text(
              formattedTotal,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(SaleItem sale, BuildContext context) {
    final subtotal = sale.items.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    const tax = 0.0; // You can add tax calculation if available
    final total = sale.amount;

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
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Subtotal', subtotal),
            _buildSummaryRow('Tax', tax),
            const Divider(),
            _buildSummaryRow('Total Amount', total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    // 💡 Apply comma formatting here
    final formattedAmount = _formatCurrency(amount);

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
            ),
          ),
          Text(
            formattedAmount,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.brown : null,
            ),
          ),
        ],
      ),
    );
  }
}
