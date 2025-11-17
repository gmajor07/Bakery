import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// PRINT: generate a PDF from the returned sale map (robust regardless of model)
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
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '🧾 SALES RECEIPT',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
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
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Table.fromTextArray(
              headers: ['Product', 'Qty', 'Unit Price', 'Subtotal'],
              data: items.map((it) {
                final name = it['name'] ?? it['product_name'] ?? '';
                final qty = (it['quantity'] ?? it['qty'] ?? 0).toString();
                final price = ((it['price'] ?? it['unit_price'] ?? 0) as num)
                    .toDouble()
                    .toStringAsFixed(2);
                final sub =
                    (((it['price'] ?? it['unit_price'] ?? 0) as num)
                                .toDouble() *
                            ((it['quantity'] ?? it['qty'] ?? 0) as num)
                                .toDouble())
                        .toStringAsFixed(2);
                return [name.toString(), qty, price, sub];
              }).toList(),
            ),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Subtotal:", style: pw.TextStyle(fontSize: 14)),
                pw.Text(
                  "TSh ${subtotal.toStringAsFixed(2)}",
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
                    "TSh ${vat.toStringAsFixed(2)}",
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
                  "TSh ${grandTotal.toStringAsFixed(2)}",
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
