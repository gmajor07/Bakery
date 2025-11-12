import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/customer.dart';
import '../../models/sale_item.dart';
import '../../provider/customer_provider.dart';
import '../../provider/sales_provider.dart';
import '../../widgets/token_error_widget.dart';
import '../pos_screens/generate_pdf.dart';
import 'sale_detail_screen.dart';

// Pagination provider
final salesPaginationProvider =
    StateNotifierProvider<SalesPaginationNotifier, SalesPaginationState>((ref) {
      return SalesPaginationNotifier();
    });

class SalesPaginationState {
  final int currentPage;
  final int itemsPerPage;
  final bool hasMore;

  SalesPaginationState({
    this.currentPage = 1,
    this.itemsPerPage = 10,
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

  void goToPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  void setHasMore(bool hasMore) {
    state = state.copyWith(hasMore: hasMore);
  }

  void reset() {
    state = SalesPaginationState();
  }
}

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesHistoryProvider);
    final selectedCustomer = ref.watch(selectedCustomerProvider);
    final selectedDateRange = ref.watch(selectedDateRangeProvider);
    final paginationState = ref.watch(salesPaginationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sales History')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Sales', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),

            // Filters Row - Made responsive
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  // Desktop layout
                  return Row(
                    children: [
                      Expanded(child: _buildCustomerFilter(ref)),
                      const SizedBox(width: 16),
                      _buildDatePicker(context, ref, selectedDateRange),
                    ],
                  );
                } else {
                  // Mobile layout
                  return Column(
                    children: [
                      _buildCustomerFilter(ref),
                      const SizedBox(height: 12),
                      _buildDatePicker(context, ref, selectedDateRange),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),

            // Pagination Info
            _buildPaginationInfo(paginationState, salesAsync),
            const SizedBox(height: 16),

            // Sales Data
            Expanded(
              child: salesAsync.when(
                data: (allSales) {
                  // Apply filters
                  List<SaleItem> filtered = _applyFilters(
                    allSales,
                    selectedCustomer,
                    selectedDateRange,
                  );

                  // Apply pagination
                  final paginatedSales = _applyPagination(
                    filtered,
                    paginationState,
                  );

                  return _buildSalesList(
                    context,
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

  List<SaleItem> _applyFilters(
    List<SaleItem> sales,
    Customer? selectedCustomer,
    DateTimeRange? selectedDateRange,
  ) {
    List<SaleItem> filtered = sales;

    // Filter by customer
    if (selectedCustomer != null) {
      filtered = filtered
          .where(
            (s) =>
                s.customer.toLowerCase() == selectedCustomer.name.toLowerCase(),
          )
          .toList();
    }

    // Filter by date range
    if (selectedDateRange != null) {
      filtered = filtered.where((s) {
        final saleDate = DateTime.parse(s.date);
        return saleDate.isAfter(
              selectedDateRange.start.subtract(const Duration(days: 1)),
            ) &&
            saleDate.isBefore(
              selectedDateRange.end.add(const Duration(days: 1)),
            );
      }).toList();
    }

    return filtered;
  }

  List<SaleItem> _applyPagination(
    List<SaleItem> sales,
    SalesPaginationState pagination,
  ) {
    final startIndex = (pagination.currentPage - 1) * pagination.itemsPerPage;
    final endIndex = startIndex + pagination.itemsPerPage;

    // Update hasMore state
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

  Widget _buildPaginationInfo(
    SalesPaginationState pagination,
    AsyncValue<List<SaleItem>> salesAsync,
  ) {
    return salesAsync.when(
      data: (allSales) {
        final totalItems = allSales.length;
        final startItem =
            (pagination.currentPage - 1) * pagination.itemsPerPage + 1;
        final endItem = pagination.currentPage * pagination.itemsPerPage;
        final displayedEnd = endItem > totalItems ? totalItems : endItem;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing $startItem-$displayedEnd of $totalItems sales',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (totalItems > pagination.itemsPerPage)
              _buildPaginationControls(pagination, totalItems),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildPaginationControls(
    SalesPaginationState pagination,
    int totalItems,
  ) {
    final totalPages = (totalItems / pagination.itemsPerPage).ceil();

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: pagination.currentPage > 1
              ? () => ref.read(salesPaginationProvider.notifier).previousPage()
              : null,
        ),
        Text('Page ${pagination.currentPage} of $totalPages'),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: pagination.hasMore
              ? () => ref.read(salesPaginationProvider.notifier).nextPage()
              : null,
        ),
      ],
    );
  }

  // ✅ FIXED: Customer Filter without overflow
  Widget _buildCustomerFilter(WidgetRef ref) {
    final selected = ref.watch(selectedCustomerProvider);
    final customersAsync = ref.watch(customerListProvider);

    return customersAsync.when(
      data: (customers) {
        final allOptions = [null, ...customers];
        return DropdownButtonFormField<Customer?>(
          value: selected,
          isExpanded: true, // This is key to prevent overflow
          decoration: const InputDecoration(
            labelText: 'Filter by Customer',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          items: allOptions.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Text(
                c?.name ?? 'All Customers',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            ref.read(selectedCustomerProvider.notifier).state = value;
            // Reset pagination when filter changes
            ref.read(salesPaginationProvider.notifier).reset();
          },
        );
      },
      loading: () => const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Filter by Customer',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          suffixIcon: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        child: SizedBox.shrink(),
      ),
      error: (error, _) => DropdownButtonFormField<Customer?>(
        value: selected,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Filter by Customer',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          errorText: 'Failed to load',
        ),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text(
              'All Customers',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
        onChanged: null,
      ),
    );
  }

  // ✅ Date Range Picker with better layout
  Widget _buildDatePicker(
    BuildContext context,
    WidgetRef ref,
    DateTimeRange? range,
  ) {
    final label = range == null
        ? 'Select date range'
        : '${DateFormat('MMM dd').format(range.start)} - ${DateFormat('MMM dd, yyyy').format(range.end)}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 400;
        return SizedBox(
          width: isWide
              ? null
              : double.infinity, // ✅ allow width only when not inside Row
          child: OutlinedButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
                initialDateRange: range,
              );
              if (picked != null) {
                ref.read(selectedDateRangeProvider.notifier).state = picked;
                ref.read(salesPaginationProvider.notifier).reset();
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildSalesList(
    BuildContext context,
    List<SaleItem> sales,
    int totalFiltered,
    SalesPaginationState pagination,
  ) {
    if (sales.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No sales found', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ❌ Removed Expanded here
        Flexible(
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
              return _buildSaleCard(context, sale);
            },
          ),
        ),

        if (totalFiltered > pagination.itemsPerPage)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey)),
            ),
            child: _buildPaginationControls(pagination, totalFiltered),
          ),
      ],
    );
  }

  Widget _buildSaleCard(BuildContext context, SaleItem sale) {
    final formattedDate = DateFormat.yMMMd().format(DateTime.parse(sale.date));
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
        title: Text('Receipt #${sale.receiptNumber}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sale.customer, overflow: TextOverflow.ellipsis, maxLines: 1),
            Text(formattedDate),
            Text(
              formattedAmount,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SaleDetailScreen(saleId: sale.receiptNumber),
                  ),
                );
              },
              tooltip: 'View Details',
            ),
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => generateSaleReceiptPdf(sale),
              tooltip: 'Print Receipt',
            ),
          ],
        ),
      ),
    );
  }
}
