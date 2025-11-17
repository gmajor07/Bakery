import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/sale_item.dart';
import '../../provider/sales_provider.dart';
// 🚨 NEW: Import the TokenErrorWidget
import '../../widgets/token_error_widget.dart';
import '../pos_screens/generate_pdf.dart';
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
    this.itemsPerPage = 50, // Default items per page
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
// 🚨 Sales History Screen with Client-Side Logic
// ----------------------------------------------------------------------

// 🚨 NEW: Date filter options enum
enum QuickDateFilter { all, today, yesterday, last7Days, thisMonth, lastMonth }

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  // Local state for client-side search/filter
  String searchQuery = '';
  DateTimeRange? selectedRange;
  // 🚨 NEW: State for the quick date filter selection
  QuickDateFilter selectedQuickFilter = QuickDateFilter.last7Days;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // Set initial date range to last 7 days
    selectedRange = _getDateRange(QuickDateFilter.last7Days);

    // Search listener logic from PaymentScreen
    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text.toLowerCase());
      ref.read(salesPaginationProvider.notifier).reset();
    });

    // Initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(salesHistoryProvider);
    });
  }
  // ... (rest of initState, dispose, scrollListener, onRefresh, clearAllFilters remain the same)

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final paginationState = ref.read(salesPaginationProvider);
      if (paginationState.hasMore) {
        ref.read(salesPaginationProvider.notifier).nextPage();
      }
    }
  }

  Future<void> _onRefresh() async {
    ref.invalidate(salesHistoryProvider);
  }

  void _clearAllFilters() {
    setState(() {
      selectedRange = null;
      selectedQuickFilter = QuickDateFilter.all; // Reset quick filter
      _searchController.clear();
      searchQuery = '';
    });
    ref.read(salesPaginationProvider.notifier).reset();
  }

  // ----------------------------------------------------------------------
  // 🚨 NEW: Helper method to calculate date ranges
  // ----------------------------------------------------------------------
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
    }
  }

  // ----------------------------------------------------------------------
  // 🚨 UI: Build method (Updated error state)
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesHistoryProvider);
    final paginationState = ref.watch(salesPaginationProvider);

    final hasFilters = selectedRange != null || searchQuery.isNotEmpty;

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
            _buildFiltersSection(context),
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
                // 🚨 UPDATED: Use TokenErrorWidget for error display
                error: (error, _) {
                  final msg = error.toString().toLowerCase();
                  if (msg.contains('401') ||
                      msg.contains('unauthorized') ||
                      msg.contains('token') ||
                      msg.contains('expired')) {
                    return TokenErrorWidget(ref: ref);
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
  // 🚨 UI: Date filter section (Updated with Quick Filters)
  // ----------------------------------------------------------------------

  Widget _buildFiltersSection(BuildContext context) {
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
                labelText: 'Search by customer name or receipt #',
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

            // 🚨 NEW: Quick Date Filter Chips/Buttons
            _buildQuickDateFilters(),

            const SizedBox(height: 12),

            // Date Range Picker (Only if 'Custom' option is needed, otherwise use only quick filters)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      selectedRange == null
                          ? 'Select Custom Range'
                          : '${DateFormat('MMM dd').format(selectedRange!.start)} - ${DateFormat('MMM dd, yyyy').format(selectedRange!.end)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () async {
                      // Deselect quick filter when choosing custom range
                      setState(() => selectedQuickFilter = QuickDateFilter.all);
                      final now = DateTime.now();
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(now.year - 5),
                        lastDate: DateTime(now.year + 1),
                        initialDateRange: selectedRange,
                      );
                      if (picked != null) {
                        // Ensure the range includes the end day completely
                        final end = DateTime(
                          picked.end.year,
                          picked.end.month,
                          picked.end.day,
                          23,
                          59,
                          59,
                        );
                        setState(
                          () => selectedRange = DateTimeRange(
                            start: picked.start,
                            end: end,
                          ),
                        );
                        ref.read(salesPaginationProvider.notifier).reset();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                if (selectedRange != null &&
                    selectedQuickFilter ==
                        QuickDateFilter
                            .all) // Only show clear button for custom range
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearAllFilters,
                    tooltip: 'Clear date filter',
                  ),
              ],
            ),
          ],
        ),
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
                  setState(() {
                    selectedQuickFilter = filter;
                    selectedRange = _getDateRange(filter);
                  });
                  ref.read(salesPaginationProvider.notifier).reset();
                } else if (filter == selectedQuickFilter) {
                  // Allow deselection to 'All'
                  setState(() {
                    selectedQuickFilter = QuickDateFilter.all;
                    selectedRange = null;
                  });
                  ref.read(salesPaginationProvider.notifier).reset();
                }
              },
            ),
          );
        }).toList(),
      ),
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

  // ----------------------------------------------------------------------
  // 🚨 Filter and Pagination Methods (Updated date filter logic)
  // ----------------------------------------------------------------------
  // In _SalesHistoryScreenState

  List<SaleItem> _applyFilters(List<SaleItem> sales) {
    return sales.where((sale) {
      // Search by customer or receipt number (remains the same)
      final matchesSearch =
          sale.receiptNumber.toString().toLowerCase().contains(searchQuery) ||
          sale.customer.toLowerCase().contains(searchQuery);

      // Filter by date range
      final saleDate = DateTime.parse(sale.date);

      // 🚨 REFINED FIX for date comparison
      final matchesDate =
          selectedRange == null ||
          (
          // Check if saleDate is ON or AFTER the start date (inclusive)
          saleDate.isAfter(
                selectedRange!.start.subtract(const Duration(seconds: 1)),
              ) &&
              // Check if saleDate is ON or BEFORE the inclusive end date (23:59:59)
              // We use the same comparison trick to ensure inclusion up to the last second of the day.
              saleDate.isBefore(
                selectedRange!.end.add(const Duration(seconds: 1)),
              ));

      return matchesSearch && matchesDate;
    }).toList();
  }
  // ... (rest of _applyPagination, _buildSalesList, _buildPaginationInfo, _buildEmptyState, and SaleCard remain the same)

  List<SaleItem> _applyPagination(
    List<SaleItem> sales,
    SalesPaginationState pagination,
  ) {
    final startIndex = (pagination.currentPage - 1) * pagination.itemsPerPage;
    final endIndex = startIndex + pagination.itemsPerPage;

    final hasMore = endIndex < sales.length;
    if (hasMore != pagination.hasMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(salesPaginationProvider.notifier).setHasMore(hasMore);
      });
    }

    return sales.sublist(
      startIndex,
      endIndex < sales.length ? endIndex : sales.length,
    );
  }

  Widget _buildSalesList(
    List<SaleItem> sales,
    int totalFiltered,
    SalesPaginationState pagination,
  ) {
    if (sales.isEmpty) {
      final hasFilters = selectedRange != null || searchQuery.isNotEmpty;
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
              controller: _scrollController,
              itemCount: sales.length + (pagination.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == sales.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
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
                  onPrint: () => generateSaleReceiptPdf(sale),
                );
              },
            ),
          ),
        ),
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing $startItem-$displayedEnd of $totalFiltered sales',
          style: TextStyle(color: Colors.grey[600]),
        ),
        if (totalFiltered > pagination.itemsPerPage)
          Text(
            'Page ${pagination.currentPage} of ${(totalFiltered / pagination.itemsPerPage).ceil()}',
            style: TextStyle(color: Colors.grey[600]),
          ),
      ],
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

/// Sale Card Widget (Kept as is)
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

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMd().add_Hm().format(
      DateTime.parse(sale.date),
    );
    final formattedAmount = 'TSh ${sale.amount.toStringAsFixed(0)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.receipt, color: Theme.of(context).primaryColor),
        ),
        title: Text(
          'Receipt #${sale.receiptNumber}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sale.customer,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(formattedDate),
            Text(
              formattedAmount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                fontSize: 16,
              ),
            ),
            if (sale.status != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(sale.status!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  sale.status!,
                  style: TextStyle(
                    color: _getStatusColor(sale.status!),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              onPressed: onViewDetails,
              tooltip: 'View Details',
            ),
            IconButton(
              icon: const Icon(Icons.print_outlined),
              onPressed: onPrint,
              tooltip: 'Print Receipt',
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
