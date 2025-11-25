import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../provider/adjustment_provider.dart';
import '../widgets/token_error_widget.dart';
import 'new_adjustment.dart';

// Assuming you have an Adjustment model defined elsewhere that is similar to:
// class Adjustment { final int id; final num amount; final String reason; final String createdAt; final InventoryItem inventoryItem; }
// class InventoryItem { final String name; final String unit; }

enum QuickDateFilter { all, today, yesterday, last7Days, thisMonth, lastMonth }

class AdjustmentsScreen extends ConsumerStatefulWidget {
  const AdjustmentsScreen({super.key});

  @override
  ConsumerState<AdjustmentsScreen> createState() => _AdjustmentsScreenState();
}

class _AdjustmentsScreenState extends ConsumerState<AdjustmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  QuickDateFilter selectedQuickFilter = QuickDateFilter.today;

  @override
  void initState() {
    super.initState();

    final filters = ref.read(adjustmentFiltersProvider);
    _searchController.text = filters.search ?? '';

    // FIX: Delay the provider modification until after the first frame.
    if (filters.startDate == null && filters.endDate == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyQuickDateFilter(QuickDateFilter.today);
      });
    }
  }

  void _applyQuickDateFilter(QuickDateFilter filter) {
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
        // Ensure the end date is inclusive of the entire day
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
        final lastMonthEnd = DateTime(now.year, now.month, 0);
        final lastMonthStart = DateTime(
          lastMonthEnd.year,
          lastMonthEnd.month,
          1,
        );
        startDate = lastMonthStart.toIso8601String();
        endDate = lastMonthEnd.toIso8601String();
        break;
    }

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
      lastDate: DateTime.now().add(
        const Duration(days: 1),
      ), // Allow selecting today
    );

    if (picked != null) {
      setState(() => selectedQuickFilter = QuickDateFilter.all);

      ref
          .read(adjustmentFiltersProvider.notifier)
          .update(
            (s) => s.copyWith(
              // Ensure end date is inclusive of the whole day (by setting it to 23:59:59 of the end day)
              startDate: picked.start.toIso8601String(),
              endDate: picked.end
                  .add(const Duration(hours: 23, minutes: 59, seconds: 59))
                  .toIso8601String(),
              page: 1,
            ),
          );
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

                    // Quick Date Filter Chips
                    _buildQuickDateFilters(),

                    const SizedBox(height: 12),

                    // Date Range Picker
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
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
          ),

          // Adjustments Data List View (REPLACED DATATABLE)
          Expanded(
            child: adjustmentsAsync.when(
              data: (adjustments) {
                if (adjustments.isEmpty) {
                  return _buildEmptyState(hasFilters);
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: adjustments.length,
                  itemBuilder: (context, index) {
                    final adj = adjustments[index];
                    return AdjustmentTile(adjustment: adj);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) {
                final msg = error.toString().toLowerCase();
                if (msg.contains('401') ||
                    msg.contains('unauthorized') ||
                    msg.contains('token') ||
                    msg.contains('expired')) {
                  return TokenErrorWidget();
                }
                return Center(child: Text('Error: ${error.toString()}'));
              },
            ),
          ),

          // Pagination
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
                  _applyQuickDateFilter(filter);
                } else if (filter == selectedQuickFilter) {
                  _applyQuickDateFilter(QuickDateFilter.all);
                }
              },
            ),
          );
        }).toList(),
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

// -------------------------------------------------------------------
// 🎯 NEW WIDGET: Mobile-friendly list item for a single adjustment
// -------------------------------------------------------------------

// Note: This relies on the structure of your adjustment/item model.
// Assuming your Adjustment model has: .amount, .createdAt, .reason, and .inventoryItem
// And InventoryItem has: .name, .unit

class AdjustmentTile extends StatelessWidget {
  final dynamic
  adjustment; // Replace 'dynamic' with your actual Adjustment model type

  const AdjustmentTile({super.key, required this.adjustment});

  @override
  Widget build(BuildContext context) {
    final amount = adjustment.amount as num;
    final isIncrease = amount > 0;

    final amountColor = isIncrease
        ? Colors.green.shade700
        : Colors.red.shade700;
    final amountText = isIncrease
        ? '+${amount.abs()}'
        : amount.toString(); // Keep negative sign for decreases

    final formattedDate = DateFormat(
      'MMM dd, yyyy HH:mm',
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
            // Row 1: Item Name and Quantity
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

            // Row 2: Date and Time
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

            // Row 3: Reason
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
