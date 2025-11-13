import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/purchase_order.dart';
import '../../provider/purchase_orders_provider.dart';
import '../../provider/pagination_provider.dart';
import '../../widgets/date_range_picker_widget.dart';
import '../../widgets/token_error_widget.dart';
import 'create_purchase_order_screen.dart';
import 'purchase_order_detail_screen.dart';

class PurchaseOrdersScreen extends ConsumerStatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  ConsumerState<PurchaseOrdersScreen> createState() =>
      _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends ConsumerState<PurchaseOrdersScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(purchaseSearchQueryProvider.notifier).state = '';
    ref.read(selectedPurchaseStatusProvider.notifier).state = null;
    ref.read(selectedPurchaseDateRangeProvider.notifier).state = null;
    ref.read(purchasePaginationProvider.notifier).reset();
  }

  List<PurchaseOrder> _applyPagination(
    List<PurchaseOrder> orders,
    PaginationState pagination,
  ) {
    final startIndex = (pagination.currentPage - 1) * pagination.itemsPerPage;
    final endIndex = startIndex + pagination.itemsPerPage;

    final hasMore = endIndex < orders.length;
    if (hasMore != pagination.hasMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(purchasePaginationProvider.notifier).setHasMore(hasMore);
      });
    }

    return orders.sublist(
      startIndex,
      endIndex < orders.length ? endIndex : orders.length,
    );
  }

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'approved':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get status background color
  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.shade50;
      case 'pending':
        return Colors.orange.shade50;
      case 'cancelled':
        return Colors.red.shade50;
      case 'approved':
        return Colors.brown.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncOrders = ref.watch(purchaseOrdersProvider);
    final selectedStatus = ref.watch(selectedPurchaseStatusProvider);
    final selectedDate = ref.watch(selectedPurchaseDateRangeProvider);
    final paginationState = ref.watch(purchasePaginationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchase Orders"),
        actions: [
          if (_searchController.text.isNotEmpty ||
              selectedStatus != null ||
              selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: 'Clear Filters',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(purchaseOrdersProvider);
              ref.read(purchasePaginationProvider.notifier).reset();
            },
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(purchaseOrdersProvider);
            ref.read(purchasePaginationProvider.notifier).reset();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search and New Order Button
                Row(
                  children: [
                    Expanded(child: _buildSearch()),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreatePurchaseOrderScreen(),
                          ),
                        );
                        if (result == true) {
                          ref.invalidate(purchaseOrdersProvider);
                          ref.read(purchasePaginationProvider.notifier).reset();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('New Order'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Filters
                Row(
                  children: [
                    Expanded(child: _buildStatusFilter(selectedStatus)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DateRangePickerWidget(
                        initialRange: selectedDate,
                        onRangeSelected: (range) {
                          ref
                                  .read(
                                    selectedPurchaseDateRangeProvider.notifier,
                                  )
                                  .state =
                              range;
                          ref.read(purchasePaginationProvider.notifier).reset();
                        },
                        label: 'Date Range',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Orders Table with Pagination
                Expanded(
                  child: asyncOrders.when(
                    data: (allOrders) {
                      final paginatedOrders = _applyPagination(
                        allOrders,
                        paginationState,
                      );
                      return _buildTableWithPagination(
                        context,
                        paginatedOrders,
                        allOrders.length,
                        paginationState,
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) {
                      final msg = err.toString().toLowerCase();
                      if (msg.contains("token") ||
                          msg.contains("unauthorized")) {
                        return TokenErrorWidget(ref: ref);
                      }
                      return Center(child: Text("Error: $err"));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search by supplier or order #',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  ref.read(purchaseSearchQueryProvider.notifier).state = '';
                  ref.read(purchasePaginationProvider.notifier).reset();
                },
              )
            : null,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildStatusFilter(String? selected) {
    const statuses = [null, "Pending","Approved", "Cancelled", "Completed"];
    return DropdownButtonFormField<String?>(
      value: selected,
      decoration: const InputDecoration(
        labelText: "Status",
        border: OutlineInputBorder(),
      ),
      items: statuses
          .map(
            (s) => DropdownMenuItem(value: s, child: Text(s ?? "All Status")),
          )
          .toList(),
      onChanged: (value) {
        ref.read(selectedPurchaseStatusProvider.notifier).state = value;
        ref.read(purchasePaginationProvider.notifier).reset();
      },
    );
  }

  Widget _buildTableWithPagination(
    BuildContext context,
    List<PurchaseOrder> orders,
    int totalOrders,
    PaginationState pagination,
  ) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("No orders found."),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Pagination Info
        _buildPaginationInfo(totalOrders, pagination),
        const SizedBox(height: 12),

        // Table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.resolveWith<Color?>(
                  (Set<WidgetState> states) => Colors.grey.shade50,
                ),
                dataRowHeight: 60,
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                columns: const [
                  DataColumn(label: Text("Order #")),
                  DataColumn(label: Text("Date")),
                  DataColumn(label: Text("Supplier")),
                  DataColumn(label: Text("Items")),
                  DataColumn(label: Text("Total")),
                  DataColumn(label: Text("Status")),
                  DataColumn(label: Text("Actions")),
                ],
                rows: orders.map((o) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          o.id.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      DataCell(
                        Text(
                          DateFormat(
                            "dd-MM-yyyy",
                          ).format(DateTime.parse(o.createdAt)),
                        ),
                      ),
                      DataCell(
                        Text(
                          o.supplier.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      DataCell(
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              o.items.length.toString(),
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          "TSh ${o.totalCost.toStringAsFixed(0)}",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusBackgroundColor(o.status),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getStatusColor(o.status),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            o.status,
                            style: TextStyle(
                              color: _getStatusColor(o.status),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PurchaseOrderDetailScreen(order: o),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.remove_red_eye,
                            color: Colors.blue,
                          ),
                          tooltip: 'View Details',
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        // Pagination Controls
        if (totalOrders > pagination.itemsPerPage)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: _buildPaginationControls(totalOrders, pagination),
          ),
      ],
    );
  }

  Widget _buildPaginationInfo(int totalOrders, PaginationState pagination) {
    final startItem =
        (pagination.currentPage - 1) * pagination.itemsPerPage + 1;
    final endItem = pagination.currentPage * pagination.itemsPerPage;
    final displayedEnd = endItem > totalOrders ? totalOrders : endItem;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing $startItem-$displayedEnd of $totalOrders orders',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        if (totalOrders > pagination.itemsPerPage)
          Text(
            'Page ${pagination.currentPage} of ${(totalOrders / pagination.itemsPerPage).ceil()}',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildPaginationControls(int totalOrders, PaginationState pagination) {
    final totalPages = (totalOrders / pagination.itemsPerPage).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: pagination.currentPage > 1
              ? () =>
                    ref.read(purchasePaginationProvider.notifier).previousPage()
              : null,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Page ${pagination.currentPage} of $totalPages',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: pagination.hasMore
              ? () => ref.read(purchasePaginationProvider.notifier).nextPage()
              : null,
        ),
      ],
    );
  }
}
