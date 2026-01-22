import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> generateSaleReceiptPdf(
  dynamic sale, {
  Map<String, dynamic>? bakeryInfo,
}) async {
  final pdf = pw.Document();

  // Thermal receipt width (80mm)
  const pageWidth = 226.77; // 80mm in points

  final font = pw.Font.ttf(
    await rootBundle.load('assets/fonts/RobotoMono-Regular.ttf'),
  );

  pw.TextStyle text(double size, {bool bold = false}) {
    return pw.TextStyle(
      font: font,
      fontSize: size,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
  }

  final bakeryName = bakeryInfo?['bakeryName'] ?? 'APOTEk Bakery';
  final address =
      bakeryInfo?['address'] ?? 'P.O Box 33967, Dar es salaam, Tanzania';
  final phone = bakeryInfo?['phone'] ?? '+255788 332 031';
  final email = bakeryInfo?['email'] ?? 'info@apotekbakery.com';

  // Handle both SaleItem object and Map formats
  final id = sale is Map ? (sale['id'] ?? 215) : (sale.id ?? 215);
  final customer = sale is Map
      ? (sale['customer'] ?? 'Cash')
      : (sale.customer ?? 'Cash');
  final dateStr = sale is Map
      ? (sale['date'] ?? DateTime.now().toIso8601String())
      : (sale.date ?? DateTime.now().toIso8601String());
  final date = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.parse(dateStr));

  final items = sale is Map
      ? ((sale['items'] as List?) ?? [])
      : (sale.items ?? []);
  final subtotal = sale is Map
      ? ((sale['subtotal'] as num?)?.toDouble() ?? 0.0)
      : (sale.subtotal ?? 0.0);
  final vat = sale is Map
      ? ((sale['vat'] as num?)?.toDouble() ?? 0.0)
      : (sale.vat ?? 0.0);
  final total = sale is Map
      ? ((sale['total'] as num?)?.toDouble() ?? 0.0)
      : (sale.amount ?? 0.0);

  // Get payment method
  final paymentMethod = sale is Map
      ? (sale['paymentMethod'] ?? 'Cash')
      : (sale.paymentMethod ?? 'Cash');

  // Get due date if credit (default to 30 days from sale date)
  final dueDate = sale is Map
      ? (sale['dueDate'] ?? '')
      : (sale.date.isNotEmpty
            ? DateFormat(
                'dd-MM-yyyy',
              ).format(DateTime.parse(dateStr).add(Duration(days: 30)))
            : '');

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(pageWidth, double.infinity),
      margin: const pw.EdgeInsets.all(8),
      build: (_) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(child: pw.Text(bakeryName, style: text(11, bold: true))),
            pw.Center(child: pw.Text(address, style: text(8))),
            pw.Center(child: pw.Text('Tel: $phone', style: text(8))),
            pw.Center(child: pw.Text(email, style: text(8))),
            pw.Divider(),

            pw.Text('Receipt #: $id', style: text(8)),
            pw.Text('Customer: $customer', style: text(8)),
            pw.Text('Date: $date', style: text(8)),
            pw.Divider(),

            pw.Text(
              'Item              Qty     Price',
              style: text(8, bold: true),
            ),

            ...items.map((it) {
              try {
                final name = it is Map
                    ? ((it['name'] ?? 'Unknown')
                          .toString()
                          .padRight(18)
                          .substring(0, 18))
                    : (it.name.padRight(18).substring(0, 18));
                final qty = it is Map
                    ? ((it['quantity'] ?? 0).toString().padLeft(3))
                    : (it.quantity.toString().padLeft(3));
                final price = it is Map
                    ? NumberFormat('#,##0').format(it['price'] ?? 0).padLeft(7)
                    : NumberFormat('#,##0').format(it.price).padLeft(7);

                return pw.Text('$name $qty $price', style: text(8));
              } catch (e) {
                return pw.Text('Error parsing item', style: text(8));
              }
            }).toList(),

            pw.SizedBox(height: 4),
            // Dotted line separator
            pw.Text(
              '............................................',
              style: text(8),
            ),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Subtotal', style: text(8)),
                pw.Text(NumberFormat('#,##0').format(subtotal), style: text(8)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('VAT', style: text(8)),
                pw.Text(NumberFormat('#,##0').format(vat), style: text(8)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total', style: text(9, bold: true)),
                pw.Text(
                  NumberFormat('#,##0').format(total),
                  style: text(9, bold: true),
                ),
              ],
            ),

            pw.Divider(),

            // Payment method with conditional credit/cash display
            paymentMethod == 'Credit'
                ? pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Payment: Credit', style: text(8)),
                      pw.Text('Due Date: $dueDate', style: text(8)),
                    ],
                  )
                : pw.Text('Payment: Cash', style: text(8)),
            pw.SizedBox(height: 8),

            pw.Center(
              child: pw.Text('Thank you for shopping with us!', style: text(8)),
            ),
            pw.Center(child: pw.Text('Enjoy!', style: text(8))),
            pw.SizedBox(height: 6),
            pw.Center(child: pw.Text('Issued By: Admin Acid', style: text(7))),
          ],
        );
      },
    ),
  );

  return pdf.save();
}
