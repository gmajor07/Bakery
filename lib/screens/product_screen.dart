import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// Import your necessary files
import '../models/product.dart';
import '../auth/auth_provider.dart';
import '../provider/products_provider.dart';
import '../provider/products_search_provider.dart';
import '../theme.dart';
import '../widgets/token_error_widget.dart';


// Helper functions for formatting
String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_TZ', // Example locale
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

  // Set a threshold for "Low Stock"
  static const int _lowStockThreshold = 5;

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

  // ⭐ MODIFIED WIDGET: Product Card
  Widget _buildProductCard(Product product, BuildContext context) {
    final theme = Theme.of(context);

    // 1. New Stock Logic
    final bool isLowStock = product.quantity > 0 && product.quantity <= _lowStockThreshold;
    final bool isZeroStock = product.quantity == 0;

    final String stockText;
    final Color stockColor;
    final IconData stockIcon;

    if (isZeroStock) {
      stockText = 'Out of Stock';
      stockColor = theme.colorScheme.error; // Red for zero stock
      stockIcon = Icons.remove_shopping_cart_outlined;
    } else if (isLowStock) {
      stockText = 'Low Stock';
      stockColor = Colors.orange; // Orange for low stock
      stockIcon = Icons.inventory_2_outlined;
    } else {
      stockText = 'In Stock';
      // 2. Color Change: Cyan/Tertiary replaced with blueGrey
      stockColor = Colors.blueGrey.shade600;
      stockIcon = Icons.inventory_2_outlined;
    }

    final statusColor = product.status == 'active'
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Icon(
          stockIcon, // Use dynamic icon based on stock
          color: stockColor, // Use dynamic stock color
          size: 32,
        ),
        title: Text(
          product.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Subtitle Row for Description (Ellipsis added)
            Text(
              product.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            // Status and Quantity Row
            Row(
              children: [
                // Status Chip
                Chip(
                  label: Text(
                    product.status[0].toUpperCase() + product.status.substring(1),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: statusColor.withOpacity(0.1),
                  side: BorderSide(color: statusColor.withOpacity(0.5)),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                // Quantity Tag
                Text(
                  '| ${formatNumber(product.quantity)} units',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
              formatCurrency(product.price),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              stockText, // Use dynamic stock text
              style: theme.textTheme.bodySmall?.copyWith(
                color: stockColor, // Use dynamic stock color
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Implement navigation to Product Detail Screen
        },
      ),
    );
  }
  // --- End of Modified Widget ---

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
      appBar: AppBar(
        title: const Text('Inventory Products'),
        elevation: 0,
      ),
      // ⭐ ADDED: Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement logic to navigate to Add Product screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Product button pressed!')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ⭐ REVERTED: Search input back to TextField
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${startIndex + 1}-$endIndex of $totalItems results',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Products List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: paginatedProducts.isEmpty
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isEmpty
                                ? 'No products currently available.'
                                : 'No products found matching "$searchQuery".',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                      : ListView.builder(
                    itemCount: paginatedProducts.length,
                    itemBuilder: (context, index) {
                      final product = paginatedProducts[index];
                      return _buildProductCard(product, context);
                    },
                  ),
                ),
              ),

              // Pagination Controls (Fixed and Modernized)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  border: Border(
                    top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous Button (Icon before Label)
                    OutlinedButton.icon(
                      onPressed: currentPage > 0 ? _previousPage : null,
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Previous'),
                    ),

                    // Page Info
                    Text(
                      'Page ${currentPage + 1} of $totalPages',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Next Button (Label before Icon)
                    OutlinedButton.icon(
                      onPressed: currentPage < totalPages - 1
                          ? () => _nextPage(totalItems, itemsPerPage)
                          : null,
                      label: const Text('Next'),
                      icon: const Icon(Icons.chevron_right),
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
            return TokenErrorWidget();
          }
          return Center(child: Text('Error: $error'));
        },
      ),
    );
  }
}