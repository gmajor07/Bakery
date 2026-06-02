import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/production_items.dart';
import '../../provider/production_provider.dart';
import '../../provider/settings_provider.dart';
import '../../widgets/report_pdf.dart';

class ProductionReportScreen extends ConsumerStatefulWidget {
  const ProductionReportScreen({super.key});

  @override
  ConsumerState<ProductionReportScreen> createState() =>
      _ProductionReportScreenState();
}

class _ProductionReportScreenState
    extends ConsumerState<ProductionReportScreen> {
  static const List<String> _reportTypes = [
    'Production Detailed Report',
    'Production Summary Report',
    'Ingredients Usage Detailed Report',
    'Ingredients Summary Report',
  ];

  final DateFormat _dayMonthFormat = DateFormat('MMM dd');
  final DateFormat _fullDateFormat = DateFormat('MMM dd, yyyy');
  String? _selectedReportType;
  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  String _selectedQuickFilter = 'Custom';

  void _applyQuickFilter(String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime start = today;
    DateTime end = now;

    switch (filter) {
      case 'Today':
        start = today;
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Yesterday':
        start = today.subtract(const Duration(days: 1));
        end = DateTime(start.year, start.month, start.day, 23, 59, 59);
        break;
      case 'This Week':
        start = today.subtract(Duration(days: today.weekday - 1));
        end = now;
        break;
      case 'Last Week':
        final lastMonday = today.subtract(Duration(days: today.weekday + 6));
        start = lastMonday;
        end = lastMonday.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        end = now;
        break;
      case 'Last Month':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      default:
        return;
    }

    setState(() {
      _selectedQuickFilter = filter;
      _selectedRange = DateTimeRange(start: start, end: end);
    });
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedRange,
    );

    if (picked != null) {
      setState(() {
        _selectedRange = picked;
        _selectedQuickFilter = 'Custom';
      });
    }
  }

  Future<void> _generatePdf() async {
    final reportType = _selectedReportType ?? 'production report';
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text('Generating $reportType PDF...'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final bakeryInfo = await ref.read(bakeryInfoProvider.future);
      final bytes = await _buildProductionReportPdf(bakeryInfo);

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

  Future<Uint8List> _buildProductionReportPdf(
    Map<String, dynamic> bakeryInfo,
  ) async {
    final productions = (await ref.read(
      productionProvider.future,
    )).where((item) => _dateInRange(item.date)).toList();
    final reportType = _selectedReportType!;

    if (reportType == 'Production Summary Report') {
      final rows = _summarizeProduction(productions);
      return generateTableReportPdf<_ProductionSummaryRow>(
        reportTitle: pdfReportTitle(reportType),
        bakeryInfo: bakeryInfo,
        rows: rows,
        columns: [
          ReportColumn(title: '#', value: (_, index) => '${index + 1}'),
          ReportColumn(
            title: 'Product',
            flex: 3,
            value: (item, _) => item.product,
          ),
          ReportColumn(
            title: 'Qty',
            alignment: pw.Alignment.centerRight,
            value: (item, _) => '${item.quantity}',
          ),
          ReportColumn(
            title: 'Cost',
            flex: 2,
            alignment: pw.Alignment.centerRight,
            value: (item, _) => _money(item.cost),
          ),
          ReportColumn(
            title: 'Revenue',
            flex: 2,
            alignment: pw.Alignment.centerRight,
            value: (item, _) => _money(item.revenue),
          ),
        ],
      );
    }

    if (reportType == 'Ingredients Usage Detailed Report' ||
        reportType == 'Ingredients Summary Report') {
      final detailRows = productions
          .expand(
            (production) => production.ingredientsDeducted.map(
              (ingredient) => _IngredientUsageRow(production, ingredient),
            ),
          )
          .toList();

      if (reportType == 'Ingredients Summary Report') {
        return generateTableReportPdf<_IngredientSummaryRow>(
          reportTitle: pdfReportTitle(reportType),
          bakeryInfo: bakeryInfo,
          rows: _summarizeIngredients(detailRows),
          columns: [
            ReportColumn(title: '#', value: (_, index) => '${index + 1}'),
            ReportColumn(
              title: 'Ingredient',
              flex: 3,
              value: (item, _) => item.name,
            ),
            ReportColumn(title: 'Unit', value: (item, _) => item.unit),
            ReportColumn(
              title: 'Amount',
              flex: 2,
              alignment: pw.Alignment.centerRight,
              value: (item, _) => _number(item.amount),
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

      return generateTableReportPdf<_IngredientUsageRow>(
        reportTitle: pdfReportTitle(reportType),
        bakeryInfo: bakeryInfo,
        rows: detailRows,
        columns: [
          ReportColumn(title: '#', value: (_, index) => '${index + 1}'),
          ReportColumn(
            title: 'Product',
            flex: 3,
            value: (item, _) => item.production.product,
          ),
          ReportColumn(
            title: 'Ingredient',
            flex: 3,
            value: (item, _) => item.ingredient.name,
          ),
          ReportColumn(
            title: 'Amount',
            flex: 2,
            alignment: pw.Alignment.centerRight,
            value: (item, _) =>
                '${_number(item.ingredient.amountDeducted)} ${item.ingredient.unit}',
          ),
          ReportColumn(
            title: 'Cost',
            flex: 2,
            alignment: pw.Alignment.centerRight,
            value: (item, _) => _money(item.ingredient.cost),
          ),
        ],
      );
    }

    return generateTableReportPdf<ProductionItem>(
      reportTitle: pdfReportTitle(reportType),
      bakeryInfo: bakeryInfo,
      rows: productions,
      columns: [
        ReportColumn(title: '#', value: (_, index) => '${index + 1}'),
        ReportColumn(
          title: 'Product',
          flex: 3,
          value: (item, _) => item.product,
        ),
        ReportColumn(
          title: 'Date',
          flex: 2,
          value: (item, _) => _date(item.date),
        ),
        ReportColumn(
          title: 'Qty',
          alignment: pw.Alignment.centerRight,
          value: (item, _) => '${item.quantity}',
        ),
        ReportColumn(
          title: 'Cost',
          flex: 2,
          alignment: pw.Alignment.centerRight,
          value: (item, _) => _money(item.cost),
        ),
        ReportColumn(
          title: 'Revenue',
          flex: 2,
          alignment: pw.Alignment.centerRight,
          value: (item, _) => _money(item.revenue),
        ),
      ],
    );
  }

  bool _dateInRange(DateTime date) {
    final start = DateTime(
      _selectedRange.start.year,
      _selectedRange.start.month,
      _selectedRange.start.day,
    );
    final end = DateTime(
      _selectedRange.end.year,
      _selectedRange.end.month,
      _selectedRange.end.day,
      23,
      59,
      59,
    );
    return !date.isBefore(start) && !date.isAfter(end);
  }

  List<_ProductionSummaryRow> _summarizeProduction(
    List<ProductionItem> productions,
  ) {
    final grouped = <String, _ProductionSummaryRow>{};
    for (final item in productions) {
      final current =
          grouped[item.product] ?? _ProductionSummaryRow(item.product, 0, 0, 0);
      grouped[item.product] = _ProductionSummaryRow(
        item.product,
        current.quantity + item.quantity,
        current.cost + item.cost,
        current.revenue + item.revenue,
      );
    }
    return grouped.values.toList();
  }

  List<_IngredientSummaryRow> _summarizeIngredients(
    List<_IngredientUsageRow> rows,
  ) {
    final grouped = <String, _IngredientSummaryRow>{};
    for (final row in rows) {
      final key = '${row.ingredient.name}-${row.ingredient.unit}';
      final current =
          grouped[key] ??
          _IngredientSummaryRow(row.ingredient.name, row.ingredient.unit, 0, 0);
      grouped[key] = _IngredientSummaryRow(
        row.ingredient.name,
        row.ingredient.unit,
        current.amount + row.ingredient.amountDeducted,
        current.cost + row.ingredient.cost,
      );
    }
    return grouped.values.toList();
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
          'Production Reports',
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
                  hint: const Text('Select production report type'),
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

              final quickFilters = _ReportField(
                label: 'Quick Select',
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        [
                          'Today',
                          'Yesterday',
                          'This Week',
                          'Last Week',
                          'This Month',
                          'Last Month',
                        ].map((filter) {
                          final isSelected = _selectedQuickFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) _applyQuickFilter(filter);
                              },
                            ),
                          );
                        }).toList(),
                  ),
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
                        Expanded(flex: 6, child: reportTypeField),
                        const SizedBox(width: 16),
                        Expanded(flex: 4, child: dateRangeField),
                      ],
                    )
                  else ...[
                    reportTypeField,
                    const SizedBox(height: 16),
                    quickFilters,
                    const SizedBox(height: 16),
                    dateRangeField,
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

class _ProductionSummaryRow {
  final String product;
  final int quantity;
  final double cost;
  final double revenue;

  const _ProductionSummaryRow(
    this.product,
    this.quantity,
    this.cost,
    this.revenue,
  );
}

class _IngredientUsageRow {
  final ProductionItem production;
  final IngredientDeducted ingredient;

  const _IngredientUsageRow(this.production, this.ingredient);
}

class _IngredientSummaryRow {
  final String name;
  final String unit;
  final double amount;
  final double cost;

  const _IngredientSummaryRow(this.name, this.unit, this.amount, this.cost);
}
