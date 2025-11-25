import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/payment_record.dart';
import '../../provider/payment_provider.dart';
import '../../widgets/token_error_widget.dart';

final paymentPaginationProvider =
    StateNotifierProvider<PaymentPaginationNotifier, PaymentPaginationState>(
      (ref) => PaymentPaginationNotifier(),
    );

class PaymentPaginationState {
  final int currentPage;
  final int itemsPerPage;
  final bool hasMore;

  PaymentPaginationState({
    this.currentPage = 1,
    this.itemsPerPage = 15,
    this.hasMore = true,
  });

  PaymentPaginationState copyWith({
    int? currentPage,
    int? itemsPerPage,
    bool? hasMore,
  }) {
    return PaymentPaginationState(
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class PaymentPaginationNotifier extends StateNotifier<PaymentPaginationState> {
  PaymentPaginationNotifier() : super(PaymentPaginationState());

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
    state = PaymentPaginationState();
  }
}

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
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
      ref.read(paymentPaginationProvider.notifier).reset();
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
      final paginationState = ref.read(paymentPaginationProvider);
      if (paginationState.hasMore) {
        ref.read(paymentPaginationProvider.notifier).nextPage();
      }
    }
  }

  void _clearFilters() {
    setState(() {
      selectedRange = null;
      _searchController.clear();
      searchQuery = '';
    });
    ref.read(paymentPaginationProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(paymentHistoryProvider);
    final paginationState = ref.watch(paymentPaginationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
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
            _buildFiltersSection(),
            const SizedBox(height: 16),
            _buildSummaryCards(historyAsync, context),
            const SizedBox(height: 16),
            Expanded(
              child: historyAsync.when(
                data: (allPayments) {
                  final filtered = _applyFilters(allPayments);
                  final paginatedPayments = _applyPagination(
                    filtered,
                    paginationState,
                  );

                  return _buildPaymentList(
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
                          ref.read(paymentPaginationProvider.notifier).reset();
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
                        ref.read(paymentPaginationProvider.notifier).reset();
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
                      ref.read(paymentPaginationProvider.notifier).reset();
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
    AsyncValue<List<PaymentRecord>> historyAsync,
    BuildContext context,
  ) {
    return historyAsync.when(
      data: (payments) {
        final filtered = _applyFilters(payments);
        final totalAmount = filtered.fold<double>(
          0,
          (sum, payment) => sum + payment.amount,
        );
        final averageAmount = filtered.isEmpty
            ? 0
            : totalAmount / filtered.length;

        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth > 600;

        final cards = [
          _buildSummaryCard(
            'Total Payments',
            filtered.length.toString(),
            Icons.payments,
            Colors.blue,
          ),
          _buildSummaryCard(
            'Total Amount',
            'TSh ${NumberFormat('#,##0').format(totalAmount)}',
            Icons.attach_money,
            Colors.green,
          ),
          _buildSummaryCard(
            'Average',
            'TSh ${NumberFormat('#,##0').format(averageAmount)}',
            Icons.trending_up,
            Colors.orange,
          ),
        ];

        return isTablet
            ? GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                physics: const NeverScrollableScrollPhysics(),
                children: cards,
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: cards
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SizedBox(width: 180, child: c),
                        ),
                      )
                      .toList(),
                ),
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
          mainAxisAlignment: MainAxisAlignment.center,
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

  List<PaymentRecord> _applyFilters(List<PaymentRecord> payments) {
    return payments.where((payment) {
      final matchesSearch =
          payment.receiptNumber.toString().toLowerCase().contains(
            searchQuery,
          ) ||
          payment.customerName.toLowerCase().contains(searchQuery);

      final matchesDate =
          selectedRange == null ||
          (payment.paymentDate.isAfter(
                selectedRange!.start.subtract(const Duration(days: 1)),
              ) &&
              payment.paymentDate.isBefore(
                selectedRange!.end.add(const Duration(days: 1)),
              ));
      return matchesSearch && matchesDate;
    }).toList();
  }

  List<PaymentRecord> _applyPagination(
    List<PaymentRecord> payments,
    PaymentPaginationState pagination,
  ) {
    final startIndex = (pagination.currentPage - 1) * pagination.itemsPerPage;
    final endIndex = startIndex + pagination.itemsPerPage;

    final hasMore = endIndex < payments.length;
    if (hasMore != pagination.hasMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(paymentPaginationProvider.notifier).setHasMore(hasMore);
      });
    }

    return payments.sublist(
      startIndex,
      endIndex < payments.length ? endIndex : payments.length,
    );
  }

  Widget _buildPaymentList(
    List<PaymentRecord> payments,
    int totalFiltered,
    PaymentPaginationState pagination,
  ) {
    if (payments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payments, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No payments found', style: TextStyle(fontSize: 16)),
            Text(
              'Try adjusting your filters',
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
              return _buildPaymentCard(payment);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationInfo(
    int totalFiltered,
    PaymentPaginationState pagination,
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

  Widget _buildPaymentCard(PaymentRecord payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.brown.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.payment, color: Colors.brown, size: 20),
        ),
        title: Text(
          'Receipt #${payment.receiptNumber}',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              payment.customerName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              DateFormat('MMM dd, yyyy').format(payment.paymentDate),
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
            if (payment.notes != null && payment.notes!.isNotEmpty)
              Text(
                payment.notes!,
                style: TextStyle(color: Colors.blue[600], fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: SizedBox(
          width: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TSh ${NumberFormat('#,##0').format(payment.amount)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 13,
                ),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Sale #${payment.saleId}',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        onTap: () => _showPaymentDetails(context, payment),
      ),
    );
  }

  void _showPaymentDetails(BuildContext context, PaymentRecord payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                'Receipt Number',
                payment.receiptNumber.toString(),
              ),
              _buildDetailRow('Sale ID', payment.saleId.toString()),
              _buildDetailRow('Customer', payment.customerName),
              _buildDetailRow(
                'Amount',
                'TSh ${NumberFormat('#,##0').format(payment.amount)}',
              ),
              _buildDetailRow(
                'Payment Date',
                DateFormat('MMM dd, yyyy - HH:mm').format(payment.paymentDate),
              ),
              if (payment.notes != null && payment.notes!.isNotEmpty)
                _buildDetailRow('Notes', payment.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, BuildContext context) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('token') ||
        msg.contains('401') ||
        msg.contains('unauthorized')) {
      return TokenErrorWidget();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load payment history',
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
            onPressed: () => ref.invalidate(paymentHistoryProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
