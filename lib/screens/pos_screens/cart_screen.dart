import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // ⬅️ NEW: Import for currency formatting
import '../../provider/pos_provider.dart';
import 'checkout_screen.dart';

// Helper function for formatting currency
String formatCurrency(double amount) {
  // Use NumberFormat to format the currency for Tanzania Shilling (TSh)
  // The symbol 'TSh' is displayed, and the maximum fraction digits is set to 0
  // to remove the decimal point if the amount is an integer.
  final formatter = NumberFormat.currency(
    locale: 'en_TZ', // Using a locale that supports TSh/African currencies
    symbol: 'TSh',
    decimalDigits: 0, // No decimal points for TSh
  );
  return formatter.format(amount);
}

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final Map<int, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(int productId, int quantity) {
    if (!_controllers.containsKey(productId)) {
      _controllers[productId] = TextEditingController(
        text: quantity.toString(),
      );
    } else {
      final controller = _controllers[productId]!;
      // Only update the controller text if the quantity has changed from an external source (like a button press)
      if (controller.text != quantity.toString()) {
        controller.text = quantity.toString();
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
      }
    }
    return _controllers[productId]!;
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final totalItems = cartNotifier.totalItems;
    final totalPrice = cartNotifier.totalPrice;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shopping Cart',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0, // Modern look, no shadow
        actions: [
          if (cart.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              onPressed: () => _showClearCartDialog(context, ref),
              tooltip: 'Clear Cart',
            ),
        ],
      ),
      body: cart.isEmpty
          ? _buildEmptyCart(context)
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              itemCount: cart.length,
              itemBuilder: (context, index) {
                final item = cart.values.elementAt(index);
                return _buildCartItem(item, ref, context);
              },
            ),
          ),
          _buildTotalSection(totalPrice, totalItems, context),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, WidgetRef ref, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxQuantity = item.product.quantity;
    final currentQuantity = item.quantity;

    final controller = _getController(item.product.id, currentQuantity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0, // Flat cards for modern look
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder for a product image (optional)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.shopping_bag_outlined, color: colorScheme.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // ⬅️ PRICE FORMATTING APPLIED HERE
                  Text(
                    formatCurrency(item.product.price),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.primary, // Using primary color for individual price
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stock: $maxQuantity',
                    style: TextStyle(
                      fontSize: 12,
                      color: maxQuantity == 0 ? colorScheme.error : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Quantity Control with Rounded Buttons
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onPressed: currentQuantity == 1
                            ? null
                            : () => ref
                            .read(cartProvider.notifier)
                            .removeProduct(item.product.id),
                        colorScheme: colorScheme,
                      ),
                      SizedBox(
                        width: 40,
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onChanged: (value) {
                            final intQty = int.tryParse(value);
                            if (intQty != null && intQty >= 1) {
                              ref
                                  .read(cartProvider.notifier)
                                  .updateProductQuantity(
                                item.product.id,
                                intQty,
                                item.product,
                              );
                            }
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                        ),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onPressed: currentQuantity >= maxQuantity
                            ? null
                            : () => ref
                            .read(cartProvider.notifier)
                            .addProduct(item.product),
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Total Price and Remove Button
                Row(
                  children: [
                    // ⬅️ SUBTOTAL PRICE FORMATTING APPLIED HERE
                    Text(
                      formatCurrency(item.product.price * item.quantity),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showRemoveItemDialog(
                        context,
                        ref,
                        item.product.id,
                        item.product.name,
                      ),
                      child: Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required ColorScheme colorScheme,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18),
      color: onPressed == null ? colorScheme.onSurfaceVariant.withOpacity(0.5) : colorScheme.primary,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    );
  }


  Widget _buildEmptyCart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80, // Larger icon
            color: colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Your shopping cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding products to proceed to checkout.',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.arrow_right_alt_rounded),
            label: const Text('Browse Products'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              Navigator.pop(context); // Assuming this screen is navigated to from the product screen
              // Or use Navigator.pushNamed(context, '/products');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(double totalPrice, int totalItems, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total ($totalItems ${totalItems == 1 ? 'item' : 'items'}):',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              // ⬅️ TOTAL PRICE FORMATTING APPLIED HERE
              Text(
                formatCurrency(totalPrice),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary, // Highlight the total price
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Proceed to Checkout'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onPressed: totalPrice > 0 ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                );
              } : null, // Disable button if cart is empty
            ),
          ),
        ],
      ),
    );
  }

  // Dialog methods remain mostly the same, ensuring color consistency
  void _showRemoveItemDialog(
      BuildContext context,
      WidgetRef ref,
      int productId,
      String productName,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove "$productName" from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).removeProduct(productId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}