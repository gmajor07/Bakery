import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/material_received.dart';
import '../../provider/material_received_provider.dart';
import '../../widgets/token_error_widget.dart';
import 'material_received_details_screen.dart';

// ----------------------------------------------------------------------
// DATE FILTER DEFINITIONS (Matching purchase orders screen)
// ----------------------------------------------------------------------
enum QuickDateFilter { all, today, last7Days, thisMonth, custom }

class MaterialsReceivedScreen extends ConsumerStatefulWidget {
  const MaterialsReceivedScreen({super.key});

  @override
  ConsumerState<MaterialsReceivedScreen> createState() =>
      _MaterialsReceivedScreenState();
}

class _MaterialsReceivedScreenState
    extends ConsumerState<MaterialsReceivedScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Local state for client-side search/filter (like purchase orders)
  String searchQuery = '';
  QuickDateFilter selectedQuickFilter = QuickDateFilter.all;
  DateTimeRange? customDateRange;

  @override
  void initState() {
    super.initState();

    // Search listener logic (updates local state and Riverpod search query)
    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text.toLowerCase());
      ref.read(materialSearchQueryProvider.notifier).state = searchQuery;
    });

    // Schedule provider updates after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyQuickFilter(QuickDateFilter.all);
      ref.invalidate(materialsProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    ref.invalidate(materialsProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      searchQuery = '';
      selectedQuickFilter = QuickDateFilter.all;
      customDateRange = null;
    });

    // Clear Riverpod states
    ref.read(materialSearchQueryProvider.notifier).state = '';
    ref.read(selectedMaterialStatusProvider.notifier).state = null;
    ref.read(selectedMaterialDateRangeProvider.notifier).state = null;
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

    // Update Riverpod state
    ref.read(selectedMaterialDateRangeProvider.notifier).state =
    filter == QuickDateFilter.custom ? customRange : _getDateRange(filter);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange:
      customDateRange ??
          _getDateRange(QuickDateFilter.all),
      helpText: 'Select Date Range',
      saveText: 'Apply',
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
        ).add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
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
      case QuickDateFilter.last7Days:
        final lastWeek = today.subtract(const Duration(days: 6));
        return DateTimeRange(start: lastWeek, end: endOfToday);
      case QuickDateFilter.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: startOfMonth, end: endOfToday);
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
      case QuickDateFilter.last7Days:
        return 'Last 7 Days';
      case QuickDateFilter.thisMonth:
        return 'This Month';
      case QuickDateFilter.custom:
        if (customDateRange != null) {
          final start = DateFormat('MMM d').format(customDateRange!.start);
          final end = DateFormat('MMM d').format(customDateRange!.end);
          return '$start - $end';
        }
        return 'Custom Range';
    }
  }

  // Client-side filtering (like purchase orders)
  List<MaterialReceipt> _applyFilters(List<MaterialReceipt> receipts) {
    final selectedStatus = ref.watch(selectedMaterialStatusProvider);
    final selectedRange = ref.watch(selectedMaterialDateRangeProvider);

    return receipts.where((receipt) {
      // Search filter
      final matchesSearch =
          searchQuery.isEmpty ||
              receipt.supplierName.toLowerCase().contains(searchQuery) ||
              receipt.purchaseOrderId.toString().contains(searchQuery);

      // Status filter
      bool matchesStatus = true;
      if (selectedStatus != null && selectedStatus.isNotEmpty) {
        matchesStatus =
            receipt.status.toLowerCase() == selectedStatus.toLowerCase();
      }

      // Date filter
      bool matchesDate = true;
      if (selectedRange != null) {
        final receiptDate = DateTime.parse(receipt.receivedDate.toString());
        final startOfReceiptDay = DateTime(
          receiptDate.year,
          receiptDate.month,
          receiptDate.day,
        );
        final startOfRangeDay = selectedRange.start;
        final endOfRangeDay = selectedRange.end;

        matchesDate =
            (startOfReceiptDay.isAtSameMomentAs(startOfRangeDay) ||
                startOfReceiptDay.isAfter(startOfRangeDay)) &&
                (startOfReceiptDay.isAtSameMomentAs(endOfRangeDay) ||
                    startOfReceiptDay.isBefore(endOfRangeDay));
      }

      return matchesSearch && matchesStatus && matchesDate;
    }).toList();
  }

  // ⭐️ NEW: Navigation function
  void _navigateToDetails(BuildContext context, int receiptId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaterialDetailsScreen(receiptId: receiptId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncReceipts = ref.watch(materialsProvider);
    final selectedRange = ref.watch(selectedMaterialDateRangeProvider);
    final selectedStatus = ref.watch(selectedMaterialStatusProvider);

    final hasFilters =
        selectedRange != null ||
            searchQuery.isNotEmpty ||
            selectedStatus != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Received'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
              // Filters Section
              _buildFiltersSection(context, selectedStatus),
              const SizedBox(height: 16),

              // Receipts List Data
              Expanded(
                child: asyncReceipts.when(
                  data: (allReceipts) {
                    final filtered = _applyFilters(allReceipts);

                    if (filtered.isEmpty) {
                      return _buildEmptyState(hasFilters);
                    }

                    return _buildReceiptsList(filtered);
                  },
                  loading: () =>
                  const Center(child: CircularProgressIndicator()),
                  error: (err, _) => _buildErrorWidget(err),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                labelText: 'Search by order# or supplier',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => searchQuery = '');
                    ref.read(materialSearchQueryProvider.notifier).state =
                    '';
                  },
                )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Row for Status and Date Picker
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

            // Quick Date Filter Chips
            _buildQuickDateFilters(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter(String? selected) {
    const statuses = [null, "pending", "completed", "cancelled"];

    return DropdownButtonFormField<String?>(
      value: selected,
      decoration: const InputDecoration(
        labelText: "Status",
        border: OutlineInputBorder(),
      ),
      isExpanded: true,
      items: statuses
          .map(
            (s) => DropdownMenuItem(
          value: s,
          child: Text(
            s == null ? "All Status" : s[0].toUpperCase() + s.substring(1),
          ),
        ),
      )
          .toList(),
      onChanged: (value) {
        ref.read(selectedMaterialStatusProvider.notifier).state = value;
      },
    );
  }

  Widget _buildQuickDateFilters() {
    const filters = [
      QuickDateFilter.all,
      QuickDateFilter.today,
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
              selectedColor: primaryColor.withOpacity(0.15),
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
                  _applyQuickFilter(QuickDateFilter.all);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReceiptsList(List<MaterialReceipt> receipts) {
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: isTablet ? _buildTableView(receipts) : _buildMobileView(receipts),
    );
  }

  Widget _buildTableView(List<MaterialReceipt> receipts) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: DataTable(
          headingRowColor: WidgetStateColor.resolveWith(
                (states) => Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          ),
          columns: const [
            DataColumn(
              label: Text(
                'Order #',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Supplier',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Received By',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // ❌ REMOVED: Actions Column
          ],
          rows: receipts.map((r) {
            final dateStr = DateFormat('dd/MM/yyyy').format(r.receivedDate);

            return DataRow(
              // ⭐️ NEW: Add onTap behavior to the whole row
              onSelectChanged: (_) => _navigateToDetails(context, r.id),
              cells: [
                DataCell(Text(r.purchaseOrderId.toString())),
                DataCell(Text(dateStr)),
                DataCell(
                  Tooltip(
                    message: r.supplierName,
                    child: Text(
                      r.supplierName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                DataCell(Text(NumberFormat('#,##0').format(r.total))),
                DataCell(Text(r.receivedBy)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(r.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(r.status)),
                    ),
                    child: Text(
                      r.status,
                      style: TextStyle(
                        color: _getStatusColor(r.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // ❌ REMOVED: Actions DataCell
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileView(List<MaterialReceipt> receipts) {
    return ListView.builder(
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        final r = receipts[index];
        final dateStr = DateFormat('dd/MM/yyyy').format(r.receivedDate);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          // ⭐️ NEW: Wrap Card content in InkWell for tap functionality
          child: InkWell(
            onTap: () => _navigateToDetails(context, r.id),
            borderRadius: BorderRadius.circular(12), // Match Card's default rounding
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with order number and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${r.purchaseOrderId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(r.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getStatusColor(r.status)),
                        ),
                        child: Text(
                          r.status,
                          style: TextStyle(
                            color: _getStatusColor(r.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Receipt details
                  _buildMobileDetailRow('Date', dateStr),
                  _buildMobileDetailRow('Supplier', r.supplierName),
                  _buildMobileDetailRow(
                    'Total',
                    NumberFormat('#,##0').format(r.total),
                  ),
                  _buildMobileDetailRow('Received By', r.receivedBy),

                  // ⭐️ REPLACED BUTTON: Use a trailing arrow icon instead
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),

                  // ❌ REMOVED: View button
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ... (Other helper widgets remain unchanged)

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
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No materials received found',
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
                        : 'Pull down to refresh and load materials received.',
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
          const Text(
            'Error loading materials received',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            onPressed: () => ref.invalidate(materialsProvider),
          ),
        ],
      ),
    );
  }

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
}