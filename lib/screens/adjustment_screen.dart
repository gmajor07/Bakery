import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../provider/adjustment_provider.dart';
import '../widgets/token_error_widget.dart';
import 'new_adjustment.dart';

// ⭐️ ADDED: 'custom' to the enum
enum QuickDateFilter { all, today, yesterday, last7Days, thisMonth, lastMonth, custom }

class AdjustmentsScreen extends ConsumerStatefulWidget {
  const AdjustmentsScreen({super.key});

  @override
  ConsumerState<AdjustmentsScreen> createState() => _AdjustmentsScreenState();
}

class _AdjustmentsScreenState extends ConsumerState<AdjustmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  // ⭐️ MODIFIED: Default to 'all' or determine based on existing filters
  QuickDateFilter selectedQuickFilter = QuickDateFilter.all;

  @override
  void initState() {
    super.initState();

    final filters = ref.read(adjustmentFiltersProvider);
    _searchController.text = filters.search ?? '';

    // Determine initial quick filter based on loaded dates
    _updateQuickFilterState(filters.startDate, filters.endDate);

    // FIX: Delay the provider modification until after the first frame.
    // Ensure 'Today' is applied if no filters are present.
    if (filters.startDate == null && filters.endDate == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Apply a default filter if none is set
        _applyQuickDateFilter(QuickDateFilter.today);
      });
    }
  }

  // ⭐️ NEW: Logic to determine the active quick filter state
  void _updateQuickFilterState(String? startDateStr, String? endDateStr) {
    if (startDateStr == null || endDateStr == null) {
      selectedQuickFilter = QuickDateFilter.all;
    } else {
      // For simplicity, if dates are set, we label it as 'custom'
      selectedQuickFilter = QuickDateFilter.custom;
    }
  }

  // ⭐️ MODIFIED: Now handles 'custom' and sets the filter state
  void _applyQuickDateFilter(QuickDateFilter filter, [DateTimeRange? customRange]) {
    final newRange = filter == QuickDateFilter.custom ? customRange : _getDateRange(filter);

    setState(() => selectedQuickFilter = filter);

    if (newRange == null) {
      ref.read(adjustmentFiltersProvider.notifier).update(
            (s) => s.copyWith(startDate: null, endDate: null, page: 1),
      );
    } else {
      // Normalize dates: start time 00:00:00, end time 23:59:59
      final start = DateTime(newRange.start.year, newRange.start.month, newRange.start.day);
      final end = DateTime(newRange.end.year, newRange.end.month, newRange.end.day)
          .add(const Duration(days: 1))
          .subtract(const Duration(seconds: 1));

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

  // ⭐️ NEW: Helper to get DateTimeRange for quick filters
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
        return null; // Handled by _pickDateRange
    }
  }

  // ⭐️ MODIFIED: Calls _applyQuickDateFilter with QuickDateFilter.custom
  void _pickDateRange() async {
    final filters = ref.read(adjustmentFiltersProvider);
    DateTimeRange? initialRange;

    // Set initial range if custom dates are already set
    if (filters.startDate != null && filters.endDate != null) {
      initialRange = DateTimeRange(
        start: DateTime.parse(filters.startDate!),
        // The saved end date includes 23:59:59, so we subtract one second to get the start of the end day
        end: DateTime.parse(filters.endDate!).subtract(const Duration(seconds: 1)),
      );
    }

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: initialRange,
    );

    if (picked != null) {
      // Apply the result as a custom filter
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
        return 'Custom Range'; // ⭐️ Added custom name
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
                    _buildQuickDateFilters(filters), // ⭐️ Pass filters
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
                  return const TokenErrorWidget();
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
                  // ⭐️ Logic improved to use maybeWhen/orElse for safer check
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

  // ⭐️ MODIFIED: Now includes Custom Range button/chip logic
  Widget _buildQuickDateFilters(dynamic filters) {
    const filterOptions = [
      QuickDateFilter.today,
      QuickDateFilter.yesterday,
      QuickDateFilter.last7Days,
      QuickDateFilter.thisMonth,
      QuickDateFilter.lastMonth,
      QuickDateFilter.custom, // ⭐️ Added custom filter chip
    ];

    final primaryColor = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Custom Date Range Picker Button (retained for explicit picker access)
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

          // Filter Chips
          ...filterOptions.map((filter) {
            final isSelected = filter == selectedQuickFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(
                  // Display selected custom range on the chip
                  filter == QuickDateFilter.custom && filters.startDate != null
                      ? '${DateFormat('MMM dd').format(DateTime.parse(filters.startDate!))} - ${DateFormat('MMM dd').format(DateTime.parse(filters.endDate!).subtract(const Duration(seconds: 1)))}'
                      : _getFilterName(filter),
                ),
                selected: isSelected,
                selectedColor: primaryColor.withOpacity(0.15),
                checkmarkColor: primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? primaryColor : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (filter == QuickDateFilter.custom) {
                    // Only open the picker if it's not currently selected, or if the user clicks the explicit button.
                    if (!isSelected) _pickDateRange();
                  } else if (selected) {
                    _applyQuickDateFilter(filter);
                  } else if (filter == selectedQuickFilter) {
                    // Allows deselecting back to 'All Time'
                    _applyQuickDateFilter(QuickDateFilter.all);
                  }
                },
              ),
            );
          }).toList(),
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


class AdjustmentTile extends StatelessWidget {
  final dynamic
  adjustment; // Replace 'dynamic' with your actual Adjustment model type

  const AdjustmentTile({super.key, required this.adjustment});

  @override
  Widget build(BuildContext context) {
    // ⚠️ WARNING: Relying on 'dynamic' for complex logic can lead to runtime errors.
    // Ensure 'adjustment' matches the expected model structure (e.g., has .amount, .createdAt, .reason, .inventoryItem.name, etc.)
    final amount = adjustment.amount as num;
    final isIncrease = amount > 0;

    final amountColor = isIncrease
        ? Colors.brown.shade700
        : Colors.red.shade700;
    final amountText = isIncrease
        ? '+${NumberFormat('#,##0').format(amount.abs())}'
        : NumberFormat('#,##0').format(amount); // Format negative number

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