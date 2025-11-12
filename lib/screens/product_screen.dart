import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

          return Column(
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
                                      .read(productSearchQueryProvider.notifier)
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

              // Products Table
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width:
                        double.infinity, // 👈 makes table fill available width
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: DataTable(
                      dataTextStyle: Theme.of(context).textTheme.bodyMedium,
                      headingTextStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: AppTheme.primaryBrown),
                      headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.brown.shade50,
                      ),
                      columnSpacing: 40, // spacing between columns
                      horizontalMargin: 16,
                      columns: const [
                        DataColumn(label: Text('Product Name')),
                        DataColumn(label: Text('Price')),
                        DataColumn(label: Text('Stock')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: paginatedProducts.map((product) {
                        final stockText = product.isInStock
                            ? 'In Stock'
                            : 'Out of Stock';
                        final stockColor = product.isInStock
                            ? Colors.green
                            : Colors.red;
                        final statusColor = product.status == 'active'
                            ? AppTheme.primaryBrown
                            : Colors.grey;

                        return DataRow(
                          cells: [
                            DataCell(Text(product.name)),
                            DataCell(
                              Text('TSh ${product.price.toStringAsFixed(0)}'),
                            ),
                            DataCell(
                              Text(
                                stockText,
                                style: TextStyle(
                                  color: stockColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                product.status[0].toUpperCase() +
                                    product.status.substring(1),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          final msg = error.toString().toLowerCase();
          if (msg.contains('401') ||
              msg.contains('unauthorized') ||
              msg.contains('token') ||
              msg.contains('expired')) {
            return TokenErrorWidget(ref: ref);
          }
          return Center(child: Text('Error: $error'));
        },
      ),
    );
  }
}
