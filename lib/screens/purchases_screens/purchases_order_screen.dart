import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/purchase_order.dart';
import '../../provider/purchase_orders_provider.dart';
import '../../provider/pagination_provider.dart';
import '../../widgets/token_error_widget.dart';
import 'create_purchase_order_screen.dart';
import 'purchase_order_detail_screen.dart';

// ----------------------------------------------------------------------
// 🚨 NEW: Quick Date Filter Definitions
// ----------------------------------------------------------------------
enum QuickDateFilter {
  all,
  today,
  yesterday,
  last7Days,
  thisMonth,
  lastMonth,
  custom,
} // ⭐️ ADDED: custom

class PurchaseOrdersScreen extends ConsumerStatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  ConsumerState<PurchaseOrdersScreen> createState() =>
      _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends ConsumerState<PurchaseOrdersScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Local state for client-side search/filter
  String searchQuery = '';
  // Local state for quick filter (used to control the chips)
  QuickDateFilter selectedQuickFilter = QuickDateFilter.today;

  // ⭐️ ADDED: Custom date range state for DateRangePicker
  DateTimeRange? customDateRange;

  // ⭐️ ADDED: Color for selected state in chips
  final Color lightBrownBackground = const Color(0xFFEEE3D7);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // Search listener logic (updates local state and Riverpod search query)
    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text.toLowerCase());
      ref.read(purchaseSearchQueryProvider.notifier).state = searchQuery;
      ref.read(purchasePaginationProvider.notifier).reset();
    });

    // 🎯 FIX: Schedule all provider updates to run after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Set initial date range/filters
      // This calls _applyQuickFilter, which updates the Riverpod provider
      _applyQuickFilter(QuickDateFilter.today);

      // 2. Initial data load (to fetch data based on the new filters)
      ref.invalidate(purchaseOrdersProvider);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final paginationState = ref.read(purchasePaginationProvider);
      if (paginationState.hasMore) {
        ref.read(purchasePaginationProvider.notifier).nextPage();
      }
    }
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
      customDateRange = null; // ⭐️ CLEARED: Custom range
    });

    // Clear Riverpod states
    ref.read(purchaseSearchQueryProvider.notifier).state = '';
    ref.read(selectedPurchaseStatusProvider.notifier).state = null;
    ref.read(selectedPurchaseDateRangeProvider.notifier).state = null;
    ref.read(purchasePaginationProvider.notifier).reset();
  }

  // ----------------------------------------------------------------------
  // Helper methods for Quick Filters
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

    // This updates the Riverpod state
    ref.read(selectedPurchaseDateRangeProvider.notifier).state =
        filter == QuickDateFilter.custom ? customRange : _getDateRange(filter);

    ref.read(purchasePaginationProvider.notifier).reset();
  }

  // ⭐️ ADDED: Date Range Picker Logic
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange:
          customDateRange ?? _getDateRange(QuickDateFilter.last7Days),
      helpText: 'Select Purchase Date Range',
      saveText: 'Apply',
    );

    if (picked != null) {
      // ⭐️ FIX: Normalize picked range to full day range (start of start day to end of end day)
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

  // ----------------------------------------------------------------------
  // Filtering and Pagination Methods - UNCHANGED
  // ----------------------------------------------------------------------
  List<PurchaseOrder> _applyFilters(List<PurchaseOrder> orders) {
    final selectedStatus = ref.watch(selectedPurchaseStatusProvider);
    final selectedRange = ref.watch(selectedPurchaseDateRangeProvider);

    // Debug: Print current filter state
    if (kDebugMode) {
      print(
        "🔄 Applying filters - Status: '$selectedStatus', Search: '$searchQuery', Date Range: $selectedRange",
      );
    }
    if (kDebugMode) {
      print("📊 Total orders before filtering: ${orders.length}");
    }

    return orders.where((order) {
      // 1. Search Filter - FIXED: Check if search query matches
      final matchesSearch =
          searchQuery.isEmpty ||
          order.supplier.name.toLowerCase().contains(searchQuery) ||
          order.id.toString().contains(searchQuery);

      // 2. Status Filter - FIXED: Handle null properly
      bool matchesStatus = true;
      if (selectedStatus != null && selectedStatus.isNotEmpty) {
        matchesStatus =
            order.status.toLowerCase() == selectedStatus.toLowerCase();
      }

      // 3. Date Filter
      bool matchesDate = true;
      if (selectedRange != null) {
        final orderDate = DateTime.parse(order.createdAt);
        // Normalize order date to start of the day for accurate comparison
        final startOfOrderDay = DateTime(
          orderDate.year,
          orderDate.month,
          orderDate.day,
        );
        // The selectedRange is already normalized (start of day to end of day)
        final startOfRangeDay = selectedRange.start;
        final endOfRangeDay = selectedRange.end;

        matchesDate =
            (startOfOrderDay.isAtSameMomentAs(startOfRangeDay) ||
                startOfOrderDay.isAfter(startOfRangeDay)) &&
            (startOfOrderDay.isAtSameMomentAs(endOfRangeDay) ||
                startOfOrderDay.isBefore(endOfRangeDay));
      }

      final shouldInclude = matchesSearch && matchesStatus && matchesDate;

      // Debug individual order filtering
      if (kDebugMode) {
        if (!matchesSearch && searchQuery.isNotEmpty) {
          print(
            "❌ EXCLUDING Order #${order.id} - Search: '${order.supplier.name}' doesn't match '$searchQuery'",
          );
        }
        if (!matchesStatus && selectedStatus != null) {
          print(
            "❌ EXCLUDING Order #${order.id} - Status: '${order.status}' doesn't match '$selectedStatus'",
          );
        }
        if (!matchesDate && selectedRange != null) {
          print(
            "❌ EXCLUDING Order #${order.id} - Date: ${order.createdAt} not in range",
          );
        }
        if (shouldInclude) {
          print(
            "✅ INCLUDING Order #${order.id} - Status: ${order.status}, Supplier: ${order.supplier.name}",
          );
        }
      }

      return shouldInclude;
    }).toList();
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

  // Helper method to get status color (kept as is)
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.brown;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'approved':
        return Colors.blue;
      case 'received':
        return Colors.brown.shade800;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get status background color (kept as is)
  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.shade50;
      case 'pending':
        return Colors.orange.shade50;
      case 'cancelled':
        return Colors.red.shade50;
      case 'approved':
        return Colors.blue.shade50;
      case 'received':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade50;
    }
  }

  // ----------------------------------------------------------------------
  // UI: Build method
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final asyncOrders = ref.watch(purchaseOrdersProvider);
    final paginationState = ref.watch(purchasePaginationProvider);
    final selectedRange = ref.watch(selectedPurchaseDateRangeProvider);
    final selectedStatus = ref.watch(selectedPurchaseStatusProvider);

    // Debug current state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) {
        print(
          "🎯 CURRENT FILTERS - Status: '$selectedStatus', Search: '$searchQuery', Date Range: $selectedRange",
        );
      }
    });

    final hasFilters =
        selectedRange != null ||
        searchQuery.isNotEmpty ||
        selectedStatus != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchase Orders"),
        actions: [
          if (hasFilters)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: 'Clear Filters',
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Filters Section ---
              _buildFiltersSection(context, selectedStatus),
              const SizedBox(height: 16),

              // --- Orders List Data ---
              Expanded(
                child: asyncOrders.when(
                  data: (allOrders) {
                    // 1. Apply Filters (Client-Side)
                    final filtered = _applyFilters(allOrders);

                    // 2. Apply Pagination (Client-Side)
                    final paginatedOrders = _applyPagination(
                      filtered,
                      paginationState,
                    );

                    return _buildOrdersList(
                      paginatedOrders,
                      filtered.length,
                      paginationState,
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) {
                    final msg = err.toString().toLowerCase();
                    if (msg.contains("token") || msg.contains("unauthorized")) {
                      return const TokenErrorWidget();
                    }
                    return Center(child: Text("Error: $err"));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreatePurchaseOrderScreen(),
            ),
          );
          if (result == true) {
            await _refreshData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // UI: Filters Section
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
                labelText: 'Search by supplier or order #',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => searchQuery = '');
                          ref.read(purchaseSearchQueryProvider.notifier).state =
                              '';
                          ref.read(purchasePaginationProvider.notifier).reset();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // ⭐️ ADDED/MODIFIED: Row for Date and Status Filters
            Row(
              children: [
                // Status Filter
                Expanded(child: _buildStatusFilter(selectedStatus)),
                const SizedBox(width: 8),

                // Date Picker Button
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

  // ⭐️ MODIFIED: Status Filter
  Widget _buildStatusFilter(String? selected) {
    const statuses = [
      null,
      "pending",
      "approved",
      "cancelled",
      "completed",
      "received",
    ];

    return DropdownButtonFormField<String?>(
      value: selected,
      decoration: const InputDecoration(
        labelText: "Status",
        border: OutlineInputBorder(),
        // contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0), // Removed vertical padding fix height issue
      ),
      isExpanded: true,
      items: statuses
          .map(
            (s) => DropdownMenuItem(value: s, child: Text(s ?? "All Status")),
          )
          .toList(),
      onChanged: (value) {
        if (kDebugMode) {
          print("🎯 Status dropdown changed from '$selected' to '$value'");
        }
        ref.read(selectedPurchaseStatusProvider.notifier).state = value;
        ref.read(purchasePaginationProvider.notifier).reset();

        // Force a rebuild to see if filter is applied
        setState(() {});
      },
    );
  }

  // ⭐️ MODIFIED: Date Filter Chips (with new selection logic and color)
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
              // ⭐️ FIX: Use primaryColor/onPrimary for selected chip color
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
  // UI: List View and Card Builder - UPDATED with Pull-to-Refresh
  // ----------------------------------------------------------------------

  Widget _buildOrdersList(
    List<PurchaseOrder> orders,
    int totalFiltered,
    PaginationState pagination,
  ) {
    if (orders.isEmpty) {
      final hasFilters =
          ref.watch(selectedPurchaseDateRangeProvider) != null ||
          searchQuery.isNotEmpty ||
          ref.watch(selectedPurchaseStatusProvider) != null;
      return _buildEmptyState(hasFilters);
    }

    return Column(
      children: [
        _buildPaginationInfo(totalFiltered, pagination),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              controller: _scrollController,
              physics:
                  const AlwaysScrollableScrollPhysics(), // ✅ FIX: Enables pull-to-refresh
              itemCount: orders.length + (pagination.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == orders.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final order = orders[index];
                return PurchaseOrderCard(
                  order: order,
                  // ⭐️ MODIFIED: onTap now handles navigation
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PurchaseOrderDetailScreen(order: order),
                      ),
                    );
                  },
                  getStatusColor: _getStatusColor,
                  getStatusBackgroundColor: _getStatusBackgroundColor,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationInfo(int totalFiltered, PaginationState pagination) {
    final startItem =
        (pagination.currentPage - 1) * pagination.itemsPerPage + 1;
    final endItem = pagination.currentPage * pagination.itemsPerPage;
    final displayedEnd = endItem > totalFiltered ? totalFiltered : endItem;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing $startItem-$displayedEnd of $totalFiltered orders',
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
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No purchase orders found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hasFilters
                        ? 'Try clearing your filters or using different search terms.'
                        : 'Pull down to refresh and load purchase orders.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (hasFilters)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear all filters'),
                      onPressed: _clearFilters,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Purchase Order Card Widget (List View Item)
// ----------------------------------------------------------------------

typedef GetStatusColor = Color Function(String status);

class PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrder order;
  // ⭐️ MODIFIED: Renamed onViewDetails to onTap
  final VoidCallback onTap;
  final GetStatusColor getStatusColor;
  final GetStatusColor getStatusBackgroundColor;

  const PurchaseOrderCard({
    super.key,
    required this.order,
    // ⭐️ MODIFIED: Renamed onViewDetails to onTap
    required this.onTap,
    required this.getStatusColor,
    required this.getStatusBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMd().add_Hm().format(
      DateTime.parse(order.createdAt),
    );
    final formattedAmount =
        'TSh ${NumberFormat('#,##0').format(order.totalCost)}'; // Use proper formatting
    // final isPending = order.status.toLowerCase() == 'pending';
    // final isApproved = order.status.toLowerCase() == 'approved';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      // ⭐️ MODIFIED: Use InkWell/GestureDetector on the Card for full tap
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_cart_checkout,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subtitle (Expanded to take available space)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      order.supplier.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedAmount,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing Status Badge
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: getStatusBackgroundColor(order.status),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: getStatusColor(order.status),
                    width: 1,
                  ),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    color: getStatusColor(order.status),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              // ⭐️ REMOVED: Redundant IconButton for View Details and Receive Goods (Use onTap)
            ],
          ),
        ),
      ),
    );
  }
}
