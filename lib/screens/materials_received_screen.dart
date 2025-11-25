import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../provider/material_received_provider.dart';
import '../widgets/token_error_widget.dart';
import 'material_received_details_screen.dart';

class MaterialsReceivedScreen extends ConsumerStatefulWidget {
  const MaterialsReceivedScreen({super.key});

  @override
  ConsumerState<MaterialsReceivedScreen> createState() =>
      _MaterialsReceivedScreenState();
}

class _MaterialsReceivedScreenState
    extends ConsumerState<MaterialsReceivedScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final filters = ref.read(materialFiltersProvider);
    _searchController.text = filters.search ?? '';
  }

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      ref
          .read(materialFiltersProvider.notifier)
          .update(
            (s) => s.copyWith(
          startDate: picked.start.toIso8601String(),
          endDate: picked.end.toIso8601String(),
          page: 1,
        ),
      );
    }
  }

  void _clearDateRange() {
    ref
        .read(materialFiltersProvider.notifier)
        .update(
          (s) => s.copyWith(
        startDate: null,
        endDate: null,
        page: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            _buildResultsCount(receiptsAsync),

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

            // Date range display
            if (filters.startDate != null && filters.endDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(DateTime.parse(filters.startDate!))} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(filters.endDate!))}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: _clearDateRange,
                      tooltip: 'Clear date range',
                    ),
                  ],
                ),
              ),
          ],
        ),
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
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _pickDateRange,
          icon: const Icon(Icons.calendar_today),
          label: const Text('Date Range'),
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
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _pickDateRange,
          icon: const Icon(Icons.calendar_today),
          label: const Text('Date Range'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsCount(AsyncValue<List<dynamic>> receiptsAsync) {
    return receiptsAsync.when(
      data: (receipts) {
        if (receipts.isEmpty) return const SizedBox();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${receipts.length} receipt${receipts.length != 1 ? 's' : ''} found',
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
      return TokenErrorWidget();
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

  Widget _buildPagination(MaterialFilters filters) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: filters.page > 1
                  ? () => ref
                  .read(materialFiltersProvider.notifier)
                  .update((s) => s.copyWith(page: s.page - 1))
                  : null,
              child: const Text('Previous'),
            ),
            Text(
              'Page ${filters.page}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: () => ref
                  .read(materialFiltersProvider.notifier)
                  .update((s) => s.copyWith(page: s.page + 1)),
              child: const Text('Next'),
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