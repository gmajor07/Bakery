import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Generates and prints a PDF receipt from a sale map
Future<void> printSaleReceipt(
    Map<String, dynamic> sale,
    double vatRate,
    ) async {
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

  // Determine if VAT was applied and the payment method for display
  final isCredit = sale['isCredit'] == true;
  final paymentMethod = isCredit
      ? "Credit"
      : sale['vat'] as num > 0
      ? "Cash (VAT Applied)"
      : "Cash (No VAT)";

  // Build items list, tolerant of various shapes
  final List items = sale['items'] is List ? sale['items'] as List : [];

  // Recalculate or use provided totals
  final subtotal = (sale['subtotal'] is num)
      ? (sale['subtotal'] as num).toDouble()
      : items.fold<double>(0, (s, it) {
    final price = (it['price'] ?? it['unit_price'] ?? 0);
    final qty = (it['quantity'] ?? it['qty'] ?? 0);
    return s + ((price as num).toDouble() * (qty as num).toDouble());
  });

  final vatAmount = (sale['vat'] is num)
      ? (sale['vat'] as num).toDouble()
      : 0.0; // Assume VAT is correctly stored in sale map

  final grandTotal = (sale['total'] is num)
      ? (sale['total'] as num).toDouble()
      : subtotal + vatAmount;

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
              'Payment Type: $paymentMethod',
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
                    ((it['quantity'] ?? it['qty'] ?? 0) as num).toDouble());
                return [
                  name.toString(),
                  qty,
                  formatPdfCurrency(price),
                  formatPdfCurrency(sub),
                ];
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
            if (vatAmount > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                      "VAT (${(vatRate * 100).toInt()}%):",
                      style: pw.TextStyle(fontSize: 14)),
                  pw.Text(
                    formatPdfCurrency(vatAmount),
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
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                'Thank You!',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
              ),
            )
          ],
        );
      },
    ),
  );

  await Printing.sharePdf(bytes: await pdf.save(), filename: 'sale_receipt.pdf');
}