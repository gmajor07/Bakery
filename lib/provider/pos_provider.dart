import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

class CartNotifier extends StateNotifier<Map<int, CartItem>> {
  CartNotifier() : super({});

  void addProduct(Product product) {
    if (state.containsKey(product.id)) {
      final updatedItem = state[product.id]!.copyWith(
        quantity: state[product.id]!.quantity + 1,
      );
      state = {...state, product.id: updatedItem}; // ✅ FIXED
    } else {
      state = {...state, product.id: CartItem(product: product, quantity: 1)};
    }
  }

  void removeProduct(int productId) {
    if (!state.containsKey(productId)) return;

    final currentItem = state[productId]!;
    if (currentItem.quantity > 1) {
      final updatedItem = currentItem.copyWith(
        quantity: currentItem.quantity - 1,
      );
      state = {...state, productId: updatedItem};
    } else {
      final newState = {...state};
      newState.remove(productId);
      state = newState;
    }
  }

  void clearCart() => state = {};

  int get totalItems =>
      state.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      state.values.fold(0.0, (sum, item) => sum + item.totalPrice);
}

final cartProvider = StateNotifierProvider<CartNotifier, Map<int, CartItem>>(
      (ref) => CartNotifier(),
);

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  double get totalPrice => product.price * quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
