// lib/screens/expense_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/expense.dart';
// Assuming these imports are correct based on your previous code structure
import '../../provider/expense_provider.dart';
import '../../provider/pagination_provider.dart';
import '../provider/pagination_provider_ex.dart';
import '../widgets/token_error_widget.dart';
import 'create_expense_screen.dart'; // Screen to add a new expense

/// 🎯 Date filters
enum QuickDateFilter {
  all,
  thisMonth,
  lastMonth,
  last7Days,
  today,
  yesterday,
  custom,
}

class ExpensesScreen extends ConsumerStatefulWidget {
  final int selectedIndex;
  final Function(int) onNavItemTapped;

  const ExpensesScreen({
    super.key,
    required this.selectedIndex,
    required this.onNavItemTapped,
  });

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String searchQuery = '';
  // Initialize filter to 'Today' to show today's expenses by default
  QuickDateFilter selectedQuickFilter = QuickDateFilter.today;
  DateTimeRange? customDateRange;

  final Color _brownColor = Colors.brown.shade400;
  // 🎯 FIX: Corrected the type from DateFormat to NumberFormat
  final NumberFormat _moneyFormatter = NumberFormat('#,##0');

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text.toLowerCase());
      ref.read(expenseSearchQueryProvider.notifier).state = searchQuery;
      ref.read(expensesPaginationProvider.notifier).reset();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Re-apply filter on screen load to ensure Riverpod state is correct and triggers the fetch
      _applyQuickFilter(QuickDateFilter.today);
      ref.invalidate(expensesProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    ref.invalidate(expensesProvider);
    ref.read(expensesPaginationProvider.notifier).reset();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      searchQuery = '';
      // Reset filter to 'All Time'
      selectedQuickFilter = QuickDateFilter.all;
      customDateRange = null;
    });

    ref.read(expenseSearchQueryProvider.notifier).state = '';
    ref.read(selectedExpenseCategoryProvider.notifier).state = null;
    ref.read(selectedExpenseDateRangeProvider.notifier).state = null;
    ref.read(expensesPaginationProvider.notifier).reset();
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange:
          customDateRange ??
          _getDateRange(selectedQuickFilter) ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      helpText: 'Select Expense Date Range',
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

  void _applyQuickFilter(QuickDateFilter filter, [DateTimeRange? range]) {
    if (filter == QuickDateFilter.custom && range == null) {
      _selectCustomDateRange();
      return;
    }

    setState(() {
      selectedQuickFilter = filter;
      customDateRange = filter == QuickDateFilter.custom ? range : null;
    });

    ref.read(selectedExpenseDateRangeProvider.notifier).state =
        filter == QuickDateFilter.custom ? range : _getDateRange(filter);

    ref.read(expensesPaginationProvider.notifier).reset();
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
        final y = today.subtract(const Duration(days: 1));
        return DateTimeRange(
          start: y,
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
        final first = DateTime(now.year, now.month - 1, 1);
        final last = DateTime(now.year, now.month, 0, 23, 59, 59);
        return DateTimeRange(start: first, end: last);
      case QuickDateFilter.custom:
        return customDateRange;
    }
  }

  String _filterLabel(QuickDateFilter f) {
    switch (f) {
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
        return 'Custom Range';
    }
  }

  String _cap(String s) => s[0].toUpperCase() + s.substring(1).toLowerCase();

  List<Expense> _applyFilters(List<Expense> expenses) {
    final categoryId = ref.watch(selectedExpenseCategoryProvider);
    final range = ref.watch(selectedExpenseDateRangeProvider);

    // Note: The API should handle search and date range filtering. This client-side filter
    // only needs to handle category if it's not handled by the API on the client side.
    // However, since we are using a simplified pagination/search, we keep client-side date/category filter here.

    return expenses.where((e) {
      final matchSearch =
          searchQuery.isEmpty ||
          e.category.name.toLowerCase().contains(searchQuery) ||
          e.notes.toLowerCase().contains(searchQuery) ||
          e.id.toString().contains(searchQuery);

      final matchCategory = categoryId == null || e.category.id == categoryId;

      // Note: We are now relying on the API to handle the date range,
      // but if the API returns ALL data regardless of date range, this filter is necessary.
      // Keeping it here for robustness with client-side filters.
      bool matchDate = true;
      if (range != null) {
        final d = DateTime.parse(e.date);
        matchDate =
            d.isAfter(range.start.subtract(const Duration(seconds: 1))) &&
            d.isBefore(range.end.add(const Duration(seconds: 1)));
      }

      return matchSearch && matchCategory && matchDate;
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green.shade700;
      case 'pending':
        return Colors.orange.shade800;
      case 'cancelled':
        return Colors.red.shade700;
      case 'completed':
        return Colors.brown.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncExpenses = ref.watch(expensesProvider);
    final pagination = ref.watch(expensesPaginationProvider);

    final hasFilters =
        searchQuery.isNotEmpty ||
        ref.watch(selectedExpenseCategoryProvider) != null ||
        selectedQuickFilter !=
            QuickDateFilter.today; // Check if filters are active

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (hasFilters)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: 'Clear Filters',
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateExpenseScreen()),
          );
          if (res == true) _refreshData();
        },
        tooltip: 'Add New Expense',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: const _LiftedFloatingActionButtonLocation(),
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            child: Column(
              children: [
                _buildFilters(),
                const SizedBox(height: 16),
                Expanded(
                  child: asyncExpenses.when(
                    data: (all) {
                      final filtered = _applyFilters(all);
                      final paged = _paginate(filtered, pagination);
                      return _buildList(paged, filtered.length, pagination);
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) {
                      final msg = error.toString().toLowerCase();
                      if (msg.contains('401') ||
                          msg.contains('unauthorized') ||
                          msg.contains('token') ||
                          msg.contains('valid') ||
                          msg.contains('expired')) {
                        return const TokenErrorWidget();
                      }
                      return Center(child: Text('Error: ${error.toString()}'));
                    },
                  ),
                ),
              ],
            ),
          ),

          // Bottom navigation menu
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavigation(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final textOnPrimary = colorScheme.onPrimary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          height: 65,
          child: Row(
            children: [
              // Home
              Expanded(
                child: _buildNavItem(
                  icon: LucideIcons.home,
                  label: 'Home',
                  index: 0,
                  isSelected: widget.selectedIndex == 0,
                  textOnPrimary: textOnPrimary,
                ),
              ),
              // Payments
              Expanded(
                child: _buildNavItem(
                  icon: LucideIcons.badgeInfo,
                  label: 'Payments',
                  index: 1,
                  isSelected: widget.selectedIndex == 1,
                  textOnPrimary: textOnPrimary,
                ),
              ),
              // Purchases
              Expanded(
                child: _buildNavItem(
                  icon: LucideIcons.shoppingCart,
                  label: 'Purchases',
                  index: 2,
                  isSelected: widget.selectedIndex == 2,
                  textOnPrimary: textOnPrimary,
                ),
              ),
              // Inventory
              Expanded(
                child: _buildNavItem(
                  icon: LucideIcons.box,
                  label: 'Inventory',
                  index: 3,
                  isSelected: widget.selectedIndex == 3,
                  textOnPrimary: textOnPrimary,
                ),
              ),
              // Expenses
              Expanded(
                child: _buildNavItem(
                  icon: LucideIcons.printer,
                  label: 'Expenses',
                  index: 4,
                  isSelected: widget.selectedIndex == 4,
                  textOnPrimary: textOnPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    required Color textOnPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onNavItemTapped(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? textOnPrimary
                  : textOnPrimary.withOpacity(0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? textOnPrimary
                    : textOnPrimary.withOpacity(0.5),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Expense> _paginate(List<Expense> list, PaginationState p) {
    final start = (p.currentPage - 1) * p.itemsPerPage;
    final end = (start + p.itemsPerPage).clamp(0, list.length);
    return start >= list.length ? [] : list.sublist(start, end);
  }

  Widget _buildFilters() {
    final selectedCategoryId = ref.watch(selectedExpenseCategoryProvider);
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final isCustomSelected = selectedQuickFilter == QuickDateFilter.custom;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search expenses, category or notes',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            categoriesAsync.when(
              data: (categories) => DropdownButtonFormField<int?>(
                value: selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ...categories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }),
                ],
                onChanged: (v) {
                  ref.read(selectedExpenseCategoryProvider.notifier).state = v;
                  ref.read(expensesPaginationProvider.notifier).reset();
                },
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error loading categories: $e'),
            ),
            const SizedBox(height: 8),
            // Date Quick Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: QuickDateFilter.values.map((f) {
                  final selected = f == selectedQuickFilter;
                  final label = _filterLabel(f);

                  // Custom Range Chip (Styled as a chip)
                  if (f == QuickDateFilter.custom) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        avatar: Icon(
                          Icons.date_range,
                          size: 20,
                          color: isCustomSelected
                              ? primaryColor
                              : Colors.grey[700],
                        ),
                        label: Text(label),
                        side: BorderSide(
                          color: isCustomSelected
                              ? primaryColor
                              : Colors.grey.shade300,
                        ),
                        backgroundColor: isCustomSelected
                            ? primaryColor.withOpacity(0.15)
                            : Colors.transparent,
                        labelStyle: TextStyle(
                          color: isCustomSelected
                              ? primaryColor
                              : Colors.grey[700],
                          fontWeight: isCustomSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        onPressed: _selectCustomDateRange,
                      ),
                    );
                  }

                  // Regular Date Filter Chips
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      selectedColor: primaryColor.withOpacity(0.15),
                      checkmarkColor: primaryColor,
                      labelStyle: TextStyle(
                        color: selected ? primaryColor : Colors.grey[700],
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      onSelected: (_) => _applyQuickFilter(f),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Expense> expenses, int total, PaginationState p) {
    if (expenses.isEmpty) {
      return const Center(child: Text('No expenses found'));
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (_, i) => ExpenseCard(
                expense: expenses[i],
                statusColor: _statusColor,
                cap: _cap,
                // ❌ ACTION REMOVED: onTap is set to null, preventing navigation to a detail screen.
                onTap: null,
              ),
            ),
          ),
        ),
        _pagination(total, p),
      ],
    );
  }

  Widget _pagination(int total, PaginationState p) {
    final pages = (total / p.itemsPerPage).ceil();
    if (pages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: p.currentPage > 1
                ? () => ref
                      .read(expensesPaginationProvider.notifier)
                      .previousPage()
                : null,
            child: const Text('Prev'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Page ${p.currentPage} / $pages'),
          ),
          ElevatedButton(
            onPressed: p.currentPage < pages
                ? () => ref.read(expensesPaginationProvider.notifier).nextPage()
                : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  // ❌ MODIFIED: onTap is nullable, allowing null to be passed (no tap action)
  final VoidCallback? onTap;
  final Color Function(String) statusColor;
  final String Function(String) cap;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap, // Make onTap optional
    required this.statusColor,
    required this.cap,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMd().format(DateTime.parse(expense.date));
    final amount = 'TSh ${NumberFormat('#,##0').format(expense.amount)}';
    final statusColor = this.statusColor(expense.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: ListTile(
        onTap: onTap, // Will be null, thus non-interactive
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(Icons.receipt, color: statusColor),
        ),
        title: Text(
          'Expense #${expense.id}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${expense.category.name}\n$date',
          style: TextStyle(color: Colors.grey[700]),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              amount,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                cap(expense.status),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom FAB location to lift it above the custom bottom navigation menu
class _LiftedFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const _LiftedFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Standard endFloat position
    final Offset standardOffset =
        FloatingActionButtonLocation.endFloat.getOffset(scaffoldGeometry);
    // Lift it up by 70 pixels to clear the custom navigation bar (which is 65 + 16 margin)
    return Offset(standardOffset.dx, standardOffset.dy - 70);
  }
}
