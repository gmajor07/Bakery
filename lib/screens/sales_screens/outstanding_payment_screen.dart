import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/outstanding_payment.dart';
import '../../provider/payment_provider.dart';
import '../../widgets/token_error_widget.dart';

// Pagination provider for outstanding payments
final outstandingPaginationProvider =
    StateNotifierProvider<
      OutstandingPaginationNotifier,
      OutstandingPaginationState
    >((ref) {
      return OutstandingPaginationNotifier();
    });

class OutstandingPaginationState {
  final int currentPage;
  final int itemsPerPage;
  final bool hasMore;

  OutstandingPaginationState({
    this.currentPage = 1,
    this.itemsPerPage = 15,
    this.hasMore = true,
  });

  OutstandingPaginationState copyWith({
    int? currentPage,
    int? itemsPerPage,
    bool? hasMore,
  }) {
    return OutstandingPaginationState(
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class OutstandingPaginationNotifier
    extends StateNotifier<OutstandingPaginationState> {
  OutstandingPaginationNotifier() : super(OutstandingPaginationState());

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
    state = OutstandingPaginationState();
  }
}

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
    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text.toLowerCase());
      ref.read(outstandingPaginationProvider.notifier).reset();
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
      final paginationState = ref.read(outstandingPaginationProvider);
      if (paginationState.hasMore) {
        ref.read(outstandingPaginationProvider.notifier).nextPage();
      }
    }
  }

  void _clearFilters() {
    setState(() {
      selectedRange = null;
      _searchController.clear();
      searchQuery = '';
    });
    ref.read(outstandingPaginationProvider.notifier).reset();
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 Search + 📅 Date Range
            _buildFiltersSection(),
            const SizedBox(height: 16),

            // 📊 Summary Cards
            _buildSummaryCards(outstandingAsync),
            const SizedBox(height: 16),

            // 📋 Outstanding Payments List
            Expanded(
              child: outstandingAsync.when(
                data: (allOutstanding) {
                  final filtered = _applyFilters(allOutstanding);
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => _buildErrorState(err, context),
              ),
            ),
          ],
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
            // Search Field
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

            // Date Range and Clear Filters
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
        final filtered = _applyFilters(payments);
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
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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

    // Update hasMore state
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
        // Pagination Info
        _buildPaginationInfo(totalFiltered, pagination),
        const SizedBox(height: 12),

        // Outstanding Payments List
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

        // Bottom Pagination Controls
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
          'Showing $startItem-$displayedEnd of $totalFiltered outstanding',
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
        title: Text('Receipt #${payment.receiptNumber}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(payment.customer),
            const SizedBox(height: 4),
            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: progress == 1 ? Colors.green : Colors.orange,
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
              DateFormat('MMM dd, yyyy').format(payment.dueDate),
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
        onTap: () {
          _showPaymentDetails(context, payment);
        },
      ),
    );
  }

  void _showPaymentDetails(BuildContext context, OutstandingPayment payment) {
    final isOverdue = payment.dueDate.isBefore(DateTime.now());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Outstanding Payment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'Receipt Number',
                payment.receiptNumber.toString(),
              ),
              _buildDetailRow('Sale ID', payment.saleId.toString()),
              _buildDetailRow('Customer', payment.customer),
              _buildDetailRow(
                'Total Amount',
                'TSh ${NumberFormat('#,##0').format(payment.totalAmount)}',
              ),
              _buildDetailRow(
                'Paid Amount',
                'TSh ${NumberFormat('#,##0').format(payment.paidAmount)}',
              ),
              _buildDetailRow(
                'Outstanding Balance',
                'TSh ${NumberFormat('#,##0').format(payment.balance)}',
              ),
              _buildDetailRow(
                'Due Date',
                DateFormat('MMM dd, yyyy').format(payment.dueDate),
                valueColor: isOverdue ? Colors.red : null,
              ),
              if (isOverdue)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        'This payment is overdue',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement record payment functionality
              _recordPayment(context, payment);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text(
              'Record Payment',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _recordPayment(BuildContext context, OutstandingPayment payment) {
    // TODO: Implement payment recording functionality
    // This would navigate to a payment recording screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Record payment for Receipt #${payment.receiptNumber}'),
        action: SnackBarAction(
          label: 'Proceed',
          onPressed: () {
            // Navigate to payment recording screen
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: TextStyle(color: valueColor)),
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
