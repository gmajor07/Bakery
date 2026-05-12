import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  static const List<String> _reportTypes = [
    'Sales Details Report',
    'Sales Summary Report',
    'Cash Sales Details Report',
    'Cash Sales Summary Report',
    'Credit Sales Details Report',
    'Credit Sales Summary Report',
    'Credit Payments Report',
    'Price List Report',
    'Sales Returns Report',
  ];

  final DateFormat _dayMonthFormat = DateFormat('MMM dd');
  final DateFormat _fullDateFormat = DateFormat('MMM dd, yyyy');
  String _selectedReportType = 'Cash Sales Details Report';
  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime(2026, 1, 1),
    end: DateTime(2026, 2, 28),
  );

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

  void _generatePdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $_selectedReportType PDF...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
          'Sales Reports',
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
                    if (value == null) return;
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
                        Expanded(flex: 7, child: reportTypeField),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: dateRangeField),
                      ],
                    )
                  else ...[
                    reportTypeField,
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
                        onPressed: _generatePdf,
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
