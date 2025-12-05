import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/outstanding_payment.dart';
import '../../provider/outstanding_payments_provider.dart';
import '../../provider/payment_provider.dart';
import '../../widgets/token_error_widget.dart';
import 'outstanding_payment_details_screen.dart'; // New page

// ----------------------------------------------------------------------
// 1. DATE FILTER DEFINITIONS
// ----------------------------------------------------------------------
enum QuickDateFilter { all, today, last7Days, thisMonth, custom }

class OutstandingPaymentsScreen extends ConsumerStatefulWidget {
  const OutstandingPaymentsScreen({super.key});

  @override
  ConsumerState<OutstandingPaymentsScreen> createState() =>
      _OutstandingPaymentsScreenState();
}

class _OutstandingPaymentsScreenState
    extends ConsumerState<OutstandingPaymentsScreen> {
  // Removed _scrollController for button-based pagination
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  // ⭐️ NEW STATE for Quick Date Filter
  QuickDateFilter selectedQuickFilter = QuickDateFilter.all;
  DateTimeRange? selectedRange;

  @override
  void initState() {
    super.initState();
    // Removed scroll listener
    _searchController.addListener(_onSearchChanged);

    // Set initial filter on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyQuickFilter(QuickDateFilter.all);
    });
  }

  @override
  void dispose() {
    // Removed _scrollController.dispose()
    _searchController.dispose();
    super.dispose();
  }

  // Removed _scrollListener()

  void _onSearchChanged() {
    setState(() => searchQuery = _searchController.text.toLowerCase());
    ref.read(outstandingPaginationProvider.notifier).reset();
  }

  // ⭐️ NEW: Date Filter Logic
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
    ref.read(outstandingPaginationProvider.notifier).reset();
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
        return selectedRange;
    }
  }

  String _getFilterName(QuickDateFilter filter) {
    switch (filter) {
      case QuickDateFilter.all:
        return 'All Time';
      case QuickDateFilter.today:
        return 'Due Today';
      case QuickDateFilter.last7Days:
        return 'Next 7 Days';
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

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: selectedRange,
    );
    if (picked != null) {
      _applyQuickFilter(QuickDateFilter.custom, picked);
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
              _buildFiltersSection(), // ⭐️ MODIFIED
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

  // ⭐️ MODIFIED: Filter Section for Search and Date Chips
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
            _buildQuickDateFilters(), // ⭐️ NEW: Date Chips
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
              onPressed: _selectCustomDateRange,
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
          }).toList(),
        ],
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

  List<OutstandingPayment> _applyFilters(List<OutstandingPayment> payments) {
    return payments.where((payment) {
      final matchesSearch =
          payment.receiptNumber.toString().contains(searchQuery) ||
              payment.customer.toLowerCase().contains(searchQuery);

      // Filter by due date
      bool matchesDate = true;
      if (selectedRange != null) {
        final startOfRange = selectedRange!.start;
        final endOfRange = selectedRange!.end;

        // Match payments whose due date is within the selected range (inclusive)
        matchesDate =
            (payment.dueDate.isAtSameMomentAs(startOfRange) || payment.dueDate.isAfter(startOfRange)) &&
                (payment.dueDate.isAtSameMomentAs(endOfRange) || payment.dueDate.isBefore(endOfRange));
      }

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
      Future.microtask(() {
        ref.read(outstandingPaginationProvider.notifier).setHasMore(hasMore);
      });
    }

    return payments.sublist(
      startIndex,
      endIndex < payments.length ? endIndex : payments.length,
    );
  }

  // ⭐️ MODIFIED: Build list for button-based pagination
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
              'Try adjusting filters or checking due dates',
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
              return _buildOutstandingCard(payment);
            },
          ),
        ),
        // ⭐️ ADDED: Pagination controls are now displayed here
        _buildPaginationControls(totalFiltered, pagination),
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
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              color: Colors.orange,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Paid: TSh ${NumberFormat('#,##0').format(payment.paidAmount)}',
                  style: TextStyle(fontSize: 12, color: Colors.brown[600]),
                ),
                const Spacer(),
                Text(
                  'Total: TSh ${NumberFormat('#,##0').format(payment.totalAmount)}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
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
                color: isOverdue ? Colors.red : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12,
                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isOverdue)
              const Text(
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
      mainAxisAlignment: MainAxisAlignment.start, // Align left for better flow
      children: [
        Text(
          'Showing $startItem-$displayedEnd of $totalFiltered payments',
          style: TextStyle(color: Colors.grey[600]),
        ),
        // Removed second page display
      ],
    );
  }

  // ⭐️ MODIFIED: Next/Previous buttons
  Widget _buildPaginationControls(
      int totalFiltered,
      OutstandingPaginationState pagination,
      ) {
    final totalPages = (totalFiltered / pagination.itemsPerPage).ceil();
    final isFirstPage = pagination.currentPage == 1;
    final isLastPage = pagination.currentPage >= totalPages;

    if (totalFiltered <= pagination.itemsPerPage) {
      return const SizedBox.shrink(); // Hide controls if only one page
    }

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
                : () => ref
                .read(outstandingPaginationProvider.notifier)
                .previousPage(),
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
            label: const Text('Next'),
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            // Use isLastPage check
            onPressed: isLastPage
                ? null
                : () => ref
                .read(outstandingPaginationProvider.notifier)
                .nextPage(),
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
      return const TokenErrorWidget();
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