import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../auth/auth_provider.dart';
import '../provider/products_provider.dart';
import '../provider/products_search_provider.dart';
import '../widgets/token_error_widget.dart';
import 'add_product_screen.dart';

// Helper functions for formatting
String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_TZ',
    symbol: 'TSh',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

String formatNumber(int number) {
  return NumberFormat('#,##0').format(number);
}

// Pagination providers
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

  static const int _lowStockThreshold = 5;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.text = ref.read(productSearchQueryProvider);
    _searchController.addListener(() {
      ref.read(productSearchQueryProvider.notifier).state =
          _searchController.text;
      ref.read(paginationProvider.notifier).state = 0;
    });

    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await ref.read(authProvider.notifier).getAccessToken();
    if (mounted) {
      setState(() {
        _token = token;
        _isLoadingToken = false;
      });
    }
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

    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Products List'), elevation: 0),
      // ⭐ FIXED: Icon only FloatingActionButton
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: productsAsync.when(
        data: (products) {
          // ⭐ ADDED: Descending Order (Assuming ID or Date)
          final List<Product> sortedList = [...products];
          sortedList.sort((a, b) => b.id.compareTo(a.id));

          final filteredProducts = sortedList.where((product) {
            return product.name.toLowerCase().contains(searchQuery) ||
                product.description.toLowerCase().contains(searchQuery);
          }).toList();

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Field
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
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  'Showing ${totalItems == 0 ? 0 : startIndex + 1}-$endIndex of $totalItems results',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

              // ⭐ ADDED: RefreshIndicator for Pull-to-Refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(productsProvider.future),
                  color: Theme.of(context).colorScheme.primary,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: paginatedProducts.isEmpty
                        ? _buildEmptyState(searchQuery)
                        : ListView.builder(
                            // physics: AlwaysScrollableScrollPhysics allows refresh even if list is short
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: paginatedProducts.length,
                            itemBuilder: (context, index) {
                              return _buildProductCard(
                                paginatedProducts[index],
                                context,
                              );
                            },
                          ),
                  ),
                ),
              ),

              // Pagination Footer
              _buildPaginationFooter(
                context,
                currentPage,
                totalPages,
                totalItems,
                itemsPerPage,
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
            return const TokenErrorWidget();
          }
          return Center(child: Text('Error: ${error.toString()}'));
        },
      ),
    );
  }

  Widget _buildEmptyState(String searchQuery) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 400,
        alignment: Alignment.center, // This is an 'AlignmentGeometry' instance
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty
                  ? 'No products available.'
                  : 'No matches for "$searchQuery".',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(
    BuildContext context,
    int currentPage,
    int totalPages,
    int totalItems,
    int itemsPerPage,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: currentPage > 0 ? _previousPage : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          Text(
            'Page ${currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}',
          ),
          OutlinedButton.icon(
            onPressed: currentPage < totalPages - 1
                ? () => _nextPage(totalItems, itemsPerPage)
                : null,
            label: const Text('Next'),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, BuildContext context) {
    final theme = Theme.of(context);
    final bool isZeroStock = product.quantity == 0;
    final bool isLowStock =
        product.quantity > 0 && product.quantity <= _lowStockThreshold;

    Color stockColor = Colors.orange.shade600;
    String stockText = 'In Stock';
    IconData stockIcon = Icons.inventory_2_outlined;

    if (isZeroStock) {
      stockColor = Colors.red.shade600;
      stockText = 'Critical';
      stockIcon = Icons.remove_shopping_cart_outlined;
    } else if (isLowStock) {
      stockColor = Colors.blueGrey;
      stockText = 'Low Stock';
    }

    final statusColor = product.status == 'Active'
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(stockIcon, color: stockColor, size: 32),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    product.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('| ${formatNumber(product.quantity)} Quantity'),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatCurrency(product.price),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              stockText,
              style: TextStyle(
                color: stockColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
