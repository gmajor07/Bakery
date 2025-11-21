import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../provider/adjustment_provider.dart';
import '../widgets/token_error_widget.dart';
import 'new_adjustment.dart';

// 🚨 NEW: Date filter options enum
enum QuickDateFilter { all, today, yesterday, last7Days, thisMonth, lastMonth }

class AdjustmentsScreen extends ConsumerStatefulWidget {
  const AdjustmentsScreen({super.key});

  @override
  ConsumerState<AdjustmentsScreen> createState() => _AdjustmentsScreenState();
}

class _AdjustmentsScreenState extends ConsumerState<AdjustmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  // 🚨 NEW: State for quick date filter
  QuickDateFilter selectedQuickFilter = QuickDateFilter.today;

  @override
  void initState() {
    super.initState();

    // Read the current filters to initialize the search bar
    final filters = ref.read(adjustmentFiltersProvider);
    _searchController.text = filters.search ?? '';

    // 🚨 FIX: Delay the provider modification until after the first frame.
    // We only want to apply the default 'today' filter if no date filter
    // is currently active (e.g., if the user hasn't selected a custom range
    // on a previous visit).
    if (filters.startDate == null && filters.endDate == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyQuickDateFilter(QuickDateFilter.today);
      });
    } else {
      // If a filter is already set, update the quick filter chip state
      // based on the current date values, or set to 'all' if custom.
      // (Advanced logic would be needed here to accurately match the QuickDateFilter enum to existing dates.)
      // For simplicity, we assume if filters.startDate is set, we don't change it,
      // but we may want to set selectedQuickFilter to QuickDateFilter.all if it was a custom range.
    }
  }

  // 🚨 NEW: Helper method to calculate date ranges
  void _applyQuickDateFilter(QuickDateFilter filter) {
    // Set the state for the chip visually
    setState(() => selectedQuickFilter = filter);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    String? startDate;
    String? endDate;

    switch (filter) {
      case QuickDateFilter.all:
        startDate = null;
        endDate = null;
        break;
      case QuickDateFilter.today:
        startDate = today.toIso8601String();
        endDate = tomorrow
            .subtract(const Duration(seconds: 1))
            .toIso8601String();
        break;
      case QuickDateFilter.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        startDate = yesterday.toIso8601String();
        endDate = today.subtract(const Duration(seconds: 1)).toIso8601String();
        break;
      case QuickDateFilter.last7Days:
        final lastWeek = today.subtract(const Duration(days: 6));
        startDate = lastWeek.toIso8601String();
        endDate = tomorrow
            .subtract(const Duration(seconds: 1))
            .toIso8601String();
        break;
      case QuickDateFilter.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        startDate = startOfMonth.toIso8601String();
        endDate = tomorrow
            .subtract(const Duration(seconds: 1))
            .toIso8601String();
        break;
      case QuickDateFilter.lastMonth:
        // Calculate the last day of the previous month
        final lastMonthEnd = DateTime(now.year, now.month, 0);
        // Calculate the first day of the previous month
        final lastMonthStart = DateTime(
          lastMonthEnd.year,
          lastMonthEnd.month,
          1,
        );
        startDate = lastMonthStart.toIso8601String();
        endDate = lastMonthEnd.toIso8601String();
        break;
    }

    // This is the line that must not be called synchronously in initState/build
    ref
        .read(adjustmentFiltersProvider.notifier)
        .update(
          (s) => s.copyWith(startDate: startDate, endDate: endDate, page: 1),
        );
  }

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      // 🚨 NEW: Deselect quick filter when choosing custom range
      setState(() => selectedQuickFilter = QuickDateFilter.all);

      ref
          .read(adjustmentFiltersProvider.notifier)
          .update(
            (s) => s.copyWith(
              startDate: picked.start.toIso8601String(),
              endDate: picked.end.toIso8601String(),
              page: 1,
            ),
          );
    }
  }

  // 🚨 NEW: Clear all filters
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

  // 🚨 NEW: Get filter display name
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
        title: const Text('Inventory Adjustments'),
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
            MaterialPageRoute(builder: (_) => const NewAdjustmentScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Adjustment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🚨 UPDATED: Enhanced filters section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search Field
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search by item name',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(adjustmentFiltersProvider.notifier)
                                      .update(
                                        (s) => s.copyWith(search: '', page: 1),
                                      );
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        ref
                            .read(adjustmentFiltersProvider.notifier)
                            .update((s) => s.copyWith(search: value, page: 1));
                      },
                    ),
                    const SizedBox(height: 12),

                    // 🚨 NEW: Quick Date Filter Chips
                    _buildQuickDateFilters(),

                    const SizedBox(height: 12),

                    // Date Range Picker
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.date_range),
                            label: Text(
                              filters.startDate == null ||
                                      filters.endDate == null
                                  ? 'Select Custom Range'
                                  : '${DateFormat('MMM dd').format(DateTime.parse(filters.startDate!))} - ${DateFormat('MMM dd, yyyy').format(DateTime.parse(filters.endDate!))}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: _pickDateRange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Adjustments Data
            Expanded(
              child: adjustmentsAsync.when(
                data: (adjustments) {
                  if (adjustments.isEmpty) {
                    return _buildEmptyState(hasFilters);
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Item Name')),
                        DataColumn(label: Text('Unit')),
                        DataColumn(label: Text('Quantity')),
                        DataColumn(label: Text('Reason')),
                      ],
                      rows: adjustments.map((adj) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                DateFormat(
                                  'dd-MM-yyyy HH:mm',
                                ).format(DateTime.parse(adj.createdAt)),
                              ),
                            ),
                            DataCell(Text(adj.inventoryItem.name)),
                            DataCell(Text(adj.inventoryItem.unit)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: adj.amount > 0
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  adj.amount > 0
                                      ? '+${adj.amount}'
                                      : adj.amount.toString(),
                                  style: TextStyle(
                                    color: adj.amount > 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(adj.reason.isNotEmpty ? adj.reason : 'N/A'),
                            ),
                          ],
                        );
                      }).toList(),
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
                    return TokenErrorWidget(ref: ref);
                  }
                  return Center(child: Text('Error: ${error.toString()}'));
                },
              ),
            ),
            const SizedBox(height: 16),

            // Pagination
            Row(
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
          ],
        ),
      ),
    );
  }

  // 🚨 NEW: Build quick date filters widget
  Widget _buildQuickDateFilters() {
    const filters = [
      QuickDateFilter.today,
      QuickDateFilter.yesterday,
      QuickDateFilter.last7Days,
      QuickDateFilter.thisMonth,
      QuickDateFilter.lastMonth,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == selectedQuickFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(_getFilterName(filter)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  // No need for setState here as _applyQuickDateFilter calls it
                  _applyQuickDateFilter(filter);
                } else if (filter == selectedQuickFilter) {
                  // Allow deselection to 'All'
                  _applyQuickDateFilter(QuickDateFilter.all);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // 🚨 NEW: Build empty state widget
  Widget _buildEmptyState(bool hasFilters) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No adjustments found',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Clear filters or try a different search term.'
                : 'No inventory adjustments recorded yet.',
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
