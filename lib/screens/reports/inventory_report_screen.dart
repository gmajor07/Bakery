import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../auth/auth_provider.dart';
import '../../models/adjustment.dart' as adjustment_model;
import '../../models/inventory_item.dart' as inventory_model;
import '../../models/product.dart';
import '../../models/product_adjustment.dart' as product_adjustment;
import '../../models/supplier_model.dart';
import '../../provider/adjustment_provider.dart';
import '../../provider/inventory_provider.dart';
import '../../provider/products_provider.dart';
import '../../provider/settings_provider.dart';
import '../../provider/suppliers_provider.dart';
import '../../widgets/report_pdf.dart';

class InventoryReportScreen extends ConsumerStatefulWidget {
  const InventoryReportScreen({super.key});

  @override
  ConsumerState<InventoryReportScreen> createState() =>
      _InventoryReportScreenState();
}

class _InventoryReportScreenState extends ConsumerState<InventoryReportScreen> {
  static const List<String> _reportTypes = [
    'Materials Current Stock',
    'Supplies Current Stock',
    'Product Current Stock',
    'Materials Below Min Level',
    'Supplies Below Min Level',
    'Materials Adjustments',
    'Supplies Adjustments',
    'Materials Out of Stock',
    'Supplies Out of Stock',
    'Product Details',
    'Product Adjustments',
    'Suppliers List',
  ];

  String? _selectedReportType;
  final DateFormat _dayMonthFormat = DateFormat('MMM dd');
  final DateFormat _fullDateFormat = DateFormat('MMM dd, yyyy');
  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  static const Set<String> _reportsWithDate = {
    'Materials Adjustments',
    'Supplies Adjustments',
    'Product Adjustments',
    'Suppliers List',
  };

  bool get _shouldShowDate =>
      _selectedReportType != null &&
      _reportsWithDate.contains(_selectedReportType);

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedRange,
    );

    if (picked != null) {
      setState(() => _selectedRange = picked);
    }
  }

  Future<void> _generatePdf() async {
    final reportType = _selectedReportType ?? 'inventory report';
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text('Generating $reportType PDF...'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final bakeryInfo = await ref.read(bakeryInfoProvider.future);
      final bytes = await _buildInventoryReportPdf(bakeryInfo);

      if (!mounted) return;
      await Printing.layoutPdf(onLayout: (_) => bytes);
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not generate report: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<Uint8List> _buildInventoryReportPdf(
    Map<String, dynamic> bakeryInfo,
  ) async {
    final reportType = _selectedReportType!;

    if (reportType == 'Product Current Stock' ||
        reportType == 'Product Details') {
      final products = await ref.read(productsProvider.future);
      return _productsPdf(reportType, bakeryInfo, products);
    }

    if (reportType == 'Suppliers List') {
      final token = await ref.read(authProvider.notifier).getAccessToken();
      if (token == null) throw Exception('Token is null');
      final suppliers = await ref.read(suppliersProvider(token).future);
      return generateTableReportPdf<Supplier>(
        reportTitle: reportType,
        bakeryInfo: bakeryInfo,
        rows: suppliers,
        columns: [
          ReportColumn(title: '#', value: (_, index) => '${index + 1}'),
          ReportColumn(
            title: 'Supplier Name',
            flex: 3,
            value: (item, _) => item.name,
          ),
          ReportColumn(
            title: 'Phone',
            flex: 2,
            value: (item, _) => item.contactInfo,
          ),
          ReportColumn(title: 'Email', flex: 3, value: (item, _) => item.email),
          ReportColumn(
            title: 'Status',
            flex: 2,
            value: (item, _) => item.status,
          ),
        ],
      );
    }

    if (reportType == 'Product Adjustments') {
      final rows = await ref
          .read(adjustmentsApiServiceProvider)
          .fetchProductAdjustments(
            startDate: _selectedRange.start.toIso8601String(),
            endDate: _selectedRange.end.toIso8601String(),
          );
      return generateTableReportPdf<product_adjustment.ProductAdjustment>(
        reportTitle: reportType,
        bakeryInfo: bakeryInfo,
        rows: rows,
        columns: [
          ReportColumn(title: '#', value: (_, index) => '${index + 1}'),
          ReportColumn(
            title: 'Product',
            flex: 3,
            value: (item, _) => item.product?.name ?? 'Unknown',
          ),
          ReportColumn(
            title: 'Date',
            flex: 2,
            value: (item, _) => _date(item.createdAt),
          ),
          ReportColumn(
            title: 'Amount',
            alignment: pw.Alignment.centerRight,
            value: (item, _) => '${item.amount}',
          ),
          ReportColumn(
            title: 'Reason',
            flex: 3,
            value: (item, _) => item.reason,
          ),
        ],
      );
    }

    if (reportType == 'Materials Adjustments' ||
        reportType == 'Supplies Adjustments') {
      final type = reportType.startsWith('Supplies')
          ? 'supplies'
          : 'raw_material';
      final rows = await ref
          .read(adjustmentsApiServiceProvider)
          .fetchAdjustments(
            startDate: _selectedRange.start.toIso8601String(),
            endDate: _selectedRange.end.toIso8601String(),
            type: type,
            limit: 10000,
          );
      return generateTableReportPdf<adjustment_model.Adjustment>(
        reportTitle: reportType,
        bakeryInfo: bakeryInfo,
        rows: rows,
        columns: [
          ReportColumn(title: '#', value: (_, index) => '${index + 1}'),
          ReportColumn(
            title: 'Item',
            flex: 3,
            value: (item, _) => item.inventoryItem.name,
          ),
          ReportColumn(
            title: 'Date',
            flex: 2,
            value: (item, _) =>
                _date(DateTime.tryParse(item.createdAt) ?? DateTime.now()),
          ),
          ReportColumn(
            title: 'Amount',
            alignment: pw.Alignment.centerRight,
            value: (item, _) => _number(item.amount),
          ),
          ReportColumn(
            title: 'Reason',
            flex: 3,
            value: (item, _) => item.reason,
          ),
        ],
      );
    }

    final type = reportType.startsWith('Supplies')
        ? 'supplies'
        : 'raw_material';
    var rows = await ref.read(inventoryProvider(type).future);
    if (reportType.contains('Below Min Level')) {
      rows = rows
          .where((item) => item.currentQuantity <= item.minLevel)
          .toList();
    } else if (reportType.contains('Out of Stock')) {
      rows = rows.where((item) => item.currentQuantity <= 0).toList();
    }

    return generateTableReportPdf<inventory_model.InventoryItem>(
      reportTitle: reportType,
      bakeryInfo: bakeryInfo,
      rows: rows,
      columns: [
        ReportColumn(title: '#', value: (_, index) => '${index + 1}'),
        ReportColumn(
          title: 'Item Name',
          flex: 3,
          value: (item, _) => item.name,
        ),
        ReportColumn(title: 'Unit', value: (item, _) => item.unit),
        ReportColumn(
          title: 'Current',
          flex: 2,
          alignment: pw.Alignment.centerRight,
          value: (item, _) => _number(item.currentQuantity),
        ),
        ReportColumn(
          title: 'Min Level',
          flex: 2,
          alignment: pw.Alignment.centerRight,
          value: (item, _) => _number(item.minLevel),
        ),
        ReportColumn(
          title: 'Cost',
          flex: 2,
          alignment: pw.Alignment.centerRight,
          value: (item, _) => _money(item.cost),
        ),
      ],
    );
  }

  Future<Uint8List> _productsPdf(
    String reportType,
    Map<String, dynamic> bakeryInfo,
    List<Product> products,
  ) {
    return generateTableReportPdf<Product>(
      reportTitle: reportType,
      bakeryInfo: bakeryInfo,
      rows: products,
      columns: [
        ReportColumn(title: '#', value: (_, index) => '${index + 1}'),
        ReportColumn(
          title: 'Product Name',
          flex: 3,
          value: (item, _) => item.name,
        ),
        ReportColumn(
          title: 'Qty',
          alignment: pw.Alignment.centerRight,
          value: (item, _) => '${item.quantity}',
        ),
        ReportColumn(
          title: 'Sell Price',
          flex: 2,
          alignment: pw.Alignment.centerRight,
          value: (item, _) => _money(item.price),
        ),
        ReportColumn(title: 'Status', flex: 2, value: (item, _) => item.status),
      ],
    );
  }

  String _date(DateTime date) => DateFormat('dd-MM-yyyy').format(date);

  String _money(num value) => NumberFormat('#,##0').format(value);

  String _number(num value) => NumberFormat('#,##0.##').format(value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final panelColor = isDark ? colorScheme.surface : Colors.white;
    final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.8);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Inventory Reports',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: panelColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;
              final reportTypeField = _ReportField(
                label: 'Report Type',
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedReportType,
                  isExpanded: true,
                  hint: const Text('Select inventory report type'),
                  icon: const Icon(LucideIcons.chevronDown),
                  decoration: _fieldDecoration(context),
                  items: _reportTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedReportType = value);
                  },
                ),
              );
              final dateRangeField = _ReportField(
                label: 'Date Range',
                child: InkWell(
                  onTap: _selectDateRange,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: _fieldDecoration(context),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 18),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _rangeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: reportTypeField),
                        if (_shouldShowDate) ...[
                          const SizedBox(width: 16),
                          Expanded(child: dateRangeField),
                        ],
                      ],
                    )
                  else ...[
                    reportTypeField,
                    if (_shouldShowDate) ...[
                      const SizedBox(height: 16),
                      dateRangeField,
                    ],
                  ],
                  const SizedBox(height: 28),
                  Align(
                    alignment: isWide
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: _selectedReportType == null
                            ? null
                            : _generatePdf,
                        icon: const Icon(LucideIcons.download, size: 18),
                        label: const Text('Generate PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String get _rangeLabel {
    final start = _dayMonthFormat.format(_selectedRange.start);
    final end = _fullDateFormat.format(_selectedRange.end);
    return '$start - $end';
  }

  InputDecoration _fieldDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      filled: true,
      fillColor: colorScheme.surface.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }
}

class _ReportField extends StatelessWidget {
  final String label;
  final Widget child;

  const _ReportField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
