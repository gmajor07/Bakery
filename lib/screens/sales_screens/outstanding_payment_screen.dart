import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/outstanding_payment.dart';
import '../../provider/outstanding_payments_provider.dart';
import '../../provider/payment_provider.dart';
import '../../widgets/token_error_widget.dart';
import 'outstanding_payment_details_screen.dart'; // New page

class OutstandingPaymentsScreen extends ConsumerStatefulWidget {
  const OutstandingPaymentsScreen({super.key});

  @override
  ConsumerState<OutstandingPaymentsScreen> createState() =>
      _OutstandingPaymentsScreenState();
}

class _OutstandingPaymentsScreenState
    extends ConsumerState<OutstandingPaymentsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  DateTimeRange? selectedRange;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_onSearchChanged);
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
      final paginationState = ref.read(outstandingPaginationProvider);
      if (paginationState.hasMore) {
        ref.read(outstandingPaginationProvider.notifier).nextPage();
      }
    }
  }

  void _onSearchChanged() {
    setState(() => searchQuery = _searchController.text.toLowerCase());
    ref.read(outstandingPaginationProvider.notifier).reset();
  }

  void _clearFilters() {
    setState(() {
      selectedRange = null;
      _searchController.clear();
      searchQuery = '';
    });
    ref.read(outstandingPaginationProvider.notifier).reset();
  }

  void _navigateToPaymentDetails(OutstandingPayment payment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OutstandingPaymentDetailsScreen(payment: payment),
      ),
    ).then((_) {
      // Refresh data when returning from details screen
      ref.invalidate(outstandingPaymentsProvider);
    });
  }

  Future<void> _refreshData() async {
    ref.invalidate(outstandingPaymentsProvider);
    ref.read(outstandingPaginationProvider.notifier).reset();
    await ref.read(outstandingPaymentsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final outstandingAsync = ref.watch(outstandingPaymentsProvider);
    final paginationState = ref.watch(outstandingPaginationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Outstanding Payments'),
        actions: [
          if (selectedRange != null || searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: 'Clear Filters',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Filters Section
              _buildFiltersSection(),
              const SizedBox(height: 16),

              // Summary Cards
              _buildSummaryCards(outstandingAsync),
              const SizedBox(height: 16),

              // Payments List
              Expanded(
                child: outstandingAsync.when(
                  data: (allOutstanding) {
                    // Filter out paid payments first, then apply other filters
                    final unpaidPayments = allOutstanding
                        .where((payment) => payment.balance > 0)
                        .toList();
                    final filtered = _applyFilters(unpaidPayments);
                    final paginatedPayments = _applyPagination(
                      filtered,
                      paginationState,
                    );
                    return _buildOutstandingList(
                      paginatedPayments,
                      filtered.length,
                      paginationState,
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => _buildErrorState(err, context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by receipt # or customer',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => searchQuery = '');
                          ref
                              .read(outstandingPaginationProvider.notifier)
                              .reset();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      selectedRange == null
                          ? 'Filter by due date'
                          : '${DateFormat('MMM dd').format(selectedRange!.start)} - ${DateFormat('MMM dd, yyyy').format(selectedRange!.end)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 1),
                        initialDateRange: selectedRange,
                      );
                      if (picked != null) {
                        setState(() => selectedRange = picked);
                        ref
                            .read(outstandingPaginationProvider.notifier)
                            .reset();
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
                      ref.read(outstandingPaginationProvider.notifier).reset();
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

  Widget _buildSummaryCards(
    AsyncValue<List<OutstandingPayment>> outstandingAsync,
  ) {
    return outstandingAsync.when(
      data: (payments) {
        // Filter out paid payments first, then apply other filters
        final unpaidPayments = payments
            .where((payment) => payment.balance > 0)
            .toList();
        final filtered = _applyFilters(unpaidPayments);
        final totalOutstanding = filtered.fold<double>(
          0,
          (sum, payment) => sum + payment.balance,
        );
        final totalCustomers = <String>{};
        final overduePayments = filtered
            .where((p) => p.dueDate.isBefore(DateTime.now()))
            .length;

        for (final payment in filtered) {
          totalCustomers.add(payment.customer);
        }

        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Outstanding',
                'TSh ${NumberFormat('#,##0').format(totalOutstanding)}',
                Icons.money_off,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Customers',
                totalCustomers.length.toString(),
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Overdue',
                overduePayments.toString(),
                Icons.warning,
                Colors.red,
              ),
            ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  List<OutstandingPayment> _applyFilters(List<OutstandingPayment> payments) {
    return payments.where((payment) {
      final matchesSearch =
          payment.receiptNumber.toString().contains(searchQuery) ||
          payment.customer.toLowerCase().contains(searchQuery);

      final matchesDate =
          selectedRange == null ||
          (payment.dueDate.isAfter(
                selectedRange!.start.subtract(const Duration(days: 1)),
              ) &&
              payment.dueDate.isBefore(
                selectedRange!.end.add(const Duration(days: 1)),
              ));

      return matchesSearch && matchesDate;
    }).toList();
  }

  List<OutstandingPayment> _applyPagination(
    List<OutstandingPayment> payments,
    OutstandingPaginationState pagination,
  ) {
    final startIndex = (pagination.currentPage - 1) * pagination.itemsPerPage;
    final endIndex = startIndex + pagination.itemsPerPage;

    final hasMore = endIndex < payments.length;
    if (hasMore != pagination.hasMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(outstandingPaginationProvider.notifier).setHasMore(hasMore);
      });
    }

    return payments.sublist(
      startIndex,
      endIndex < payments.length ? endIndex : payments.length,
    );
  }

  Widget _buildOutstandingList(
    List<OutstandingPayment> payments,
    int totalFiltered,
    OutstandingPaginationState pagination,
  ) {
    if (payments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_score, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No outstanding payments', style: TextStyle(fontSize: 16)),
            Text(
              'All payments are settled',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildPaginationInfo(totalFiltered, pagination),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: payments.length + (pagination.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == payments.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final payment = payments[index];
              return _buildOutstandingCard(payment);
            },
          ),
        ),
        if (totalFiltered > pagination.itemsPerPage)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: _buildPaginationControls(totalFiltered, pagination),
          ),
      ],
    );
  }

  Widget _buildOutstandingCard(OutstandingPayment payment) {
    final isOverdue = payment.dueDate.isBefore(DateTime.now());
    final progress = payment.paidAmount / payment.totalAmount;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isOverdue
                ? Colors.red.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isOverdue ? Icons.warning : Icons.pending,
            color: isOverdue ? Colors.red : Colors.orange,
          ),
        ),
        title: Text(
          'Receipt #${payment.receiptNumber}',
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(payment.customer, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: Colors.orange,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Paid: TSh ${NumberFormat('#,##0').format(payment.paidAmount)}',
                  style: TextStyle(fontSize: 12, color: Colors.green[600]),
                ),
                const Spacer(),
                Text(
                  'Total: TSh ${NumberFormat('#,##0').format(payment.totalAmount)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'TSh ${NumberFormat('#,##0').format(payment.balance)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isOverdue ? Colors.red : Colors.orange,
              ),
            ),
            Text(
              DateFormat('MMM dd').format(payment.dueDate),
              style: TextStyle(
                color: isOverdue ? Colors.red : Colors.grey[600],
                fontSize: 12,
                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isOverdue)
              Text(
                'OVERDUE',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        onTap: () => _navigateToPaymentDetails(payment),
      ),
    );
  }

  Widget _buildPaginationInfo(
    int totalFiltered,
    OutstandingPaginationState pagination,
  ) {
    final startItem =
        (pagination.currentPage - 1) * pagination.itemsPerPage + 1;
    final endItem = pagination.currentPage * pagination.itemsPerPage;
    final displayedEnd = endItem > totalFiltered ? totalFiltered : endItem;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing $startItem-$displayedEnd of $totalFiltered payments',
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

  Widget _buildPaginationControls(
    int totalFiltered,
    OutstandingPaginationState pagination,
  ) {
    final totalPages = (totalFiltered / pagination.itemsPerPage).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: pagination.currentPage > 1
              ? () => ref
                    .read(outstandingPaginationProvider.notifier)
                    .previousPage()
              : null,
        ),
        Text('Page ${pagination.currentPage} of $totalPages'),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: pagination.hasMore
              ? () =>
                    ref.read(outstandingPaginationProvider.notifier).nextPage()
              : null,
        ),
      ],
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
            'Failed to load outstanding payments',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(outstandingPaymentsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
