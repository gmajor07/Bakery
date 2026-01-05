import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_recipe.dart';
import '../provider/products_provider.dart';
import '../services/inventory_api_service.dart';
import '../models/inventory_item.dart';
import '../widgets/token_error_widget.dart';

class RecipeScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> productData;

  const RecipeScreen({super.key, required this.productData});

  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _batchSizeController = TextEditingController(text: '1');
  final List<RecipeIngredient> _ingredients = [];
  List<InventoryItem> _inventoryItems = [];
  bool _isLoadingInventory = true;

  @override
  void initState() {
    super.initState();
    _loadInventoryItems();
    // Add one empty ingredient row by default
    _addIngredientRow();
  }

  @override
  void dispose() {
    _batchSizeController.dispose();
    super.dispose();
  }

  Future<void> _loadInventoryItems() async {
    try {
      setState(() {
        _isLoadingInventory = true;
      });

      final inventoryService = ref.read(inventoryApiServiceProvider);
      final items = await inventoryService.fetchInventory();

      setState(() {
        _inventoryItems = items;
        _isLoadingInventory = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingInventory = false;
      });

      if (mounted) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('401') ||
            msg.contains('unauthorized') ||
            msg.contains('token') ||
            msg.contains('expired')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login again.'),
            ),
          );
          // You might want to navigate to login screen here
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading inventory: $e')),
          );
        }
      }
    }
  }

  void _addIngredientRow() {
    setState(() {
      _ingredients.add(RecipeIngredient());
    });
  }

  void _removeIngredientRow(int index) {
    setState(() {
      if (_ingredients.length > 1) {
        _ingredients.removeAt(index);
      }
    });
  }

  Future<void> _createProduct() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Validate that all ingredient rows are filled
      for (int i = 0; i < _ingredients.length; i++) {
        final ingredient = _ingredients[i];
        if (ingredient.selectedItemId == null ||
            ingredient.quantityController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please fill all ingredient fields in row ${i + 1}',
              ),
            ),
          );
          return;
        }
      }

      try {
        // Convert ingredients to CreateProductRecipe format
        final List<CreateProductRecipe> productRecipes = [];
        for (final ingredient in _ingredients) {
          productRecipes.add(
            CreateProductRecipe(
              inventoryItemId: ingredient.selectedItemId!,
              amountRequired: double.parse(ingredient.quantityController.text),
            ),
          );
        }

        // Create product using API
        final productService = ref.read(productsApiServiceProvider);
        await productService.createProduct(
          name: widget.productData['name'],
          description: widget.productData['description'],
          price: widget.productData['price'],
          prepTime: widget.productData['prepTime'],
          batchSize: int.parse(_batchSizeController.text),
          quantity: widget.productData['quantity'],
          status: widget.productData['status'],
          productRecipes: productRecipes,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product created successfully!')),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error creating product: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Recipe'), elevation: 0),
      body: _isLoadingInventory
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Recipe Header
                    Text(
                      'Product Recipe',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Batch Size
                    TextFormField(
                      controller: _batchSizeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Batch Size (units produced by this recipe)',
                        hintText: '1',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Batch size is required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (int.parse(value) <= 0) {
                          return 'Batch size must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Add Ingredient Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ingredients',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addIngredientRow,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Ingredient'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Ingredients List
                    ...List.generate(_ingredients.length, (index) {
                      return _buildIngredientRow(index, theme);
                    }),

                    const SizedBox(height: 32),

                    // Create Product Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createProduct,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        child: const Text('Create Product'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildIngredientRow(int index, ThemeData theme) {
    final ingredient = _ingredients[index];
    final selectedItem = _inventoryItems.isNotEmpty
        ? _inventoryItems.firstWhere(
            (InventoryItem item) => item.id == ingredient.selectedItemId,
            orElse: () => _inventoryItems.first,
          )
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row header with remove button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ingredient ${index + 1}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_ingredients.length > 1)
                  IconButton(
                    onPressed: () => _removeIngredientRow(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Remove ingredient',
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Item Name Dropdown
            DropdownButtonFormField<int>(
              value: ingredient.selectedItemId,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
              items: _inventoryItems.map<DropdownMenuItem<int>>((
                InventoryItem item,
              ) {
                return DropdownMenuItem<int>(
                  value: item.id,
                  child: Text(item.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    ingredient.selectedItemId = value;
                    // Auto-fill unit based on selected item
                    final selectedInventoryItem = _inventoryItems.firstWhere(
                      (InventoryItem item) => item.id == value,
                    );
                    ingredient.unitController.text = selectedInventoryItem.unit;
                  });
                }
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select an item';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Quantity and Unit Row
            Row(
              children: [
                // Quantity
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: ingredient.quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Quantity is required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      if (double.parse(value) <= 0) {
                        return 'Quantity must be greater than 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Unit (read-only)
                Expanded(
                  child: TextFormField(
                    controller: ingredient.unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeIngredient {
  int? selectedItemId;
  final quantityController = TextEditingController();
  final unitController = TextEditingController();

  void dispose() {
    quantityController.dispose();
    unitController.dispose();
  }
}
