import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangePickerWidget extends StatefulWidget {
  final DateTimeRange? initialRange;
  final Function(DateTimeRange?) onRangeSelected;
  final String? label;

  const DateRangePickerWidget({
    super.key,
    this.initialRange,
    required this.onRangeSelected,
    this.label,
  });

  @override
  State<DateRangePickerWidget> createState() => _DateRangePickerWidgetState();
}

class _DateRangePickerWidgetState extends State<DateRangePickerWidget> {
  DateTimeRange? _selectedRange;

  final List<String> quickOptions = [
    'Today',
    'Yesterday',
    'This Week',
    'Last Week',
    'This Month',
    'Last Month',
    'Clear',
  ];

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.initialRange;
  }

  void _selectDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedRange,
    );

    if (picked != null) {
      setState(() => _selectedRange = picked);
      widget.onRangeSelected(picked);
    }
  }

  void _selectQuickRange(String rangeType) {
    final now = DateTime.now();
    DateTimeRange? range;

    switch (rangeType) {
      case 'Today':
        range = DateTimeRange(start: now, end: now);
        break;
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        range = DateTimeRange(start: yesterday, end: yesterday);
        break;
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        range = DateTimeRange(start: startOfWeek, end: now);
        break;
      case 'Last Week':
        final startOfLastWeek = now.subtract(Duration(days: now.weekday + 6));
        final endOfLastWeek = now.subtract(Duration(days: now.weekday));
        range = DateTimeRange(start: startOfLastWeek, end: endOfLastWeek);
        break;
      case 'This Month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        range = DateTimeRange(start: startOfMonth, end: now);
        break;
      case 'Last Month':
        final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 0);
        range = DateTimeRange(start: startOfLastMonth, end: endOfLastMonth);
        break;
      case 'Clear':
        range = null;
        break;
    }

    setState(() => _selectedRange = range);
    widget.onRangeSelected(range);
  }

  @override
  Widget build(BuildContext context) {
    final label = _selectedRange == null
        ? widget.label ?? 'Select date range'
        : '${DateFormat('MMM dd').format(_selectedRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedRange!.end)}';

    final selectedQuickOption = _selectedRange != null
        ? _getRangeType(_selectedRange!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.date_range),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () => _selectDateRange(context),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: quickOptions.contains(selectedQuickOption)
              ? selectedQuickOption
              : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          hint: const Text("Quick select"),
          items: quickOptions.map((rangeType) {
            return DropdownMenuItem<String>(
              value: rangeType,
              child: Text(rangeType),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) _selectQuickRange(value);
          },
        ),
      ],
    );
  }

  String _getRangeType(DateTimeRange range) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));
    final endOfLastWeek = startOfWeek.subtract(const Duration(days: 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = DateTime(now.year, now.month, 0);

    if (_isSameDay(range.start, range.end)) {
      if (_isSameDay(range.start, today)) return 'Today';
      if (_isSameDay(range.start, yesterday)) return 'Yesterday';
    }

    if (_isSameDay(range.start, startOfWeek) && _isSameDay(range.end, now)) {
      return 'This Week';
    }

    if (_isSameDay(range.start, startOfLastWeek) &&
        _isSameDay(range.end, endOfLastWeek)) {
      return 'Last Week';
    }

    if (_isSameDay(range.start, startOfMonth) && _isSameDay(range.end, now)) {
      return 'This Month';
    }

    if (_isSameDay(range.start, startOfLastMonth) &&
        _isSameDay(range.end, endOfLastMonth)) {
      return 'Last Month';
    }

    return 'Custom';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
