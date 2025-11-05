import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/pos_provider.dart';
import 'checkout_screen.dart'; //

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final totalItems = cartNotifier.totalItems;
    final totalPrice = cartNotifier.totalPrice;

    return Scaffold(
      appBar: AppBar(title: Text('Cart ($totalItems items)')),
      body: cart.isEmpty
          ? const Center(
        child: Text('Your cart is empty', style: TextStyle(fontSize: 18)),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...cart.values.map((item) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(item.product.name),
                subtitle: Text(
                  'TSh ${item.product.price.toStringAsFixed(2)} each',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        ref
                            .read(cartProvider.notifier)
                            .removeProduct(item.product.id);
                      },
                    ),
                    Text('${item.quantity}'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        ref
                            .read(cartProvider.notifier)
                            .addProduct(item.product);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          const Divider(),
          ListTile(
            title: const Text(
              'Total',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              'TSh ${totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CheckoutScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.pink,
          ),
          child: const Text(
            'Proceed to Checkout',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
