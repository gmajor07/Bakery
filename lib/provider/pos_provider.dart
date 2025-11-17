import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

class CartNotifier extends StateNotifier<Map<int, CartItem>> {
  CartNotifier() : super({});

  /// Add +1 product to the cart
  void addProduct(Product product) {
    final currentItem = state[product.id];
    final updatedQuantity = (currentItem?.quantity ?? 0) + 1;

    state = {
      ...state,
      product.id: CartItem(product: product, quantity: updatedQuantity),
    };
  }

  /// Remove -1 product or remove item if it reaches zero
  void removeProduct(int productId) {
    final currentItem = state[productId];
    if (currentItem == null) return;

    final newQuantity = currentItem.quantity - 1;
    if (newQuantity > 0) {
      state = {
        ...state,
        productId: currentItem.copyWith(quantity: newQuantity),
      };
    } else {
      state = Map<int, CartItem>.from(state)..remove(productId);
    }
  }

  /// Update manually entered quantity
  void updateProductQuantity(int productId, int quantity, [Product? product]) {
    // ✅ If product not in cart but user entered a value, add it
    final existingItem = state[productId];

    if (existingItem == null && product != null) {
      if (quantity > 0) {
        state = {
          ...state,
          productId: CartItem(product: product, quantity: quantity),
        };
      }
      return;
    }

    if (existingItem == null) return;

    final maxQuantity = existingItem.product.quantity;
    final newQuantity = quantity.clamp(0, maxQuantity);

    // ✅ If zero, remove from cart
    if (newQuantity == 0) {
      final newState = Map<int, CartItem>.from(state)..remove(productId);
      state = newState;
    } else {
      // ✅ Always assign a NEW map reference
      state = {
        ...state,
        productId: existingItem.copyWith(quantity: newQuantity),
      };
    }
  }

  /// Clear entire cart
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
