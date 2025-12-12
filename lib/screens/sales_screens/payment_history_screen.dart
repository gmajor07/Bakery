import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/payment_record.dart';
import '../../provider/payment_provider.dart';
import '../../widgets/token_error_widget.dart';

// ----------------------------------------------------------------------
// 1. DATE FILTER DEFINITIONS
// ----------------------------------------------------------------------
enum QuickDateFilter { all, today, yesterday, last7Days, thisMonth, custom }

// ----------------------------------------------------------------------
// 2. PAGINATION PROVIDER (NO CHANGES NEEDED HERE)
// ----------------------------------------------------------------------
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

// ----------------------------------------------------------------------
// 3. WIDGET STATE AND METHODS
// ----------------------------------------------------------------------
class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  // Removed _scrollController and _scrollListener for button-based pagination
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  // ⭐️ NEW STATE for Quick Date Filter
  QuickDateFilter selectedQuickFilter = QuickDateFilter.all;
  DateTimeRange? selectedRange;

  @override
  void initState() {
    super.initState();
    // Removed scroll listener
    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text.toLowerCase());
      ref.read(paymentPaginationProvider.notifier).reset();
    });

    // Set initial filter on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyQuickFilter(QuickDateFilter.all);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ⭐️ NEW: Date Filter Logic (Similar to ProductionScreen)
  void _applyQuickFilter(QuickDateFilter filter, [DateTimeRange? customRange]) {
    final newRange = filter == QuickDateFilter.custom ? customRange : _getDateRange(filter);

    setState(() {
      selectedQuickFilter = filter;
      // Normalizing the end date for filtering purposes: setting time to 23:59:59
      if (newRange != null) {
        selectedRange = DateTimeRange(
          start: DateTime(newRange.start.year, newRange.start.month, newRange.start.day),
          end: DateTime(newRange.end.year, newRange.end.month, newRange.end.day)
              .add(const Duration(days: 1))
              .subtract(const Duration(seconds: 1)),
        );
      } else {
        selectedRange = null;
      }
    });
    ref.read(paymentPaginationProvider.notifier).reset();
  }

  DateTimeRange? _getDateRange(QuickDateFilter filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (filter) {
      case QuickDateFilter.all:
        return null;
      case QuickDateFilter.today:
        return DateTimeRange(start: today, end: today);
      case QuickDateFilter.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return DateTimeRange(start: yesterday, end: yesterday);
      case QuickDateFilter.last7Days:
        final lastWeek = today.subtract(const Duration(days: 6));
        return DateTimeRange(start: lastWeek, end: today);
      case QuickDateFilter.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: startOfMonth, end: today);
      case QuickDateFilter.custom:
        return selectedRange;
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
      case QuickDateFilter.custom:
        if (selectedRange != null) {
          final start = DateFormat('MMM d').format(selectedRange!.start);
          final end = DateFormat('MMM d').format(selectedRange!.end);
          return '$start - $end';
        }
        return 'Custom Range';
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      searchQuery = '';
    });
    _applyQuickFilter(QuickDateFilter.all);
    // Pagination reset is handled by _applyQuickFilter
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
            _buildFiltersSection(), // ⭐️ MODIFIED
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

  // ⭐️ MODIFIED: Filter Section for Date Chips and Date Picker
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
            _buildQuickDateFilters(),
          ],
        ),
      ),
    );
  }

  // ⭐️ NEW: Quick Date Filter Chips
  Widget _buildQuickDateFilters() {
    const filters = [
      QuickDateFilter.all,
      QuickDateFilter.today,
      QuickDateFilter.yesterday,
      QuickDateFilter.last7Days,
      QuickDateFilter.thisMonth,
      QuickDateFilter.custom,
    ];

    final primaryColor = Theme.of(context).colorScheme.primary;
    final navBarContainerColor = Theme.of(context).colorScheme.brightness == Brightness.dark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : const Color(0xFFEEE3D7);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // ⭐️ Custom Date Range Picker Button
          SizedBox(
            width: 50,
            height: 40,
            child: ElevatedButton(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(now.year - 5),
                  lastDate: DateTime(now.year + 1),
                  initialDateRange: selectedRange,
                );
                if (picked != null) {
                  _applyQuickFilter(QuickDateFilter.custom, picked);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Icon(Icons.date_range),
            ),
          ),
          const SizedBox(width: 8),
          // ⭐️ Filter Chips
          ...filters.map((filter) {
            final isSelected = filter == selectedQuickFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(_getFilterName(filter)),
                selected: isSelected,
                selectedColor: navBarContainerColor,
                checkmarkColor: primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? primaryColor : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (filter == QuickDateFilter.custom) {
                    // Open picker if custom is selected but not currently active
                    if (!isSelected) {
                      _selectCustomDateRange();
                    }
                  } else if (selected) {
                    _applyQuickFilter(filter);
                  } else if (filter == selectedQuickFilter) {
                    // Allow deselection back to 'All'
                    _applyQuickFilter(QuickDateFilter.all);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: selectedRange,
    );
    if (picked != null) {
      _applyQuickFilter(QuickDateFilter.custom, picked);
    }
  }


  Widget _buildSummaryCards(
      AsyncValue<List<PaymentRecord>> historyAsync,
      BuildContext context,
      ) {
    // ... (Summary card logic remains the same)
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
            Colors.brown,
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
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
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
              (payment.paymentDate.isAfter(selectedRange!.start) &&
                  payment.paymentDate.isBefore(selectedRange!.end));

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
      // Use Future.microtask to avoid calling setState during build/layout
      Future.microtask(() {
        ref.read(paymentPaginationProvider.notifier).setHasMore(hasMore);
      });
    }

    return payments.sublist(
      startIndex,
      endIndex < payments.length ? endIndex : payments.length,
    );
  }

  // ⭐️ MODIFIED: Build list without scroll listener
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
            // Removed controller
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return _buildPaymentCard(payment);
            },
          ),
        ),
        _buildPaginationControls(totalFiltered, pagination), // ⭐️ NEW CONTROLS
      ],
    );
  }

  // ⭐️ NEW: Pagination Controls (Next/Previous Buttons)
  Widget _buildPaginationControls(
      int totalFiltered,
      PaymentPaginationState pagination,
      ) {
    final totalPages = (totalFiltered / pagination.itemsPerPage).ceil();
    final isFirstPage = pagination.currentPage == 1;
    final isLastPage = pagination.currentPage >= totalPages;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            label: const Text('Previous'),
            onPressed: isFirstPage
                ? null
                : () => ref.read(paymentPaginationProvider.notifier).previousPage(),
          ),
          const SizedBox(width: 16),
          Text(
            'Page ${pagination.currentPage} of $totalPages',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            icon: const Text('Next'),
            label: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: isLastPage || totalPages == 0
                ? null
                : () => ref.read(paymentPaginationProvider.notifier).nextPage(),
          ),
        ],
      ),
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
        // Removed second page display, as it's now in the controls
      ],
    );
  }

  Widget _buildPaymentCard(PaymentRecord payment) {
    // ... (Payment card logic remains the same)
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.payment, color: Theme.of(context).colorScheme.primary, size: 20),
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
                  color: Colors.brown,
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
    // ... (Detail dialog logic remains the same)
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
    // ... (Detail row logic remains the same)
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
    // ... (Error state logic remains the same)
    final msg = error.toString().toLowerCase();
    if (msg.contains('token') ||
        msg.contains('401') ||
        msg.contains('unauthorized')) {
      return const TokenErrorWidget();
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