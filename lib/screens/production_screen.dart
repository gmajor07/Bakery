import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/production_items.dart';
import '../../provider/production_provider.dart';
import '../../widgets/token_error_widget.dart';
import 'production_detail_screen.dart';

// ----------------------------------------------------------------------
// 🚨 NEW: Quick Date Filter Definitions
// ----------------------------------------------------------------------
enum QuickDateFilter { all, today, yesterday, last7Days, thisMonth, custom }

class ProductionScreen extends ConsumerStatefulWidget {
  const ProductionScreen({super.key});

  @override
  ConsumerState<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends ConsumerState<ProductionScreen> {
  // Local State
  String searchQuery = '';
  QuickDateFilter selectedQuickFilter = QuickDateFilter.all; // Default to All
  DateTimeRange? selectedDateRange;
  final TextEditingController _searchController = TextEditingController();

  // ⭐️ Color for selected state in chips
  final Color lightBrownBackground = const Color(0xFFEEE3D7);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text.toLowerCase());
    });

    // 🎯 INITIAL FILTER: Set initial date filter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyQuickFilter(QuickDateFilter.all);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------------------
  // ⭐️ NEW: Date Filtering Logic
  // ----------------------------------------------------------------------

  void _applyQuickFilter(QuickDateFilter filter, [DateTimeRange? customRange]) {
    final newRange = filter == QuickDateFilter.custom ? customRange : _getDateRange(filter);

    setState(() {
      selectedQuickFilter = filter;
      selectedDateRange = newRange;
    });
    // Note: No Riverpod provider needed here since the entire list is client-side filtered
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: selectedDateRange ?? _getDateRange(QuickDateFilter.last7Days),
      helpText: 'Select Production Date Range',
      saveText: 'Apply',
    );

    if (picked != null) {
      final normalizedRange = DateTimeRange(
        start: DateTime(picked.start.year, picked.start.month, picked.start.day),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day)
            .add(const Duration(days: 1))
            .subtract(const Duration(seconds: 1)),
      );
      _applyQuickFilter(QuickDateFilter.custom, normalizedRange);
    }
  }

  DateTimeRange? _getDateRange(QuickDateFilter filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfToday = today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

    switch (filter) {
      case QuickDateFilter.all:
        return null;
      case QuickDateFilter.today:
        return DateTimeRange(start: today, end: endOfToday);
      case QuickDateFilter.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return DateTimeRange(start: yesterday, end: today.subtract(const Duration(seconds: 1)));
      case QuickDateFilter.last7Days:
        final lastWeek = today.subtract(const Duration(days: 6));
        return DateTimeRange(start: lastWeek, end: endOfToday);
      case QuickDateFilter.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: startOfMonth, end: endOfToday);
      case QuickDateFilter.custom:
        return selectedDateRange;
    }
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
      case QuickDateFilter.custom:
        if (selectedDateRange != null) {
          final start = DateFormat('MMM d').format(selectedDateRange!.start);
          final end = DateFormat('MMM d').format(selectedDateRange!.end);
          return '$start - $end';
        }
        return 'Custom Range';
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      searchQuery = '';
      _applyQuickFilter(QuickDateFilter.all);
    });
  }

  // ----------------------------------------------------------------------
  // ⭐️ MODIFIED: Helper Formatting Functions
  // ----------------------------------------------------------------------

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return 'TSh ${formatter.format(amount.abs())}';
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Color _getProfitMarginColor(double margin) {
    if (margin >= 20) return Colors.brown;
    if (margin >= 10) return Colors.orange;
    return Colors.red;
  }

  void _navigateToDetail(int productionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductionDetailScreen(productionId: productionId),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // ⭐️ RESTORED: Missing Widget Builders
  // ----------------------------------------------------------------------

  // 🎯 RESTORED: _buildErrorWidget
  Widget _buildErrorWidget(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('401') ||
        msg.contains('unauthorized') ||
        msg.contains('token') ||
        msg.contains('expired')) {
      return const TokenErrorWidget();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading data',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: () => ref.invalidate(productionProvider),
          ),
        ],
      ),
    );
  }

  // 🎯 RESTORED: _buildDetailItem
  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProfitMarginItem(double margin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profit Margin',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _getProfitMarginColor(margin).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getProfitMarginColor(margin)),
          ),
          child: Text(
            '${margin.toStringAsFixed(2)}%',
            style: TextStyle(
              color: _getProfitMarginColor(margin),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No production records found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // UI Build Methods
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final productionAsync = ref.watch(productionProvider);
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Production'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // ⭐️ ADDED: Clear Filter Button in AppBar
        actions: [
          if (searchQuery.isNotEmpty || selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: 'Clear All Filters',
            ),
        ],
      ),
      body: Column(
        children: [
          // ⭐️ MODIFIED: Search and Filter Section
          _buildFilterSection(context),

          // Results Count
          _buildResultsCount(productionAsync),

          // Data Display - Responsive based on screen size
          Expanded(
            child: productionAsync.when(
              data: (items) => isTablet
                  ? _buildTabletView(items)
                  : _buildMobileView(items),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorWidget(error), // 🎯 USES RESTORED METHOD
            ),
          ),
        ],
      ),
    );
  }

  // ⭐️ NEW: Filter Section combines search and date chips
  Widget _buildFilterSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by product name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => searchQuery = '');
                  },
                )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(height: 12),

            // Date Picker and Quick Filter Chips
            Row(
              children: [
                // Date Picker Button
                SizedBox(
                  width: 50,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _selectDateRange(context),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Icon(Icons.date_range),
                  ),
                ),
                const SizedBox(width: 8),

                // Quick Filter Chips
                Expanded(child: _buildQuickDateFilters()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateFilters() {
    const filters = [
      QuickDateFilter.all,
      QuickDateFilter.today,
      QuickDateFilter.yesterday,
      QuickDateFilter.last7Days,
      QuickDateFilter.thisMonth,
      QuickDateFilter.custom,
    ];

    final primaryColor = Theme.of(context).colorScheme.primary;

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
              selectedColor: lightBrownBackground,
              checkmarkColor: primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? primaryColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (filter == QuickDateFilter.custom) {
                  _selectDateRange(context);
                } else if (selected) {
                  _applyQuickFilter(filter);
                } else if (filter == selectedQuickFilter) {
                  // Allow deselection back to 'All'
                  _applyQuickFilter(QuickDateFilter.all);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsCount(AsyncValue<List<ProductionItem>> productionAsync) {
    return productionAsync.when(
      data: (items) {
        final filteredItems = _getFilteredItems(items);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${filteredItems.length} record${filteredItems.length != 1 ? 's' : ''} found',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  // Tablet View - DataTable with horizontal scrolling
  Widget _buildTabletView(List<ProductionItem> items) {
    final filteredItems = _getFilteredItems(items);

    if (filteredItems.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: DataTable(
          headingRowColor: WidgetStateColor.resolveWith(
                (states) => Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          ),
          columns: const [
            DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Cost', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Profit Margin', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: filteredItems.map((item) => _buildTabletDataRow(item)).toList(),
        ),
      ),
    );
  }

  DataRow _buildTabletDataRow(ProductionItem item) {
    return DataRow(
      cells: [
        DataCell(
          Tooltip(
            message: item.product,
            child: Text(
              item.product,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          // ⭐️ TAPPING FIX: Added onTap to DataCell for navigation
          onTap: () => _navigateToDetail(item.id),
        ),
        DataCell(Text(item.quantity.toString())),
        DataCell(Text(_formatDate(item.date))),
        // ⭐️ FORMATTING FIX
        DataCell(Text(
          _formatCurrency(item.cost),
          style: const TextStyle(fontWeight: FontWeight.w500),
        )),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getProfitMarginColor(item.profitMargin).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getProfitMarginColor(item.profitMargin)),
            ),
            child: Text(
              '${item.profitMargin.toStringAsFixed(2)}%',
              style: TextStyle(
                color: _getProfitMarginColor(item.profitMargin),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          // ⭐️ TAPPING FIX: Keep action button for tablet for quick action
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'View details',
            onPressed: () => _navigateToDetail(item.id),
          ),
        ),
      ],
    );
  }

  // Mobile View - Card-based layout
  Widget _buildMobileView(List<ProductionItem> items) {
    final filteredItems = _getFilteredItems(items);

    if (filteredItems.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildProductionCard(item);
      },
    );
  }

  // ⭐️ MODIFIED: Card for full-card tap and removal of action button
  Widget _buildProductionCard(ProductionItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      // ⭐️ TAPPING FIX: Wrap Card content in InkWell
      child: InkWell(
        onTap: () => _navigateToDetail(item.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with product name and NO action button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.product,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Icon to hint tap-ability (optional)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Production details in a compact grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 3,
                children: [
                  _buildDetailItem('Quantity', item.quantity.toString()), // 🎯 USES RESTORED METHOD
                  _buildDetailItem('Date', _formatDate(item.date)), // 🎯 USES RESTORED METHOD
                  // ⭐️ FORMATTING FIX
                  _buildDetailItem('Cost', _formatCurrency(item.cost)), // 🎯 USES RESTORED METHOD
                  _buildProfitMarginItem(item.profitMargin),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // ⭐️ MODIFIED: Filtering and Date Range Implementation
  // ----------------------------------------------------------------------
  List<ProductionItem> _getFilteredItems(List<ProductionItem> items) {
    // 1. Remove duplicates by ID (remains the same)
    final uniqueItems = {
      for (var item in items) item.id: item,
    }.values.toList();

    return uniqueItems.where((item) {
      final itemDate = item.date;

      // 1. Search Filter
      final matchesSearch = item.product.toLowerCase().contains(searchQuery);

      // 2. Date Filter
      bool matchesDate = true;
      if (selectedDateRange != null) {
        final startOfRangeDay = selectedDateRange!.start;
        final endOfRangeDay = selectedDateRange!.end;

        // Ensure the comparison is robust (start of day to end of day)
        matchesDate =
            (itemDate.isAtSameMomentAs(startOfRangeDay) || itemDate.isAfter(startOfRangeDay)) &&
                (itemDate.isAtSameMomentAs(endOfRangeDay) || itemDate.isBefore(endOfRangeDay));
      }

      return matchesSearch && matchesDate;
    }).toList();
  }
}