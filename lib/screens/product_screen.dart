import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../provider/products_provider.dart';
import '../widgets/token_error_widget.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: ref.read(authProvider.notifier).getAccessToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final token = snapshot.data;
        if (token == null) {
          return const Scaffold(
            body: Center(child: Text('Token not found. Please log in again.')),
          );
        }

        final productsAsync = ref.watch(productsProvider(token));

        return Scaffold(
          appBar: AppBar(title: const Text('Products')),
          body: productsAsync.when(
            data: (products) => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text(
                      '${product.description}\nStock: ${product.quantity}',
                    ),
                    trailing: Text('TSh ${product.price.toStringAsFixed(2)}'),
                  ),
                );
              },
            ),
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
        );
      },
    );
  }
}
