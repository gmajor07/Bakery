import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../provider/products_provider.dart';
import '../../provider/pos_provider.dart';
import '../../widgets/token_error_widget.dart';
import 'cart_screen.dart' hide formatCurrency;
import '../../auth/auth_provider.dart';
import '../../utils/formatters.dart'; // Contains formatCurrency

// Utility function definition for completeness (as used in the UI)
String formatNumber(int number) {
  // Use a locale that uses commas for thousands separator
  return NumberFormat('#,##0').format(number);
}

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  String searchQuery = '';
  // Map to hold controllers for quantity TextFields
  final Map<int, TextEditingController> _qtyControllers = {};

  @override
  void dispose() {
    for (var controller in _qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _refreshProducts() async {
    final token = ref.read(authProvider).accessToken;
    if (token != null) {
      ref.invalidate(productsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

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
    final productsAsync = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);
    final totalItems = cart.values.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Point of Sale',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Cart Button at the top right
          if (totalItems > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Badge.count(
                count: totalItems,
                backgroundColor: colorScheme.error,
                textColor: colorScheme.onError,
                child: IconButton(
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
                  color: colorScheme.primary,
                  tooltip: 'View Cart',
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
            tooltip: 'Refresh Products',
            color: colorScheme.onSurface,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header & Search Section (Combined for flow)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Section
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(
                      0.5,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
                const SizedBox(height: 16),
                // Muted info text, moved below search
                Text(
                  'Total items in cart: $totalItems',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Products List with Pull-to-Refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshProducts,
              color: colorScheme.primary,
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
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isEmpty
                                ? 'No products available'
                                : 'No products found for "$searchQuery"',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurfaceVariant,
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

                      // Get or create controller for the product
                      final qtyController = _qtyControllers.putIfAbsent(
                        product.id,
                        () => TextEditingController(),
                      );
                      // Update controller text if quantity changes externally
                      if (qtyController.text != quantity.toString()) {
                        qtyController.text = quantity.toString();
                        // Maintain cursor position at the end
                        qtyController.selection = TextSelection.fromPosition(
                          TextPosition(offset: qtyController.text.length),
                        );
                      }

                      return _buildProductCard(
                        context,
                        ref,
                        product,
                        quantity,
                        qtyController,
                        colorScheme,
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
                    // Check if mounted before returning widget
                    if (context.mounted) {
                      return const TokenErrorWidget();
                    }
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: colorScheme.error,
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
    );
  }

  // Extracted widget for better readability and maintainability (Responsive version)
  Widget _buildProductCard(
    BuildContext context,
    WidgetRef ref,
    Product product,
    int quantity,
    TextEditingController qtyController,
    ColorScheme colorScheme,
  ) {
    final isOutOfStock = product.quantity == 0;
    final canIncrement = product.quantity > quantity;

    // Determine screen width to adjust layout density if needed
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 360;
    final cardPadding = isNarrowScreen ? 12.0 : 16.0;

    // ADJUSTED FLEX RATIOS: Give controls more horizontal space
    final infoFlex = isNarrowScreen ? 2 : 3;
    final controlFlex = isNarrowScreen ? 3 : 2;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product Info
            Expanded(
              flex: infoFlex,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // PRICE FORMATTING
                  Text(
                    formatCurrency(product.price),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // STOCK FORMATTING
                  Text(
                    'Stock: ${formatNumber(product.quantity)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isOutOfStock
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isOutOfStock
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Quantity Controls / Add Button
            Expanded(
              flex: controlFlex,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (quantity > 0) ...[
                    // Quantity controls (Remove/Input/Add)
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 20),
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .removeProduct(product.id),
                            color: colorScheme.primary,
                            visualDensity: VisualDensity.compact,
                          ),
                          // Manual quantity input
                          SizedBox(
                            width: 50, // Usable width, supported by flex ratio
                            child: TextField(
                              controller: qtyController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              onChanged: (value) {
                                final intQty = int.tryParse(value);
                                if (intQty != null && intQty >= 1) {
                                  _handleQuantityUpdate(
                                    ref,
                                    product,
                                    intQty,
                                    qtyController,
                                  );
                                } else if (value.isEmpty) {
                                  // Logic to handle clearing the input field
                                }
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 20),
                            onPressed: canIncrement
                                ? () => ref
                                      .read(cartProvider.notifier)
                                      .addProduct(product)
                                : null,
                            color: canIncrement
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant.withOpacity(0.5),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Add button when item not in cart
                    FilledButton.icon(
                      onPressed: isOutOfStock
                          ? null
                          : () => ref
                                .read(cartProvider.notifier)
                                .addProduct(product),
                      icon: const Icon(Icons.add),
                      label: Text(isNarrowScreen ? '' : 'Add'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: isNarrowScreen
                            ? const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              )
                            : const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
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
  }

  // ⭐️ RESTORED FUNCTION: Helper to handle quantity updates and stock checks
  void _handleQuantityUpdate(
    WidgetRef ref,
    Product product,
    int intQty,
    TextEditingController controller,
  ) {
    if (intQty <= 0) {
      ref.read(cartProvider.notifier).removeProduct(product.id);
    } else if (intQty <= product.quantity) {
      ref.read(cartProvider.notifier).updateProductQuantity(product.id, intQty);
    } else {
      // If user exceeds stock, reset the TextField immediately to max stock
      controller.text = product.quantity.toString();
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
      ref
          .read(cartProvider.notifier)
          .updateProductQuantity(product.id, product.quantity);
    }
  }
}
