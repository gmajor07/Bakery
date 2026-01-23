import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../provider/adjustment_provider.dart';
import '../../widgets/token_error_widget.dart';
import 'new_material_adjustment_screen.dart';

enum QuickDateFilter {
  all,
  today,
  yesterday,
  last7Days,
  thisMonth,
  lastMonth,
  custom,
}

class MaterialAdjustmentsScreen extends ConsumerStatefulWidget {
  final String type; // 'raw_material' or 'supplies'

  const MaterialAdjustmentsScreen({super.key, required this.type});

  @override
  ConsumerState<MaterialAdjustmentsScreen> createState() =>
      _MaterialAdjustmentsScreenState();
}

class _MaterialAdjustmentsScreenState
    extends ConsumerState<MaterialAdjustmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  QuickDateFilter selectedQuickFilter = QuickDateFilter.all;

  @override
  void initState() {
    super.initState();

    final filters = ref.read(adjustmentFiltersProvider);
    _searchController.text = filters.search ?? '';

    // Set the type after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(adjustmentFiltersProvider.notifier)
          .update((s) => s.copyWith(type: widget.type));
    });

    _updateQuickFilterState(filters.startDate, filters.endDate);

    if (filters.startDate == null && filters.endDate == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyQuickDateFilter(QuickDateFilter.today);
      });
    }
  }

  void _updateQuickFilterState(String? startDateStr, String? endDateStr) {
    if (startDateStr == null || endDateStr == null) {
      selectedQuickFilter = QuickDateFilter.all;
    } else {
      selectedQuickFilter = QuickDateFilter.custom;
    }
  }

  void _applyQuickDateFilter(
    QuickDateFilter filter, [
    DateTimeRange? customRange,
  ]) {
    final newRange = filter == QuickDateFilter.custom
        ? customRange
        : _getDateRange(filter);

    setState(() => selectedQuickFilter = filter);

    if (newRange == null) {
      ref
          .read(adjustmentFiltersProvider.notifier)
          .update((s) => s.copyWith(startDate: null, endDate: null, page: 1));
    } else {
      final start = DateTime(
        newRange.start.year,
        newRange.start.month,
        newRange.start.day,
      );
      final end = DateTime(
        newRange.end.year,
        newRange.end.month,
        newRange.end.day,
      ).add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

      ref
          .read(adjustmentFiltersProvider.notifier)
          .update(
            (s) => s.copyWith(
              startDate: start.toIso8601String(),
              endDate: end.toIso8601String(),
              page: 1,
            ),
          );
    }
  }

  DateTimeRange? _getDateRange(QuickDateFilter filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (filter) {
      case QuickDateFilter.all:
        return null;
      case QuickDateFilter.today:
        return DateTimeRange(start: today, end: today);
      case QuickDateFilter.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return DateTimeRange(start: yesterday, end: yesterday);
      case QuickDateFilter.last7Days:
        final lastWeek = today.subtract(const Duration(days: 6));
        return DateTimeRange(start: lastWeek, end: today);
      case QuickDateFilter.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: startOfMonth, end: today);
      case QuickDateFilter.lastMonth:
        final lastMonthEnd = DateTime(now.year, now.month, 0);
        final lastMonthStart = DateTime(
          lastMonthEnd.year,
          lastMonthEnd.month,
          1,
        );
        return DateTimeRange(start: lastMonthStart, end: lastMonthEnd);
      case QuickDateFilter.custom:
        return null;
    }
  }

  void _pickDateRange() async {
    final filters = ref.read(adjustmentFiltersProvider);
    DateTimeRange? initialRange;

    if (filters.startDate != null && filters.endDate != null) {
      initialRange = DateTimeRange(
        start: DateTime.parse(filters.startDate!),
        end: DateTime.parse(
          filters.endDate!,
        ).subtract(const Duration(seconds: 1)),
      );
    }

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: initialRange,
    );

    if (picked != null) {
      _applyQuickDateFilter(QuickDateFilter.custom, picked);
    }
  }

  void _clearAllFilters() {
    setState(() {
      selectedQuickFilter = QuickDateFilter.all;
      _searchController.clear();
    });
    ref
        .read(adjustmentFiltersProvider.notifier)
        .update(
          (s) =>
              s.copyWith(search: '', startDate: null, endDate: null, page: 1),
        );
  }

  String _getFilterName(QuickDateFilter filter) {
    switch (filter) {
      case QuickDateFilter.all:
        return 'All Time';
      case QuickDateFilter.today:
        return 'Today';
      case QuickDateFilter.yesterday:
        return 'Yesterday';
      case QuickDateFilter.last7Days:
        return 'Last 7 Days';
      case QuickDateFilter.thisMonth:
        return 'This Month';
      case QuickDateFilter.lastMonth:
        return 'Last Month';
      case QuickDateFilter.custom:
        return 'Custom Range';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(adjustmentFiltersProvider);
    final adjustmentsAsync = ref.watch(adjustmentsProvider);

    final hasFilters =
        filters.search?.isNotEmpty == true ||
        filters.startDate != null ||
        filters.endDate != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.type == 'raw_material' ? 'Materials' : 'Supplies'} Adjustments',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(adjustmentsProvider);
            },
            tooltip: 'Refresh',
          ),
          if (hasFilters)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearAllFilters,
              tooltip: 'Clear Filters',
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NewMaterialAdjustmentScreen(type: widget.type),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text(' Adjustment'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search by item name',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        ref
                            .read(adjustmentFiltersProvider.notifier)
                            .update((s) => s.copyWith(search: value, page: 1));
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildQuickDateFilters(filters),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: adjustmentsAsync.when(
              data: (adjustments) {
                if (adjustments.isEmpty) {
                  return _buildEmptyState(hasFilters);
                }
                // ⭐️ IMPLEMENTED: Pull-to-Refresh
                return RefreshIndicator(
                  onRefresh: () async {
                    return ref.refresh(adjustmentsProvider.future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    // Ensures list is draggable for refresh even if items are few
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: adjustments.length,
                    itemBuilder: (context, index) {
                      return MaterialAdjustmentTile(
                        adjustment: adjustments[index],
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) {
                final msg = error.toString().toLowerCase();
                if (msg.contains('401') ||
                    msg.contains('unauthorized') ||
                    msg.contains('token') ||
                    msg.contains('expired')) {
                  return const TokenErrorWidget();
                }
                return Center(child: Text('Error: ${error.toString()}'));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: filters.page > 1
                      ? () {
                          ref
                              .read(adjustmentFiltersProvider.notifier)
                              .update((s) => s.copyWith(page: s.page - 1));
                        }
                      : null,
                  child: const Text('Previous'),
                ),
                Text('Page ${filters.page}'),
                ElevatedButton(
                  onPressed:
                      adjustmentsAsync.maybeWhen(
                        data: (adjustments) => adjustments.isNotEmpty,
                        orElse: () => false,
                      )
                      ? () {
                          ref
                              .read(adjustmentFiltersProvider.notifier)
                              .update((s) => s.copyWith(page: s.page + 1));
                        }
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateFilters(dynamic filters) {
    const filterOptions = [
      QuickDateFilter.today,
      QuickDateFilter.yesterday,
      QuickDateFilter.last7Days,
      QuickDateFilter.thisMonth,
      QuickDateFilter.lastMonth,
      QuickDateFilter.custom,
    ];

    final primaryColor = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 50,
            height: 40,
            child: ElevatedButton(
              onPressed: _pickDateRange,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(width: 8),
          ...filterOptions.map((filter) {
            final isSelected = filter == selectedQuickFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(
                  filter == QuickDateFilter.custom && filters.startDate != null
                      ? '${DateFormat('MMM dd').format(DateTime.parse(filters.startDate!))} - ${DateFormat('MMM dd').format(DateTime.parse(filters.endDate!).subtract(const Duration(seconds: 1)))}'
                      : _getFilterName(filter),
                ),
                selected: isSelected,
                selectedColor: primaryColor.withOpacity(0.15),
                checkmarkColor: primaryColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? primaryColor
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (filter == QuickDateFilter.custom) {
                    if (!isSelected) _pickDateRange();
                  } else if (selected) {
                    _applyQuickDateFilter(filter);
                  } else if (filter == selectedQuickFilter) {
                    _applyQuickDateFilter(QuickDateFilter.all);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool hasFilters) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No material adjustments found',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Clear filters or try a different search term.'
                : 'No material/supplies adjustments recorded yet.',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (hasFilters)
            ElevatedButton.icon(
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear all filters'),
              onPressed: _clearAllFilters,
            ),
        ],
      ),
    );
  }
}

class MaterialAdjustmentTile extends StatelessWidget {
  final dynamic adjustment;

  const MaterialAdjustmentTile({super.key, required this.adjustment});

  @override
  Widget build(BuildContext context) {
    final amount = adjustment.amount as num;
    final isIncrease = amount > 0;

    final amountColor = isIncrease
        ? Colors.brown.shade700
        : Colors.red.shade700;
    final amountText = isIncrease
        ? '+${NumberFormat('#,##0').format(amount.abs())}'
        : NumberFormat('#,##0').format(amount);

    final formattedDate = DateFormat(
      'dd-MM-yyyy',
    ).format(DateTime.parse(adjustment.createdAt));

    final reasonText = adjustment.reason?.isNotEmpty == true
        ? adjustment.reason
        : 'No reason provided';
    final inventoryItem = adjustment.inventoryItem;

    final itemName = inventoryItem.name;
    final itemUnit = inventoryItem.unit;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    itemName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: amountColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$amountText $itemUnit',
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ⭐️ REMOVED: Current Stock logic
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              'Reason:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              reasonText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
