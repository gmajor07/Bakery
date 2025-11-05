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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // ✅ If token is not yet loaded
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final token = authState.accessToken;
    if (token == null) {
      return const Scaffold(
        body: Center(child: Text('Token not found. Please log in again.')),
      );
    }

    final productsAsync = ref.watch(productsProvider(token));
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (cart.isNotEmpty)
                  Positioned(
                    right: 0,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        cart.values.fold<int>(0, (sum, item) => sum + item.quantity).toString(),
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search products...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filtered = products
                    .where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Stock: ${product.quantity}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('TSh ${product.price.toStringAsFixed(0)}'),
                                  const SizedBox(height: 6),
                                  ElevatedButton(
                                    onPressed: product.quantity == 0
                                        ? null
                                        : () => ref.read(cartProvider.notifier).addProduct(product),
                                    child: const Text('Add'),
                                  ),
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
                return Center(child: Text('Login Again'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
