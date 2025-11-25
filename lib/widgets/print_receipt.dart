import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart'; // Import for PdfColors
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// Helper to format currency consistently
String _formatCurrency(double amount) {
  final formatter = NumberFormat('#,##0.00', 'en_US');
  return 'TSh ${formatter.format(amount)}';
}

// 🎯 RENAMED & MODIFIED: Function now saves the PDF and returns the file path.
Future<String?> generateSaleReceiptPdf(Map<String, dynamic> sale) async {
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

  // --- Calculation Logic (remains the same) ---
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

  // Define custom styles
  final headerStyle = pw.TextStyle(
    fontSize: 18,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.white,
  );
  final boldStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold);
  final totalStyle = pw.TextStyle(
    fontSize: 16,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.brown700,
  );

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // 1. STYLED HEADER BOX (Brown Accent)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.brown400,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('APOTEk Bakery Receipt', style: headerStyle),
                  pw.Text(
                    dateFormatted,
                    style: headerStyle.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // 2. TRANSACTION INFO
            pw.Text(
              'Transaction Details',
              style: boldStyle.copyWith(fontSize: 14),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Receipt #: ${sale['id'] ?? ''}'),
                    pw.Text('Customer: $customerName'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Payment: ${sale['isCredit'] == true ? "Credit" : "Cash"}',
                      style: boldStyle,
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // 3. ITEMS TABLE
            pw.Text('Items Purchased', style: boldStyle.copyWith(fontSize: 14)),
            pw.SizedBox(height: 8),

            pw.Table.fromTextArray(
              headers: ['Product', 'Qty', 'Unit Price', 'Subtotal'],
              cellAlignment: pw.Alignment.centerRight,
              headerStyle: boldStyle.copyWith(
                fontSize: 10,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.brown400,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                ),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(3), // Product Name
                1: const pw.FlexColumnWidth(1), // Qty
                2: const pw.FlexColumnWidth(1.5), // Unit Price
                3: const pw.FlexColumnWidth(1.5), // Subtotal
              },
              data: items.map((it) {
                final name = it['name'] ?? it['product_name'] ?? '';
                final qty = (it['quantity'] ?? it['qty'] ?? 0).toString();
                final price = ((it['price'] ?? it['unit_price'] ?? 0) as num)
                    .toDouble();
                final sub =
                    price *
                    ((it['quantity'] ?? it['qty'] ?? 0) as num).toDouble();

                return [
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(name.toString()),
                  ),
                  qty,
                  _formatCurrency(price),
                  _formatCurrency(sub),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),

            // 4. SUMMARY (Aligned to Right)
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _buildSummaryRow('Subtotal:', subtotal, boldStyle),
                  if (vat > 0) _buildSummaryRow('VAT (18%):', vat, boldStyle),
                  pw.Divider(height: 1),
                  pw.SizedBox(height: 5),
                  _buildSummaryRow('GRAND TOTAL:', grandTotal, totalStyle),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // 5. FOOTER
            pw.Center(
              child: pw.Text(
                'Thank you for your business! Please visit us again soon.',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'Powered by APOTEk System',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  // --- Save PDF to file (remains the same) ---
  try {
    final bytes = await pdf.save();
    final output = await getTemporaryDirectory();
    final fileName = 'receipt_${sale['id'] ?? 'temp'}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  } catch (e) {
    print('Error saving PDF: $e');
    return null;
  }
}

// Helper widget for building the summary rows
pw.Widget _buildSummaryRow(String label, double amount, pw.TextStyle style) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(width: 200), // Push label far left
        pw.Expanded(flex: 4, child: pw.Text(label, style: style)),
        pw.Expanded(
          flex: 5,
          child: pw.Text(
            _formatCurrency(amount),
            style: style,
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    ),
  );
}
