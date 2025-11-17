import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/sale_item.dart';
// Note: We no longer need selectedDateRangeProvider or searchQueryProvider from here
import '../../provider/sales_provider.dart';
import '../../widgets/token_error_widget.dart';
import '../pos_screens/generate_pdf.dart';
import 'sale_detail_screen.dart';

// ----------------------------------------------------------------------
// 🚨 NEW: Client-Side Pagination State Definitions (Copied from Payment)
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
    this.itemsPerPage = 15, // Default items per page
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

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

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Scroll Listener logic from PaymentScreen for infinite scroll
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
    // Refresh loads all data again
    ref.invalidate(salesHistoryProvider);
  }

  void _clearAllFilters() {
    setState(() {
      selectedRange = null;
      _searchController.clear();
      searchQuery = '';
    });
    ref.read(salesPaginationProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    // salesHistoryProvider must fetch ALL sales data
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
                error: (err, _) => _buildErrorState(err, context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // 🚨 Filter and Pagination Methods (Copied/Adapted from Payment)
  // ----------------------------------------------------------------------

  Widget _buildFiltersSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
            // Date Range Picker
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      selectedRange == null
                          ? 'Select date range'
                          : '${DateFormat('MMM dd').format(selectedRange!.start)} - ${DateFormat('MMM dd, yyyy').format(selectedRange!.end)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(now.year - 5),
                        lastDate: DateTime(now.year + 1),
                        initialDateRange: selectedRange,
                      );
                      if (picked != null) {
                        setState(() => selectedRange = picked);
                        ref.read(salesPaginationProvider.notifier).reset();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                if (selectedRange != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() => selectedRange = null);
                      ref.read(salesPaginationProvider.notifier).reset();
                    },
                    tooltip: 'Clear date filter',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<SaleItem> _applyFilters(List<SaleItem> sales) {
    return sales.where((sale) {
      // Search by customer or receipt number
      final matchesSearch =
          sale.receiptNumber.toString().toLowerCase().contains(searchQuery) ||
          sale.customer.toLowerCase().contains(searchQuery);

      // Filter by date range
      final saleDate = DateTime.parse(sale.date);
      final matchesDate =
          selectedRange == null ||
          (saleDate.isAfter(
                selectedRange!.start.subtract(const Duration(days: 1)),
              ) &&
              saleDate.isBefore(
                selectedRange!.end.add(const Duration(days: 1)),
              ));
      return matchesSearch && matchesDate;
    }).toList();
  }

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

  Widget _buildErrorState(Object error, BuildContext context) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('token') ||
        msg.contains('401') ||
        msg.contains('unauthorized')) {
      return TokenErrorWidget(ref: ref);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load sales history',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
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
