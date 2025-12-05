import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../provider/material_received_provider.dart';
import '../widgets/token_error_widget.dart';
import 'material_received_details_screen.dart'; // Ensure this path is correct

// ----------------------------------------------------------------------
// DATE FILTER DEFINITIONS (Matching other screens)
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

  // ⭐️ NEW STATE: Control for the quick filter chips
  QuickDateFilter _selectedQuickFilter = QuickDateFilter.all;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(materialFiltersProvider);
    _searchController.text = filters.search ?? '';

    // Initialize the quick filter state based on current provider filters
    _updateQuickFilterState(filters.startDate, filters.endDate);
  }

  void _updateQuickFilterState(String? startDateStr, String? endDateStr) {
    if (startDateStr == null || endDateStr == null) {
      _selectedQuickFilter = QuickDateFilter.all;
    } else {
      // Assuming if dates are set, it's either from a quick filter or custom
      _selectedQuickFilter = QuickDateFilter.custom;
    }
  }

  // ⭐️ MODIFIED: Now triggers filter update using the QuickDateFilter enum
  void _pickDateRange({DateTimeRange? initialRange}) async {
    final now = DateTime.now();
    final filters = ref.read(materialFiltersProvider);
    DateTimeRange? currentRange;
    if (filters.startDate != null && filters.endDate != null) {
      currentRange = DateTimeRange(
        start: DateTime.parse(filters.startDate!),
        end: DateTime.parse(filters.endDate!).add(const Duration(seconds: 1)).subtract(const Duration(days: 1)),
      );
    }

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initialRange ?? currentRange,
    );

    if (picked != null) {
      _applyQuickFilter(QuickDateFilter.custom, picked);
    }
  }

  void _clearDateRange() {
    _applyQuickFilter(QuickDateFilter.all);
  }

  void _applyQuickFilter(QuickDateFilter filter, [DateTimeRange? customRange]) {
    final newRange = filter == QuickDateFilter.custom ? customRange : _getDateRange(filter);

    setState(() {
      _selectedQuickFilter = filter;
    });

    if (newRange == null) {
      ref.read(materialFiltersProvider.notifier).update(
            (s) => s.copyWith(startDate: null, endDate: null, page: 1),
      );
    } else {
      // Normalize dates: start time 00:00:00, end time 23:59:59
      final start = DateTime(newRange.start.year, newRange.start.month, newRange.start.day);
      final end = DateTime(newRange.end.year, newRange.end.month, newRange.end.day)
          .add(const Duration(days: 1))
          .subtract(const Duration(seconds: 1));

      ref.read(materialFiltersProvider.notifier).update(
            (s) => s.copyWith(
          startDate: start.toIso8601String(),
          endDate: end.toIso8601String(),
          page: 1,
        ),
      );
    }
  }

  DateTimeRange? _getDateRange(QuickDateFilter filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (filter) {
      case QuickDateFilter.all:
        return null;
      case QuickDateFilter.today:
        return DateTimeRange(start: today, end: today);
      case QuickDateFilter.last7Days:
        final lastWeek = today.subtract(const Duration(days: 6));
        return DateTimeRange(start: lastWeek, end: today);
      case QuickDateFilter.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: startOfMonth, end: today);
      case QuickDateFilter.custom:
        return null;
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
        return 'Custom Range';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ⭐️ materialsProvider now returns List<dynamic> (List<MaterialReceipt>)
    final filters = ref.watch(materialFiltersProvider);
    final receiptsAsync = ref.watch(materialsProvider);
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Materials Received'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Date Filter
            _buildFiltersSection(filters, isTablet),

            // Results count
            _buildResultsCount(receiptsAsync, filters),

            // Table or List
            Expanded(
              child: receiptsAsync.when(
                data: (receipts) {
                  if (receipts.isEmpty) {
                    return _buildEmptyState();
                  }

                  return isTablet
                      ? _buildTableView(receipts)
                      : _buildMobileView(receipts);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => _buildErrorWidget(err),
              ),
            ),

            // Pagination
            _buildPagination(filters),
          ],
        ),
      ),
    );
  }

  // ⭐️ MODIFIED: Filters section now includes quick date chips
  Widget _buildFiltersSection(MaterialFilters filters, bool isTablet) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isTablet) _buildTabletFilters(filters),
            if (!isTablet) _buildMobileFilters(filters),

            const SizedBox(height: 12),
            _buildQuickDateFilters(filters),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateFilters(MaterialFilters filters) {
    const filterOptions = [
      QuickDateFilter.all,
      QuickDateFilter.today,
      QuickDateFilter.last7Days,
      QuickDateFilter.thisMonth,
      QuickDateFilter.custom,
    ];

    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Custom Date Range Picker Button
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
            final isSelected = filter == _selectedQuickFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(
                  filter == QuickDateFilter.custom && filters.startDate != null
                      ? '${DateFormat('MMM d').format(DateTime.parse(filters.startDate!))} - ${DateFormat('MMM d').format(DateTime.parse(filters.endDate!))}'
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
                    if (!isSelected) _pickDateRange();
                  } else if (selected) {
                    _applyQuickFilter(filter);
                  } else if (filter == _selectedQuickFilter) {
                    _applyQuickFilter(QuickDateFilter.all);
                  }
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTabletFilters(MaterialFilters filters) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search receipts...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  ref
                      .read(materialFiltersProvider.notifier)
                      .update((s) => s.copyWith(search: '', page: 1));
                },
              )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              ref
                  .read(materialFiltersProvider.notifier)
                  .update((s) => s.copyWith(search: value, page: 1));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFilters(MaterialFilters filters) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search receipts...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref
                    .read(materialFiltersProvider.notifier)
                    .update((s) => s.copyWith(search: '', page: 1));
              },
            )
                : null,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) {
            ref
                .read(materialFiltersProvider.notifier)
                .update((s) => s.copyWith(search: value, page: 1));
          },
        ),
      ],
    );
  }

  // ⭐️ MODIFIED: Displays current page info using totalRecords from filters
  Widget _buildResultsCount(AsyncValue<List<dynamic>> receiptsAsync, MaterialFilters filters) {
    return receiptsAsync.when(
      data: (receipts) {
        final totalPages = (filters.totalRecords / filters.limit).ceil();

        if (filters.totalRecords == 0 && receipts.isEmpty) return const SizedBox();

        final startItem = (filters.page - 1) * filters.limit + 1;
        final endItem = (filters.page - 1) * filters.limit + receipts.length;
        final displayedEnd = endItem > filters.totalRecords ? filters.totalRecords : endItem;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing $startItem-$displayedEnd of ${filters.totalRecords} receipt${filters.totalRecords != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              if (filters.totalRecords > filters.limit)
                Text(
                  'Page ${filters.page} of $totalPages',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
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

  Widget _buildTableView(List<dynamic> receipts) {
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
            DataColumn(label: Text('Order #', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Supplier', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Received By', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: receipts.map((r) {
            final dateStr = DateFormat('dd/MM/yyyy').format(r.receivedDate);

            return DataRow(
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined),
                    tooltip: 'View details',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // Ensure MaterialDetailsScreen is correctly defined elsewhere
                          builder: (_) => MaterialDetailsScreen(receiptId: r.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileView(List<dynamic> receipts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        final r = receipts[index];
        final dateStr = DateFormat('dd/MM/yyyy').format(r.receivedDate);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                _buildMobileDetailRow('Total', NumberFormat('#,##0').format(r.total)),
                _buildMobileDetailRow('Received By', r.receivedBy),

                // View button
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MaterialDetailsScreen(receiptId: r.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 36),
                    ),
                  ),
                ),
              ],
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

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No receipts found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or date range',
            style: TextStyle(color: Colors.grey),
          ),
        ],
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
            'Error loading receipts',
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

  // ⭐️ MODIFIED: Fully functional pagination controls
  Widget _buildPagination(MaterialFilters filters) {
    final totalPages = (filters.totalRecords / filters.limit).ceil();
    final isLastPage = filters.page >= totalPages && totalPages > 0;
    final isFirstPage = filters.page <= 1;

    if (filters.totalRecords <= filters.limit && filters.totalRecords > 0) {
      return const SizedBox.shrink();
    }

    if (filters.totalRecords == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              label: const Text('Previous'),
              onPressed: isFirstPage
                  ? null
                  : () => ref
                  .read(materialFiltersProvider.notifier)
                  .update((s) => s.copyWith(page: s.page - 1)),
            ),
            Text(
              'Page ${filters.page} of $totalPages',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              label: const Text('Next'),
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: isLastPage
                  ? null
                  : () => ref
                  .read(materialFiltersProvider.notifier)
                  .update((s) => s.copyWith(page: s.page + 1)),
            ),
          ],
        ),
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