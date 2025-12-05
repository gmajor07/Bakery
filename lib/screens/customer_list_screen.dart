// lib/screens/customer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Adjust imports based on your project structure
import '../auth/auth_provider.dart';
import '../models/customer.dart';
import '../provider/customers_provider.dart'; // We will invalidate this
import '../provider/customer_search_provider.dart';
import '../theme.dart';
import '../widgets/token_error_widget.dart';
import 'customer_creation_screen.dart';

// Pagination providers (Reusable)
final paginationProvider = StateProvider<int>((ref) => 0);
final itemsPerPageProvider = StateProvider<int>((ref) => 10);

class CustomerScreen extends ConsumerStatefulWidget {
  const CustomerScreen({super.key});

  @override
  ConsumerState<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends ConsumerState<CustomerScreen> {
  late TextEditingController _searchController;
  String? _token;
  bool _isLoadingToken = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.text = ref.read(customerSearchQueryProvider);

    _searchController.addListener(() {
      ref.read(customerSearchQueryProvider.notifier).state =
          _searchController.text;
      // Reset to first page when search changes
      ref.read(paginationProvider.notifier).state = 0;
    });

    ref.read(authProvider.notifier).getAccessToken().then((value) {
      setState(() {
        _token = value;
        _isLoadingToken = false;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _nextPage(int totalItems, int itemsPerPage) {
    final currentPage = ref.read(paginationProvider);
    final totalPages = (totalItems / itemsPerPage).ceil();
    if (currentPage < totalPages - 1) {
      ref.read(paginationProvider.notifier).state = currentPage + 1;
    }
  }

  void _previousPage() {
    final currentPage = ref.read(paginationProvider);
    if (currentPage > 0) {
      ref.read(paginationProvider.notifier).state = currentPage - 1;
    }
  }

  // ⬅️ NEW: Pull-to-refresh logic
  Future<void> _handleRefresh() async {
    if (_token != null) {
      // Invalidate the specific instance of the FutureProvider being watched
      // This forces Riverpod to re-fetch the data.
      ref.invalidate(customersProvider(_token!));

      // Wait for the new data fetch to complete.
      // This makes the RefreshIndicator stay visible until loading is done.
      await ref.read(customersProvider(_token!).future);
    }
  }
  // --- Widget for Customer Card View (no changes needed here) ---
  Widget _buildCustomerCard(Customer customer, BuildContext context) {
    final statusColor = customer.status == 'active' ? Colors.brown : Colors.red;
    final isDefaultIcon = customer.isDefault
        ? Icon(Icons.star, color: AppTheme.primaryBrown, size: 18)
        : const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Name and Default Icon
            Row(
              children: [
                Text(
                  customer.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBrown,
                  ),
                ),
                const SizedBox(width: 8),
                isDefaultIcon,
              ],
            ),
            const SizedBox(height: 8),
            // Email and Phone
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Email', style: TextStyle(color: Colors.grey)),
                      Text(
                        customer.email,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Phone', style: TextStyle(color: Colors.grey)),
                      Text(customer.phone, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Credit Limit and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Credit Limit',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      'Tsh${customer.creditLimit.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Status', style: TextStyle(color: Colors.grey)),
                    Text(
                      customer.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // --- End of Customer Card Widget ---

  void _navigateToAddCustomer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CustomerCreationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(customerSearchQueryProvider).toLowerCase();
    final currentPage = ref.watch(paginationProvider);
    final itemsPerPage = ref.watch(itemsPerPageProvider);

    if (_isLoadingToken) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_token == null) {
      return const Scaffold(
        body: Center(child: Text('Token not found. Please log in again.')),
      );
    }

    final customersAsync = ref.watch(customersProvider(_token!));

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddCustomer(context),
        backgroundColor: AppTheme.primaryBrown,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: customersAsync.when(
        data: (customers) {
          // Filtering and Pagination logic remains the same...
          final filteredCustomers = customers.where((customer) {
            return customer.name.toLowerCase().contains(searchQuery) ||
                customer.email.toLowerCase().contains(searchQuery) ||
                customer.phone.contains(searchQuery);
          }).toList();

          final totalItems = filteredCustomers.length;
          final totalPages = (totalItems / itemsPerPage).ceil();
          final startIndex = currentPage * itemsPerPage;
          final endIndex = (startIndex + itemsPerPage) > totalItems
              ? totalItems
              : (startIndex + itemsPerPage);

          final paginatedCustomers = filteredCustomers.sublist(
            startIndex,
            endIndex,
          );

          // ⬅️ NEW: Use RefreshIndicator
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppTheme.primaryBrown, // Customize the spinner color
            // ⬅️ Replace SingleChildScrollView with ListView.builder + Header/Footer elements
            child: ListView.builder(
              itemCount: paginatedCustomers.length + 3, // +3 for search, info, and pagination controls
              itemBuilder: (context, index) {
                // 1. Search Bar (Header)
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search by name, email, or phone',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(customerSearchQueryProvider.notifier).state = '';
                          },
                        )
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                }

                // 2. Info Row (Header)
                if (index == 1) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${startIndex + 1}-${endIndex} of $totalItems customers',
                        ),
                        if (searchQuery.isNotEmpty)
                          Text('Filtered by: "$searchQuery"'),
                      ],
                    ),
                  );
                }

                // 3. Pagination Controls (Footer)
                if (index == paginatedCustomers.length + 2) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: currentPage > 0 ? _previousPage : null,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Previous'),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Page ${currentPage + 1} of $totalPages',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: currentPage < totalPages - 1
                              ? () => _nextPage(totalItems, itemsPerPage)
                              : null,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next'),
                        ),
                      ],
                    ),
                  );
                }

                // 4. Customer Cards (Main Content)
                final cardIndex = index - 2; // Subtract header items (0 and 1)
                final customer = paginatedCustomers[cardIndex];

                // Add padding above and below the list section for visual separation
                final hasListPadding = cardIndex == 0 ? const EdgeInsets.only(top: 16, left: 16, right: 16) : const EdgeInsets.symmetric(horizontal: 16);

                return Padding(
                  padding: hasListPadding,
                  child: _buildCustomerCard(customer, context),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) { // Added stack for better debugging
          final msg = error.toString().toLowerCase();
          if (msg.contains('401') ||
              msg.contains('unauthorized') ||
              msg.contains('token')) {
            return TokenErrorWidget();
          }
          return Center(child: Text('Error: $error'));
        },
      ),
    );
  }
}