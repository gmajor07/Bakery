import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/product.dart';

class ReportColumn<T> {
  final String title;
  final String Function(T item, int index) value;
  final int flex;
  final pw.Alignment alignment;

  const ReportColumn({
    required this.title,
    required this.value,
    this.flex = 1,
    this.alignment = pw.Alignment.centerLeft,
  });
}

String pdfReportTitle(String reportType) {
  return reportType;
}

Future<Uint8List> generatePriceListReportPdf({
  required List<Product> products,
  required Map<String, dynamic> bakeryInfo,
  required String reportTitle,
  DateTime? printedAt,
}) {
  final sortedProducts = [...products]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  return generateTableReportPdf<Product>(
    reportTitle: reportTitle,
    bakeryInfo: bakeryInfo,
    printedAt: printedAt,
    rows: sortedProducts,
    columns: [
      ReportColumn<Product>(
        title: '#',
        flex: 1,
        value: (_, index) => '${index + 1}',
      ),
      ReportColumn<Product>(
        title: 'Product Name',
        flex: 6,
        value: (product, _) => product.name,
      ),
      ReportColumn<Product>(
        title: 'Sell Price',
        flex: 2,
        alignment: pw.Alignment.centerRight,
        value: (product, _) => NumberFormat('#,##0').format(product.price),
      ),
    ],
  );
}

Future<Uint8List> generateTableReportPdf<T>({
  required String reportTitle,
  required Map<String, dynamic> bakeryInfo,
  required List<T> rows,
  required List<ReportColumn<T>> columns,
  String? dateRangeLabel,
  DateTime? printedAt,
}) async {
  final pdf = pw.Document();
  final printedDate = DateFormat(
    'dd-MM-yyyy: HH:mm:ss',
  ).format(printedAt ?? DateTime.now());

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 26, 36, 30),
      header: (_) => _ReportHeader(
        bakeryInfo: bakeryInfo,
        reportTitle: reportTitle,
        dateRangeLabel: dateRangeLabel,
        printedDate: printedDate,
      ),
      build: (_) => [
        pw.SizedBox(height: 10),
        _ReportTable<T>(rows: rows, columns: columns),
      ],
    ),
  );

  return pdf.save();
}

class _ReportHeader extends pw.StatelessWidget {
  final Map<String, dynamic> bakeryInfo;
  final String reportTitle;
  final String? dateRangeLabel;
  final String printedDate;

  _ReportHeader({
    required this.bakeryInfo,
    required this.reportTitle,
    required this.dateRangeLabel,
    required this.printedDate,
  });

  @override
  pw.Widget build(pw.Context context) {
    final bakeryName =
        bakeryInfo['bakeryName']?.toString().trim().isNotEmpty == true
        ? bakeryInfo['bakeryName'].toString()
        : 'APOTEk Bakery';
    final address = bakeryInfo['address']?.toString().trim().isNotEmpty == true
        ? bakeryInfo['address'].toString()
        : 'P.O Box 33967, Dar es salaam, Tanzania';
    final phone = bakeryInfo['phone']?.toString().trim().isNotEmpty == true
        ? bakeryInfo['phone'].toString()
        : '+255788 332 031';
    final email = bakeryInfo['email']?.toString().trim().isNotEmpty == true
        ? bakeryInfo['email'].toString()
        : 'info@apotekbakery.com';

    return pw.Container(
      width: double.infinity,
      alignment: pw.Alignment.center,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.RichText(
            textAlign: pw.TextAlign.center,
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: 'APOT',
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#2F6FB3'),
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.TextSpan(
                  text: 'Ek',
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#F36F21'),
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.Text(
            bakeryName,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            address,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Phone: $phone',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Email: $email',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            reportTitle,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          if (dateRangeLabel != null)
            pw.Text(
              dateRangeLabel!,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9),
            ),
          pw.Text(
            'Printed On: $printedDate',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _ReportTable<T> extends pw.StatelessWidget {
  final List<T> rows;
  final List<ReportColumn<T>> columns;

  _ReportTable({required this.rows, required this.columns});

  @override
  pw.Widget build(pw.Context context) {
    final headerColor = PdfColor.fromHex('#1F2937');
    final rowColor = PdfColor.fromHex('#F7F7F7');

    return pw.Table(
      columnWidths: {
        for (var i = 0; i < columns.length; i++)
          i: pw.FlexColumnWidth(columns[i].flex.toDouble()),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: columns.map((column) {
            return pw.Container(
              alignment: column.alignment,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              child: pw.Text(
                column.title,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),
        if (rows.isEmpty)
          pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                child: pw.Text(
                  'No data found',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              for (var i = 1; i < columns.length; i++) pw.SizedBox(),
            ],
          )
        else
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: index.isEven ? rowColor : PdfColors.white,
              ),
              children: columns.map((column) {
                return pw.Container(
                  alignment: column.alignment,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 11,
                  ),
                  child: pw.Text(
                    column.value(item, index),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                );
              }).toList(),
            );
          }),
      ],
    );
  }
}
