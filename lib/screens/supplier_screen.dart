import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Adjust imports based on your project structure
import '../auth/auth_provider.dart';
import '../models/supplier_model.dart';
import '../provider/supplier_search_provider.dart';
import '../provider/suppliers_provider.dart';
import '../theme.dart';
import '../widgets/token_error_widget.dart';
// ⬇️ Ensure this file and class are created!
import 'supplier_creation_screen.dart';

// Assuming these are correctly defined StateProviders:
final paginationProvider = StateProvider<int>((ref) => 0);
final itemsPerPageProvider = StateProvider<int>((ref) => 10);

class SupplierScreen extends ConsumerStatefulWidget {
  const SupplierScreen({super.key});

  @override
  ConsumerState<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends ConsumerState<SupplierScreen> {
  late TextEditingController _searchController;
  String? _token;
  bool _isLoadingToken = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.text = ref.read(supplierSearchQueryProvider);

    _searchController.addListener(() {
      ref.read(supplierSearchQueryProvider.notifier).state =
          _searchController.text;
      // ⬅️ Ensure correct StateProvider usage
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
    final currentPage = ref
        .read(paginationProvider.notifier)
        .state; // Correct state access
    final totalPages = (totalItems / itemsPerPage).ceil();
    if (currentPage < totalPages - 1) {
      ref.read(paginationProvider.notifier).state = currentPage + 1;
    }
  }

  void _previousPage() {
    final currentPage = ref
        .read(paginationProvider.notifier)
        .state; // Correct state access
    if (currentPage > 0) {
      ref.read(paginationProvider.notifier).state = currentPage - 1;
    }
  }

  Future<void> _handleRefresh() async {
    if (_token != null) {
      // ⬅️ Cleaner way to force a refetch and wait for it
      ref.invalidate(suppliersProvider(_token!));
      await ref.read(suppliersProvider(_token!).future);
    }
  }

  void _navigateToAddSupplier(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const SupplierCreationScreen(), // ⬅️ Now resolved by creating the file
      ),
    );
  }

  // --- Widget for Supplier Card View (UPDATED for status capitalization) ---
  Widget _buildSupplierCard(Supplier supplier, BuildContext context) {
    // 1. Capitalize the first letter of the status for display
    String displayStatus = supplier.status.isNotEmpty
        ? supplier.status[0].toUpperCase() + supplier.status.substring(1)
        : '—'; // Handle empty status case

    final statusIsActive = supplier.status.toLowerCase() == 'active';
    final statusColor = statusIsActive ? Colors.brown : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  supplier.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBrown,
                  ),
                ),
                Text(
                  displayStatus, // ⬅️ Use the capitalized status here
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Contact Info
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Email', style: TextStyle(color: Colors.grey)),
                      Text(
                        supplier.email,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 8),
                      // Renamed 'Phone' label to 'Contact Info' to match model
                      const Text(
                        'Contact Info',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(supplier.contactInfo),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Address',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        supplier.address,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // --- End of Supplier Card Widget ---

  @override
  Widget build(BuildContext context) {
    // ⬅️ Correct state access: watch the state value, not the provider object
    final searchQuery = ref.watch(supplierSearchQueryProvider);
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

    final suppliersAsync = ref.watch(suppliersProvider(_token!));

    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddSupplier(context),
        backgroundColor: AppTheme.primaryBrown,
        child: const Icon(Icons.group_add, color: Colors.white),
      ),
      body: suppliersAsync.when(
        data: (suppliers) {
          // Filtering logic
          final filteredSuppliers = suppliers.where((supplier) {
            return supplier.name.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                supplier.email.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                supplier.contactInfo.contains(searchQuery);
          }).toList();

          // Pagination calculations
          final totalItems = filteredSuppliers.length;
          final totalPages = (totalItems / itemsPerPage).ceil();
          final startIndex = currentPage * itemsPerPage;
          final endIndex = (startIndex + itemsPerPage) > totalItems
              ? totalItems
              : (startIndex + itemsPerPage);

          final paginatedSuppliers = filteredSuppliers.sublist(
            startIndex,
            endIndex,
          );

          // Use RefreshIndicator wrapping the ListView
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppTheme.primaryBrown,
            child: ListView.builder(
              itemCount: paginatedSuppliers.length + 3,
              itemBuilder: (context, index) {
                // ... (rest of the ListView.builder logic remains the same)

                // 1. Search Bar (Header)
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        // Updated search label to reflect contactInfo change
                        labelText: 'Search by name, email, or contact info',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                          .read(
                                            supplierSearchQueryProvider
                                                .notifier,
                                          )
                                          .state =
                                      '';
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
                          'Showing ${startIndex + 1}-$endIndex of $totalItems suppliers',
                        ),
                        if (searchQuery.isNotEmpty)
                          Text('Filtered by: "$searchQuery"'),
                      ],
                    ),
                  );
                }

                // 3. Pagination Controls (Footer)
                if (index == paginatedSuppliers.length + 2) {
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

                // 4. Supplier Cards (Main Content)
                final cardIndex = index - 2;
                final supplier = paginatedSuppliers[cardIndex];

                final hasListPadding = cardIndex == 0
                    ? const EdgeInsets.only(top: 16, left: 16, right: 16)
                    : const EdgeInsets.symmetric(horizontal: 16);

                return Padding(
                  padding: hasListPadding,
                  child: _buildSupplierCard(supplier, context),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          final msg = error.toString().toLowerCase();
          if (msg.contains('401') ||
              msg.contains('unauthorized') ||
              msg.contains('token')) {
            return const TokenErrorWidget();
          }
          return Center(child: Text('Error: $error'));
        },
      ),
    );
  }
}
