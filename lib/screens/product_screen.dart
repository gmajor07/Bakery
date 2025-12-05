import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import your necessary files
import '../auth/auth_provider.dart';
import '../provider/products_provider.dart';
import '../provider/products_search_provider.dart';
import '../theme.dart';
import '../widgets/token_error_widget.dart';


// Pagination provider
final paginationProvider = StateProvider<int>((ref) => 0);
final itemsPerPageProvider = StateProvider<int>((ref) => 10);

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  late TextEditingController _searchController;
  String? _token;
  bool _isLoadingToken = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.text = ref.read(productSearchQueryProvider);
    _searchController.addListener(() {
      ref.read(productSearchQueryProvider.notifier).state =
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

  // --- New Widget for Product Card View ---
  Widget _buildProductCard(dynamic product, BuildContext context) {
    // Assuming 'product' is the instance of your Product model
    final stockText = product.isInStock ? 'In Stock' : 'Out of Stock';
    final stockColor = product.isInStock ? Colors.brown : Colors.red;
    final statusColor = product.status == 'active'
        ? AppTheme.primaryBrown
        : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Name
            Text(
              product.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBrown,
              ),
            ),
            const SizedBox(height: 8),

            // Price and Stock
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Price', style: TextStyle(color: Colors.grey)),
                    Text(
                      'TSh ${product.price.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                // Stock
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Stock', style: TextStyle(color: Colors.grey)),
                    Text(
                      stockText,
                      style: TextStyle(
                        color: stockColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            // Status
            Row(
              children: [
                const Text('Status: ', style: TextStyle(color: Colors.grey)),
                Text(
                  product.status[0].toUpperCase() + product.status.substring(1),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // --- End of New Widget ---

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(productSearchQueryProvider).toLowerCase();
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

    // Replace dynamic with the actual type of your Product model if possible
    final productsAsync = ref.watch(productsProvider(_token!));

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: productsAsync.when(
        data: (products) {
          final filteredProducts = products.where((product) {
            return product.name.toLowerCase().contains(searchQuery) ||
                product.description.toLowerCase().contains(searchQuery);
          }).toList();

          // Calculate pagination
          final totalItems = filteredProducts.length;
          final totalPages = (totalItems / itemsPerPage).ceil();
          final startIndex = currentPage * itemsPerPage;
          final endIndex = (startIndex + itemsPerPage) > totalItems
              ? totalItems
              : (startIndex + itemsPerPage);
          final paginatedProducts = filteredProducts.sublist(
            startIndex,
            endIndex,
          );

          // FIX: Wrap the entire contents in a SingleChildScrollView
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search products',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                        .read(
                                          productSearchQueryProvider.notifier,
                                        )
                                        .state =
                                    '';
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),

                // Results and Pagination Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${startIndex + 1}-$endIndex of $totalItems products',
                      ),
                      if (searchQuery.isNotEmpty)
                        Text('Filtered by: "$searchQuery"'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // FIX: Products List (Replaced DataTable)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: paginatedProducts.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No products found matching your search.',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                        )
                      : ListView.builder(
                          // These two properties are crucial for ListView inside SingleChildScrollView
                          shrinkWrap: true,
                          primary: false,
                          itemCount: paginatedProducts.length,
                          itemBuilder: (context, index) {
                            final product = paginatedProducts[index];
                            return _buildProductCard(product, context);
                          },
                        ),
                ),

                // Pagination Controls
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Previous Button
                      ElevatedButton.icon(
                        onPressed: currentPage > 0 ? _previousPage : null,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                      ),

                      const SizedBox(width: 16),

                      // Page Info
                      Text(
                        'Page ${currentPage + 1} of $totalPages',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(width: 16),

                      // Next Button
                      ElevatedButton.icon(
                        onPressed: currentPage < totalPages - 1
                            ? () => _nextPage(totalItems, itemsPerPage)
                            : null,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Next'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          final msg = error.toString().toLowerCase();
          if (msg.contains('401') ||
              msg.contains('unauthorized') ||
              msg.contains('token') ||
              msg.contains('expired')) {
            return TokenErrorWidget();
          }
          return Center(child: Text('Error: $error'));
        },
      ),
    );
  }
}
