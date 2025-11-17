import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/sales_provider.dart';
import '../../provider/sales_pagination_provider.dart';

/// Sales History Filters: Quick Date + Manual Range
class SalesHistoryFilters extends ConsumerWidget {
  const SalesHistoryFilters({super.key});

  void _refreshProvider(WidgetRef ref) {
    ref.read(salesPaginationProvider.notifier).reset();
    ref.invalidate(salesHistoryProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDateRange = ref.watch(selectedDateRangeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Date Selection Buttons
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                final now = DateTime.now();
                final startOfDay = DateTime(now.year, now.month, now.day);
                ref.read(selectedDateRangeProvider.notifier).state =
                    DateTimeRange(start: startOfDay, end: now);
                _refreshProvider(ref);
              },
              child: const Text('Today'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final now = DateTime.now();
                final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
                ref.read(selectedDateRangeProvider.notifier).state =
                    DateTimeRange(start: startOfWeekDay, end: now);
                _refreshProvider(ref);
              },
              child: const Text('This Week'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final now = DateTime.now();
                final startOfMonth = DateTime(now.year, now.month, 1);
                ref.read(selectedDateRangeProvider.notifier).state =
                    DateTimeRange(start: startOfMonth, end: now);
                _refreshProvider(ref);
              },
              child: const Text('This Month'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Manual Date Range Picker
        OutlinedButton.icon(
          icon: const Icon(Icons.date_range),
          label: Text(
            selectedDateRange != null
                ? '${selectedDateRange.start.month}/${selectedDateRange.start.day}/${selectedDateRange.start.year} - '
                '${selectedDateRange.end.month}/${selectedDateRange.end.day}/${selectedDateRange.end.year}'
                : 'Select Date Range',
            overflow: TextOverflow.ellipsis,
          ),
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              initialDateRange: selectedDateRange,
            );

            if (picked != null) {
              ref.read(selectedDateRangeProvider.notifier).state = picked;
              _refreshProvider(ref);
            }
          },
        ),
      ],
    );
  }
}