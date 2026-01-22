import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/sale_item.dart';
import '../../provider/sales_provider.dart';
import '../../provider/settings_provider.dart';
import '../../widgets/print_receipt.dart';
import '../../widgets/token_error_widget.dart';
import 'sale_detail_screen.dart';

// ----------------------------------------------------------------------
// 🚨 Client-Side Pagination State Definitions (Kept as is)
// ----------------------------------------------------------------------

final salesPaginationProvider =
StateNotifierProvider<SalesPaginationNotifier, SalesPaginationState>(
      (ref) => SalesPaginationNotifier(),
);

class SalesPaginationState {
  final int currentPage;
  final int itemsPerPage;
  final bool hasMore;

  SalesPaginationState({
    this.currentPage = 1,
    this.itemsPerPage = 10, // Default items per page
    this.hasMore = true,
  });

  SalesPaginationState copyWith({
    int? currentPage,
    int? itemsPerPage,
    bool? hasMore,
  }) {
    return SalesPaginationState(
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class SalesPaginationNotifier extends StateNotifier<SalesPaginationState> {
  SalesPaginationNotifier() : super(SalesPaginationState());

  void nextPage() {
    state = state.copyWith(currentPage: state.currentPage + 1);
  }

  void previousPage() {
    if (state.currentPage > 1) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  void setHasMore(bool hasMore) {
    state = state.copyWith(hasMore: hasMore);
  }

  void reset() {
    state = SalesPaginationState();
  }
}

// ----------------------------------------------------------------------
// 🚨 Sales History Screen with Standardized Filtering and Pagination
// ----------------------------------------------------------------------

// 🚨 NEW/FIXED: Date filter options enum (Consistent with PO screen)
enum QuickDateFilter {
  all,
  today,
  yesterday,
  last7Days,
  thisMonth,
  lastMonth,
  custom, // 🚨 Added custom option for chip display
}

// ⭐️ NEW CONSTANT: Define the light brown color
const Color lightBrownBackground = Color(0xFFEEE3D7);

// 🚨 NEW PROVIDERS for Sales History Filtering (Standardized)
final selectedSaleStatusProvider = StateProvider<String?>((ref) => null);
final selectedSaleDateRangeProvider = StateProvider<DateTimeRange?>(
      (ref) => null,
);

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  // ❌ Removed: ScrollController for infinite scrolling
  final TextEditingController _searchController = TextEditingController();

  // Local state for client-side search/filter
  String searchQuery = '';
  // Local state for quick filter (used to control the chips)
  QuickDateFilter selectedQuickFilter = QuickDateFilter.today;
  // Custom date range state for DateRangePicker
  DateTimeRange? customDateRange;
  // Status filter state
  String? selectedStatus;

  @override
  void initState() {
    super.initState();

    // 1. Search listener logic (updates local state and Riverpod search query)
    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text.toLowerCase());
      ref.read(salesPaginationProvider.notifier).reset();
    });

    // 2. Initial data load and filter setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set initial date filter to Today
      _applyQuickFilter(QuickDateFilter.today);
      // Invalidate to fetch data based on the initial filters
      ref.invalidate(salesHistoryProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(salesHistoryProvider);
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      searchQuery = '';
      selectedQuickFilter = QuickDateFilter.all; // Reset quick filter
      customDateRange = null;
      selectedStatus = null; // Clear local status filter
    });

    // Clear Riverpod filter states
    ref.read(selectedSaleStatusProvider.notifier).state = null;
    ref.read(selectedSaleDateRangeProvider.notifier).state = null;
    ref.read(salesPaginationProvider.notifier).reset();
  }

  // ----------------------------------------------------------------------
  // 🚨 NEW/FIXED: Date Filter Logic (Standardized with PO screen)
  // ----------------------------------------------------------------------

  void _applyQuickFilter(QuickDateFilter filter, [DateTimeRange? customRange]) {
    setState(() {
      selectedQuickFilter = filter;
      if (filter == QuickDateFilter.custom) {
        customDateRange = customRange;
      } else {
        customDateRange = null;
      }
    });

    // This updates the Riverpod state for filtering
    ref.read(selectedSaleDateRangeProvider.notifier).state =
    filter == QuickDateFilter.custom ? customRange : _getDateRange(filter);

    ref.read(salesPaginationProvider.notifier).reset();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange:
      customDateRange ?? _getDateRange(QuickDateFilter.last7Days),
      helpText: 'Select Sale Date Range',
      saveText: 'Apply',
      // 🚨 FIX: Apply Theme Builder for consistent style
      builder: (context, child) {
        return Theme(
          // Use the current theme for consistency
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Normalize picked range to full day range (start of start day to end of end day)
      final normalizedRange = DateTimeRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
        ).add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
      );
      _applyQuickFilter(QuickDateFilter.custom, normalizedRange);
    }
  }

  DateTimeRange? _getDateRange(QuickDateFilter filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // End of today (23:59:59)
    final endOfToday = today
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    switch (filter) {
      case QuickDateFilter.all:
        return null;
      case QuickDateFilter.today:
        return DateTimeRange(start: today, end: endOfToday);
      case QuickDateFilter.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return DateTimeRange(
          start: yesterday,
          end: today.subtract(const Duration(seconds: 1)),
        );
      case QuickDateFilter.last7Days:
        final lastWeek = today.subtract(const Duration(days: 6));
        return DateTimeRange(start: lastWeek, end: endOfToday);
      case QuickDateFilter.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: startOfMonth, end: endOfToday);
      case QuickDateFilter.lastMonth:
        final firstDayThisMonth = DateTime(now.year, now.month, 1);
        final lastDayLastMonth = firstDayThisMonth.subtract(
          const Duration(days: 1),
        );
        final firstDayLastMonth = DateTime(
          lastDayLastMonth.year,
          lastDayLastMonth.month,
          1,
        );
        return DateTimeRange(
          start: firstDayLastMonth,
          end: lastDayLastMonth
              .add(const Duration(days: 1))
              .subtract(const Duration(seconds: 1)),
        );
      case QuickDateFilter.custom:
        return customDateRange;
    }
  }

  // ----------------------------------------------------------------------
  // UI: Build method (Updated error state)
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesHistoryProvider);
    final paginationState = ref.watch(salesPaginationProvider);
    final selectedRange = ref.watch(selectedSaleDateRangeProvider);
    final selectedStatus = ref.watch(selectedSaleStatusProvider);

    final hasFilters =
        selectedRange != null ||
            searchQuery.isNotEmpty ||
            selectedStatus != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Filters Section ---
            _buildFiltersSection(context, selectedStatus),
            const SizedBox(height: 16),

            // --- Sales Data with Pull-to-refresh ---
            Expanded(
              child: salesAsync.when(
                data: (allSales) {
                  // 1. Apply Filters (Client-Side)
                  final filtered = _applyFilters(allSales);

                  // 2. Apply Pagination (Client-Side)
                  final paginatedSales = _applyPagination(
                    filtered,
                    paginationState,
                  );

                  return _buildSalesList(
                    paginatedSales,
                    filtered.length,
                    paginationState,
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
                  return Center(child: Text('Error: $error'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // 🚨 UI: Date and Status Filter section (Standardized)
  // ----------------------------------------------------------------------

  Widget _buildFiltersSection(BuildContext context, String? selectedStatus) {
    return Card(
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
                labelText: 'Search by receipt # or customer name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => searchQuery = '');
                    ref.read(salesPaginationProvider.notifier).reset();
                  },
                )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // 🚨 NEW: Row for Status Filter and Date Picker Button
            Row(
              children: [
                // Status Filter
                Expanded(child: _buildStatusFilter(selectedStatus)),
                const SizedBox(width: 8),

                // Date Picker Button (launches custom date range picker)
                SizedBox(
                  width: 50,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _selectDateRange(context),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    child: const Icon(Icons.date_range),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick Date Filter Chips/Buttons
            _buildQuickDateFilters(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter(String? selected) {
    // Define the available statuses for sales (lowercase used for internal value)
    const statuses = [null, 'completed', 'pending', 'cancelled'];

    return DropdownButtonFormField<String?>(
      value: selected,
      items: statuses
          .map(
            (s) => DropdownMenuItem(
          value: s,
          // 🎯 FIX: Display text is capitalized for better UI
          child: Text(s == null ? "All Status" : _capitalizeFirstLetter(s)),
        ),
      )
          .toList(),
      onChanged: (val) {
        ref.read(selectedSaleStatusProvider.notifier).state = val;
        ref.read(salesPaginationProvider.notifier).reset();
        setState(() => selectedStatus = val); // Keep local state updated
      },
      decoration: const InputDecoration(
        labelText: "Status",
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
      QuickDateFilter.lastMonth,
      QuickDateFilter.custom, // Include custom range chip
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

  // ----------------------------------------------------------------------
  // Helper Methods (Modified to handle QuickDateFilter enum)
  // ----------------------------------------------------------------------

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
        if (customDateRange != null) {
          final start = DateFormat('MMM d').format(customDateRange!.start);
          final end = DateFormat('MMM d').format(customDateRange!.end);
          return '$start - $end';
        }
        return 'Custom Range';
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    // Handle null/all case specifically
    if (text.toLowerCase() == 'completed' ||
        text.toLowerCase() == 'pending' ||
        text.toLowerCase() == 'cancelled') {
      return text[0].toUpperCase() + text.substring(1);
    }
    return text[0].toUpperCase() + text.substring(1);
  }

  // ----------------------------------------------------------------------
  // Filter and Pagination Methods (Using Riverpod state for filtering)
  // ----------------------------------------------------------------------

  List<SaleItem> _applyFilters(List<SaleItem> sales) {
    final selectedStatus = ref.watch(selectedSaleStatusProvider);
    final selectedRange = ref.watch(selectedSaleDateRangeProvider);

    return sales.where((sale) {
      // 1. Search Filter
      final matchesSearch =
          searchQuery.isEmpty ||
              sale.receiptNumber.toString().toLowerCase().contains(searchQuery) ||
              sale.customer.toLowerCase().contains(searchQuery);

      // 2. Status Filter
      // 🎯 FIX: Ensure case-insensitive comparison for status
      final matchesStatus =
          selectedStatus == null ||
              sale.status.toLowerCase() == selectedStatus.toLowerCase();

      // 3. Date Filter
      bool matchesDate = true;
      if (selectedRange != null) {
        final saleDate = DateTime.parse(sale.date);

        // Normalize sale date to start of the day for accurate comparison
        final startOfSaleDay = DateTime(
          saleDate.year,
          saleDate.month,
          saleDate.day,
        );
        final startOfRangeDay = selectedRange.start;
        final endOfRangeDay = selectedRange.end;

        // Check if the sale date is within or exactly at the start/end of the range
        matchesDate =
            (startOfSaleDay.isAtSameMomentAs(startOfRangeDay) ||
                startOfSaleDay.isAfter(startOfRangeDay)) &&
                (startOfSaleDay.isAtSameMomentAs(endOfRangeDay) ||
                    startOfSaleDay.isBefore(endOfRangeDay));
      }

      return matchesSearch && matchesStatus && matchesDate;
    }).toList();
  }

  List<SaleItem> _applyPagination(
      List<SaleItem> sales,
      SalesPaginationState pagination,
      ) {
    final startIndex = (pagination.currentPage - 1) * pagination.itemsPerPage;
    final endIndex = startIndex + pagination.itemsPerPage;


    if (startIndex >= sales.length) {
      // Safety check: if current page is beyond data, go back to last page
      if (pagination.currentPage > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(salesPaginationProvider.notifier).previousPage();
        });
      }
      return [];
    }

    return sales.sublist(
      startIndex,
      endIndex < sales.length ? endIndex : sales.length,
    );
  }

  // ----------------------------------------------------------------------
  // UI: Sales List and Pagination Controls (New Pagination Buttons)
  // ----------------------------------------------------------------------

  Widget _buildSalesList(
      List<SaleItem> sales,
      int totalFiltered,
      SalesPaginationState pagination,
      ) {
    if (sales.isEmpty) {
      final hasFilters =
          ref.watch(selectedSaleDateRangeProvider) != null ||
              searchQuery.isNotEmpty ||
              ref.watch(selectedSaleStatusProvider) != null;
      return _buildEmptyState(hasFilters);
    }

    return Column(
      children: [
        _buildPaginationInfo(totalFiltered, pagination),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: sales.length,
              itemBuilder: (context, index) {
                final sale = sales[index];
                return SaleCard(
                  sale: sale,
                  onViewDetails: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SaleDetailScreen(saleId: sale.receiptNumber),
                      ),
                    );
                  },
                  onPrint: () async {
                    final bakeryInfo = await ref.read(bakeryInfoProvider.future);
                    await generateSaleReceiptPdf(sale, bakeryInfo: bakeryInfo);
                  },
                );
              },
            ),
          ),
        ),
        // 🚨 FIX: Pagination Buttons at the bottom
        _buildPaginationControls(totalFiltered, pagination),
      ],
    );
  }

  Widget _buildPaginationInfo(
      int totalFiltered,
      SalesPaginationState pagination,
      ) {
    final startItem =
        (pagination.currentPage - 1) * pagination.itemsPerPage + 1;
    final endItem = pagination.currentPage * pagination.itemsPerPage;
    final displayedEnd = endItem > totalFiltered ? totalFiltered : endItem;
    final totalPages = (totalFiltered / pagination.itemsPerPage).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing $startItem-$displayedEnd of $totalFiltered sales',
          style: TextStyle(color: Colors.grey[600]),
        ),
        if (totalFiltered > pagination.itemsPerPage)
          Text(
            'Page ${pagination.currentPage} of $totalPages',
            style: TextStyle(color: Colors.grey[600]),
          ),
      ],
    );
  }

  Widget _buildPaginationControls(
      int totalFiltered,
      SalesPaginationState pagination,
      ) {
    final totalPages = (totalFiltered / pagination.itemsPerPage).ceil();
    final isFirstPage = pagination.currentPage == 1;
    final isLastPage = pagination.currentPage >= totalPages;

    if (totalFiltered <= pagination.itemsPerPage) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🎯 FIX: Use OutlinedButton for consistent styling with PO screen
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: isFirstPage
                ? null
                : ref.read(salesPaginationProvider.notifier).previousPage,
            child: const Text('Previous'),
          ),
          const SizedBox(width: 16),
          // 🎯 FIX: Use OutlinedButton for consistent styling with PO screen
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: isLastPage
                ? null
                : ref.read(salesPaginationProvider.notifier).nextPage,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool hasFilters) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No sales found',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  hasFilters
                      ? 'Clear filters or try a different search term.'
                      : 'Pull down to refresh the list.',
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
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------

/// Modernized Sale Card Widget (Kept as is)
class SaleCard extends StatelessWidget {
  final SaleItem sale;
  final VoidCallback onViewDetails;
  final VoidCallback onPrint;

  const SaleCard({
    super.key,
    required this.sale,
    required this.onViewDetails,
    required this.onPrint,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.brown;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat(
      'MMM dd, yyyy - HH:mm',
    ).format(DateTime.parse(sale.date));
    // Use NumberFormat for better localization/currency display
    final numberFormat = NumberFormat.currency(
      locale: 'en_TZ', // Example locale for Tanzania
      symbol: 'TSh',
      decimalDigits: 0,
    );
    final formattedAmount = numberFormat.format(sale.amount);

    return InkWell(
      onTap: onViewDetails, // ⭐ tap anywhere = open details
      borderRadius: BorderRadius.circular(12), // Larger radius for modern look
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor, // Use card color for distinction
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.5), // Subtle border
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Icon/Receipt Number Section (Left) ---
            Icon(
              Icons.receipt_long, // Modern icon
              color: theme.primaryColor,
              size: 28,
            ),
            const SizedBox(width: 16),

            // --- Details Section (Center) ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Receipt Number
                  Text(
                    '#${sale.receiptNumber}',
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Customer Name
                  Text(
                    sale.customer,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Date
                  Text(
                    formattedDate,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.7,
                      ),
                    ),
                  ),

                  // Status Badge
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _StatusBadge(
                      status: sale.status,
                      color: _getStatusColor(sale.status),
                    ),
                  ),
                ],
              ),
            ),

            // --- Amount & Actions Section (Right) ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Amount
                Text(
                  formattedAmount,
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 10),

                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // View Details Indicator
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper Widget for Status Badge
class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    // Ensure the entire string (like "completed") is capitalized only at the first letter
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20), // Pill shape
      ),
      child: Text(
        // 🎯 FIX: Use the capitalization utility instead of .toUpperCase()
        _capitalizeFirstLetter(status),
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontSize: 10,
        ),
      ),
    );
  }
}