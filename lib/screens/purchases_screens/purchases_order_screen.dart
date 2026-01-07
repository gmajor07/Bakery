import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/purchase_order.dart';
import '../../provider/purchase_orders_provider.dart';
import '../../provider/pagination_provider.dart';
import 'create_purchase_order_screen.dart';
import 'purchase_order_detail_screen.dart';

// 🎯 Reordered enum for new flow: All Time, This Month, Last Month, Last 7 Days, Today, Yesterday, Custom
enum QuickDateFilter {
  all,
  thisMonth,
  lastMonth,
  last7Days,
  today,
  yesterday,
  custom,
}

class PurchaseOrdersScreen extends ConsumerStatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  ConsumerState<PurchaseOrdersScreen> createState() =>
      _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends ConsumerState<PurchaseOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();

  String searchQuery = '';
  // 🎯 DEFAULT: Set to This Month (Keeping the default but it's now the second option in the flow)
  QuickDateFilter selectedQuickFilter = QuickDateFilter.thisMonth;
  DateTimeRange? customDateRange;

  // Brown color for selection (kept from previous changes)
  final Color _brownColor = Colors.brown.shade400;
  final Color lightBrownBackground = const Color(0xFFEEE3D7);

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text.toLowerCase());
      ref.read(purchaseSearchQueryProvider.notifier).state = searchQuery;
      ref.read(purchasePaginationProvider.notifier).reset();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 🎯 INITIAL LOAD: Show data for this month by default
      _applyQuickFilter(QuickDateFilter.thisMonth);
      ref.invalidate(purchaseOrdersProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    ref.invalidate(purchaseOrdersProvider);
    ref.read(purchasePaginationProvider.notifier).reset();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      searchQuery = '';
      selectedQuickFilter = QuickDateFilter.all;
      customDateRange = null;
    });

    ref.read(purchaseSearchQueryProvider.notifier).state = '';
    ref.read(selectedPurchaseStatusProvider.notifier).state = null;
    ref.read(selectedPurchaseDateRangeProvider.notifier).state = null;
    ref.read(purchasePaginationProvider.notifier).reset();
  }

  void _applyQuickFilter(QuickDateFilter filter, [DateTimeRange? customRange]) {
    setState(() {
      selectedQuickFilter = filter;
      if (filter == QuickDateFilter.custom) {
        customDateRange = customRange;
      } else {
        customDateRange = null;
      }
    });

    ref.read(selectedPurchaseDateRangeProvider.notifier).state =
        filter == QuickDateFilter.custom ? customRange : _getDateRange(filter);

    ref.read(purchasePaginationProvider.notifier).reset();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange:
          customDateRange ?? _getDateRange(QuickDateFilter.last7Days),
      // Set the color for the Date Range Picker Theme (kept from previous changes)
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: _brownColor),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
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
          23,
          59,
          59,
        ),
      );
      _applyQuickFilter(QuickDateFilter.custom, normalizedRange);
    }
  }

  DateTimeRange? _getDateRange(QuickDateFilter filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
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
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: endOfToday,
        );
      case QuickDateFilter.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: endOfToday,
        );
      case QuickDateFilter.lastMonth:
        final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59);
        return DateTimeRange(start: firstDayLastMonth, end: lastDayLastMonth);
      case QuickDateFilter.custom:
        return customDateRange;
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
      case QuickDateFilter.lastMonth:
        return 'Last Month';
      case QuickDateFilter.custom:
        if (customDateRange != null) {
          return '${DateFormat('MMM d').format(customDateRange!.start)} - ${DateFormat('MMM d').format(customDateRange!.end)}';
        }
        return 'Custom';
    }
  }

  // Ensure only the first letter is capitalized, and the rest is lower case. (kept from previous changes)
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    final lower = text.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  List<PurchaseOrder> _applyFilters(List<PurchaseOrder> orders) {
    final selectedStatus = ref.watch(selectedPurchaseStatusProvider);
    final selectedRange = ref.watch(selectedPurchaseDateRangeProvider);

    return orders.where((order) {
      final matchesSearch =
          searchQuery.isEmpty ||
          order.supplier.name.toLowerCase().contains(searchQuery) ||
          order.id.toString().contains(searchQuery);

      bool matchesStatus =
          selectedStatus == null ||
          order.status.toLowerCase() == selectedStatus.toLowerCase();

      bool matchesDate = true;
      if (selectedRange != null) {
        final orderDate = DateTime.parse(order.createdAt);
        // Normalize selectedRange.start for date comparison (start of the day)
        final rangeStart = DateTime(
          selectedRange.start.year,
          selectedRange.start.month,
          selectedRange.start.day,
        );
        // Normalize selectedRange.end to the end of the day
        final rangeEnd = DateTime(
          selectedRange.end.year,
          selectedRange.end.month,
          selectedRange.end.day,
          23,
          59,
          59,
        );

        matchesDate =
            orderDate.isAfter(
              rangeStart.subtract(const Duration(seconds: 1)),
            ) &&
            orderDate.isBefore(rangeEnd.add(const Duration(seconds: 1)));
      }

      return matchesSearch && matchesStatus && matchesDate;
    }).toList();
  }

  List<PurchaseOrder> _applyPagination(
    List<PurchaseOrder> orders,
    PaginationState pagination,
  ) {
    final startIndex = (pagination.currentPage - 1) * pagination.itemsPerPage;
    if (startIndex >= orders.length) return [];
    final endIndex = startIndex + pagination.itemsPerPage;
    return orders.sublist(
      startIndex,
      endIndex < orders.length ? endIndex : orders.length,
    );
  }

  // RECTANGLE THEME COLORS: Solid colors for the "Button" look (kept from previous changes)
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.brown.shade700;
      case 'pending':
        return Colors.orange.shade800;
      case 'cancelled':
        return Colors.red.shade700;
      case 'approved':
        return Colors.brown.shade300;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncOrders = ref.watch(purchaseOrdersProvider);
    final paginationState = ref.watch(purchasePaginationProvider);
    final hasFilters =
        ref.watch(selectedPurchaseDateRangeProvider) != null ||
        searchQuery.isNotEmpty ||
        ref.watch(selectedPurchaseStatusProvider) != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchase Orders"),
        actions: [
          if (hasFilters)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildFiltersSection(context),
              const SizedBox(height: 16),
              Expanded(
                child: asyncOrders.when(
                  data: (allOrders) {
                    final filtered = _applyFilters(allOrders);
                    final paginated = _applyPagination(
                      filtered,
                      paginationState,
                    );
                    return _buildOrdersList(
                      paginated,
                      filtered.length,
                      paginationState,
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text("Error: $err")),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreatePurchaseOrderScreen(),
            ),
          );
          if (result == true) _refreshData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFiltersSection(BuildContext context) {
    final selectedStatus = ref.watch(selectedPurchaseStatusProvider);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Orders or Suppliers',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatusFilter(selectedStatus)),
                const SizedBox(width: 8),
                // Date range button color to brown (kept from previous changes)
                IconButton.filledTonal(
                  onPressed: () => _selectDateRange(context),
                  icon: const Icon(Icons.date_range),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: _brownColor.withOpacity(0.1),
                    foregroundColor: _brownColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildQuickDateFilters(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter(String? selected) {
    const statuses = [null, "pending", "approved", "cancelled", "completed"];
    return DropdownButtonFormField<String?>(
      value: selected,
      decoration: const InputDecoration(
        labelText: "Status",
        border: OutlineInputBorder(),
      ),
      // Apply capitalization to the dropdown items (kept from previous changes)
      items: statuses
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(s == null ? "All Status" : _capitalizeFirstLetter(s)),
            ),
          )
          .toList(),
      onChanged: (value) {
        ref.read(selectedPurchaseStatusProvider.notifier).state = value;
        ref.read(purchasePaginationProvider.notifier).reset();
      },
    );
  }

  Widget _buildQuickDateFilters() {
    // 🎯 The filters will now appear in the order defined in the reordered enum.
    final filters = QuickDateFilter.values;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == selectedQuickFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(_getFilterName(filter)),
              selected: isSelected,
              onSelected: (val) => val ? _applyQuickFilter(filter) : null,
              // Quick Filter Chip color to brown (kept from previous changes)
              selectedColor: _brownColor,
              labelStyle: TextStyle(color: isSelected ? Colors.white : null),
              checkmarkColor: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrdersList(
    List<PurchaseOrder> orders,
    int total,
    PaginationState pagination,
  ) {
    if (orders.isEmpty) return _buildEmptyState();
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) => PurchaseOrderCard(
                order: orders[index],
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PurchaseOrderDetailScreen(order: orders[index]),
                    ),
                  );
                  if (result == true)
                    _refreshData(); // Refresh if detail screen causes an update
                },
                getStatusColor: _getStatusColor,
                capitalizeStatus: _capitalizeFirstLetter,
              ),
            ),
          ),
        ),
        _buildPaginationControls(total, pagination),
      ],
    );
  }

  Widget _buildPaginationControls(int total, PaginationState pagination) {
    final totalPages = (total / pagination.itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: pagination.currentPage > 1
                ? () => ref
                      .read(purchasePaginationProvider.notifier)
                      .previousPage()
                : null,
            child: const Text("Prev"),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text("${pagination.currentPage} / $totalPages"),
          ),
          ElevatedButton(
            onPressed: pagination.currentPage < totalPages
                ? () => ref.read(purchasePaginationProvider.notifier).nextPage()
                : null,
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() =>
      const Center(child: Text("No orders found for this selection."));
}

class PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrder order;
  final VoidCallback onTap;
  final Color Function(String) getStatusColor;
  final String Function(String) capitalizeStatus;

  const PurchaseOrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.getStatusColor,
    required this.capitalizeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMd().format(DateTime.parse(order.createdAt));
    final amount = 'TSh ${NumberFormat('#,##0').format(order.totalCost)}';
    final statusColor = getStatusColor(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.1),
                child: Icon(Icons.shopping_bag, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      order.supplier.name,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // RECTANGLE STATUS BUTTON
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(
                        4,
                      ), // Sharp rectangle edges
                    ),
                    child: Text(
                      // Use the capitalization function (kept from previous changes)
                      capitalizeStatus(order.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
