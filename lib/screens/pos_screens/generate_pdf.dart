import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;

import '../../models/sale_item.dart';

Future<Uint8List> generateSaleReceiptPdf(SaleItem sale) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Receipt #${sale.receiptNumber}',
            style: pw.TextStyle(fontSize: 18),
          ),
          pw.Text('Customer: ${sale.customer}'),
          pw.Text('Date: ${sale.date}'),
          pw.Text('Status: ${sale.status}'),
          pw.Text('Payment: ${sale.paymentStatus}'),
          pw.SizedBox(height: 12),
          pw.Text('Items Sold:', style: pw.TextStyle(fontSize: 16)),
          pw.TableHelper.fromTextArray(
            headers: ['Product', 'Qty', 'Unit Price', 'Subtotal'],
            data: sale.items
                .map(
                  (item) => [
                    item.name,
                    item.quantity.toString(),
                    item.price.toStringAsFixed(2),
                    (item.price * item.quantity).toStringAsFixed(2),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Total: TSh ${sale.amount.toStringAsFixed(2)}'),
        ],
      ),
    ),
  );

  return pdf.save();
}
