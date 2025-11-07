import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/products_provider.dart';
import '../../provider/pos_provider.dart';
import '../../widgets/token_error_widget.dart';
import 'cart_screen.dart';
import '../../auth/auth_provider.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  String searchQuery = '';

  Future<void> _refreshProducts() async {
    final token = ref.read(authProvider).accessToken;
    if (token != null) {
      ref.invalidate(productsProvider(token));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final token = authState.accessToken;
    if (token == null) {
      return const Scaffold(
        body: Center(child: Text('Token not found. Please log in again.')),
      );
    }

    // Watch products and cart providers for auto refresh
    final productsAsync = ref.watch(productsProvider(token));
    final cart = ref.watch(cartProvider);
    final totalItems = cart.values.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS - Point of Sale'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
            tooltip: 'Refresh Products',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Products',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total items in cart: $totalItems',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Search Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),

          // Products List with Pull-to-Refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshProducts,
              child: productsAsync.when(
                data: (products) {
                  final filtered = products
                      .where(
                        (p) => p.name.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isEmpty
                                ? 'No products available'
                                : 'No products found for "$searchQuery"',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      final cartItem = cart[product.id];
                      final quantity = cartItem?.quantity ?? 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Product Info
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Stock: ${product.quantity}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: product.quantity == 0
                                            ? Colors.red
                                            : Colors.grey[600],
                                        fontWeight: product.quantity == 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Price and Add Button
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'TSh ${product.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 9, 33, 10),
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    if (quantity > 0) ...[
                                      // Quantity controls when item is in cart
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove,
                                              size: 20,
                                            ),
                                            onPressed: () => ref
                                                .read(cartProvider.notifier)
                                                .removeProduct(product.id),
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.grey[200],
                                              padding: const EdgeInsets.all(4),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Text(
                                              quantity.toString(),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add,
                                              size: 20,
                                            ),
                                            onPressed:
                                                product.quantity <= quantity
                                                ? null
                                                : () => ref
                                                      .read(
                                                        cartProvider.notifier,
                                                      )
                                                      .addProduct(product),
                                            style: IconButton.styleFrom(
                                              backgroundColor: Theme.of(
                                                context,
                                              ).primaryColor,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.all(4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      // Add button when item is not in cart
                                      FilledButton.icon(
                                        onPressed: product.quantity == 0
                                            ? null
                                            : () => ref
                                                  .read(cartProvider.notifier)
                                                  .addProduct(product),
                                        icon: const Icon(
                                          Icons.add,
                                        ), // ➕ Plus icon
                                        label: const Text('Add to Cart'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Theme.of(
                                            context,
                                          ).primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ), // Rounded rectangle
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error loading products',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _refreshProducts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // Floating Cart Button with auto refresh after sale
      floatingActionButton: totalItems > 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
                // Refresh automatically if sale was completed
                if (result == true) {
                  await _refreshProducts();
                }
              },
              icon: const Icon(Icons.shopping_cart_checkout),
              label: Text('Cart ($totalItems)'),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            )
          : null,
    );
  }
}
