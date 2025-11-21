import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/auth_provider.dart';
import '../../models/purchase_order.dart';
import '../../provider/purchase_orders_provider.dart';
import '../../purchases_model/inventory_item.dart';
import '../../purchases_model/unit_type.dart';
// 💡 ASSUMING THESE MODELS EXIST BASED ON USAGE:

class CreatePurchaseOrderScreen extends ConsumerStatefulWidget {
  const CreatePurchaseOrderScreen({super.key});

  @override
  ConsumerState<CreatePurchaseOrderScreen> createState() =>
      _CreatePurchaseOrderScreenState();
}

class _CreatePurchaseOrderScreenState
    extends ConsumerState<CreatePurchaseOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form State Variables
  int? selectedSupplierId;
  List<Map<String, dynamic>> items = [];
  String notes = '';
  double totalCost = 0.0;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Start with one item for convenience
    _addItem();
  }

  void _addItem() {
    setState(() {
      items.add({
        'inventoryItemId': null,
        'quantity': 1,
        'unit': null,
        'price': 0.0,
      });
      _calculateTotal();
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
      _calculateTotal();
      // Ensure there's always at least one item field if the list becomes empty
      if (items.isEmpty) {
        _addItem();
      }
    });
  }

  void _calculateTotal() {
    setState(() {
      totalCost = items.fold(
        0.0,
        (sum, item) => sum + ((item['quantity'] ?? 0) * (item['price'] ?? 0.0)),
      );
    });
  }

  // ------------------------- API HANDLER -------------------------

  Future<void> _createOrder() async {
    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all required fields in the form and items.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Ensure at least one valid item is selected
    if (items.where((i) => i['inventoryItemId'] != null).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add and select at least one item.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isCreating = true);

    final auth = ref.read(authProvider.notifier);
    final api = ref.read(purchaseOrdersApiServiceProvider);

    try {
      final token = await auth.getAccessToken();
      if (token == null) {
        throw Exception('Token expired or missing.');
      }

      final payload = {
        "supplierId": selectedSupplierId,
        "totalCost": totalCost,
        "status": "pending", // Default status for new POs
        "notes": notes,
        "items": items
            .where((i) => i['inventoryItemId'] != null) // Only send valid items
            .map(
              (i) => {
                "inventoryItemId": i['inventoryItemId'],
                "quantity": i['quantity'],
                "unit": i['unit'],
                "price": i['price'],
              },
            )
            .toList(),
      };

      await api.createPurchaseOrder(payload);

      // Successfully created order, refresh the list on the previous screen
      ref.invalidate(purchaseOrdersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Purchase order created successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Pop and return true to indicate success
      }
    } catch (e) {
      final errorText = e.toString().toLowerCase();

      if (errorText.contains('401') ||
          errorText.contains('unauthorized') ||
          errorText.contains('token')) {
        await auth.logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please log in again.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "❌ Failed to create order: ${e.toString().split(':')[0]}",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  // ------------------------- UI BUILDERS -------------------------

  @override
  Widget build(BuildContext context) {
    // 💡 Explicitly watch the providers to get AsyncValue<List<T>>
    final suppliersAsync = ref.watch(suppliersProvider);
    final itemsAsync = ref.watch(inventoryItemsProvider);
    final unitsAsync = ref.watch(unitTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Create Purchase Order")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader('Supplier & Details'),
                const SizedBox(height: 12),

                // --- 1. Supplier Dropdown ---
                _buildSupplierDropdown(suppliersAsync),
                const SizedBox(height: 20),

                // --- 2. Notes Field ---
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Notes (Optional)",
                    hintText: "E.g., Delivery required by next Friday",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onSaved: (value) => notes = value ?? '',
                ),
                const SizedBox(height: 30),

                // --- 3. Items List ---
                _buildHeader('Order Items'),
                const SizedBox(height: 12),

                // Dynamic Item Fields
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return _buildItemRow(index, item, itemsAsync, unitsAsync);
                }),

                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text("Add Another Item"),
                ),

                const SizedBox(height: 20),

                // --- 4. Total Cost Display ---
                _buildTotalCostDisplay(),

                const SizedBox(height: 30),

                // --- 5. Action Buttons ---
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildSupplierDropdown(AsyncValue<List<dynamic>> suppliersAsync) {
    return suppliersAsync.when(
      data: (suppliers) {
        // 💡 CAST LIST: Explicitly cast to List<Supplier>
        final supplierList = suppliers.cast<Supplier>();

        return DropdownButtonFormField<int>(
          value: selectedSupplierId,
          items: supplierList
              .map<DropdownMenuItem<int>>(
                // 💡 Explicit Map Type
                (s) => DropdownMenuItem<int>(value: s.id, child: Text(s.name)),
              )
              .toList(),
          onChanged: (val) => setState(() => selectedSupplierId = val),
          decoration: const InputDecoration(
            labelText: "Supplier *",
            hintText: "Select a supplier",
            border: OutlineInputBorder(),
          ),
          validator: (val) => val == null ? "Please select a supplier" : null,
        );
      },
      loading: () => const Center(child: LinearProgressIndicator()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          "Error loading suppliers: ${e.toString().split(':')[0]}",
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildItemRow(
    int index,
    Map<String, dynamic> item,
    AsyncValue<List<dynamic>> itemsAsync,
    AsyncValue<List<dynamic>> unitsAsync,
  ) {
    // 💡 CAST LIST: Explicitly cast to List<InventoryItem>
    final List<InventoryItem> inventoryItems =
        itemsAsync.valueOrNull?.cast<InventoryItem>() ?? [];

    // Find the currently selected item to display its details (unit/price)
    final InventoryItem? selectedInventoryItem = inventoryItems
        .cast<InventoryItem?>()
        .firstWhere(
          (i) => i?.id == item['inventoryItemId'],
          orElse: () => null,
        );

    // Calculate row total
    final rowTotal = (item['quantity'] ?? 0) * (item['price'] ?? 0.0);
    final formattedRowTotal = NumberFormat.currency(
      symbol: 'TSh',
      decimalDigits: 0,
    ).format(rowTotal);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Item Dropdown and Delete Button
            Row(
              children: [
                Expanded(
                  child: itemsAsync.when(
                    data: (_) => DropdownButtonFormField<int>(
                      value: item['inventoryItemId'],
                      items: inventoryItems
                          .map<DropdownMenuItem<int>>(
                            // 💡 Explicit Map Type
                            (i) => DropdownMenuItem<int>(
                              value: i.id,
                              child: Text(
                                i.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        final selected = inventoryItems.firstWhere(
                          (i) => i.id == val,
                        );
                        setState(() {
                          item['inventoryItemId'] = val;
                          item['price'] = selected.cost;
                          item['unit'] =
                              selected.unit; // Default to inventory unit
                          _calculateTotal();
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: "Item *",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                      validator: (val) => val == null ? "Select item" : null,
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text("Error loading items"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () => _removeItem(index),
                  tooltip: 'Remove Item',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Row 2: Qty and Unit
            Row(
              children: [
                // Quantity
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    key: ValueKey('qty_${index}_${item['quantity']}'),
                    initialValue: item['quantity'].toString(),
                    decoration: const InputDecoration(
                      labelText: "Qty",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      errorMaxLines: 1,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      item['quantity'] = int.tryParse(v) ?? 0;
                      _calculateTotal();
                    },
                    validator: (v) =>
                        (int.tryParse(v ?? '') ?? 0) < 1 ? "Min 1" : null,
                  ),
                ),
                const SizedBox(width: 8),

                // Unit dropdown
                Expanded(
                  flex: 4,
                  child: unitsAsync.when(
                    data: (units) {
                      // 💡 CAST LIST: Explicitly cast to List<UnitType>
                      final unitList = units.cast<UnitType>();

                      return DropdownButtonFormField<String>(
                        value: item['unit'],
                        items: unitList
                            .map<DropdownMenuItem<String>>(
                              // 💡 Explicit Map Type (FIX)
                              (u) => DropdownMenuItem<String>(
                                // 💡 Explicit Item Type (FIX)
                                value: u.name,
                                child: Text(u.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() => item['unit'] = val);
                        },
                        decoration: const InputDecoration(
                          labelText: "Unit",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text("Error loading units"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Row 3: Price and Total
            Row(
              children: [
                // Price
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    key: ValueKey('price_${index}_${item['price']}'),
                    initialValue: item['price'].toStringAsFixed(2),
                    decoration: InputDecoration(
                      labelText: "Unit Price",
                      hintText: selectedInventoryItem != null
                          ? 'Default: ${selectedInventoryItem.cost.toStringAsFixed(2)}'
                          : null,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      item['price'] = double.tryParse(v) ?? 0.0;
                      _calculateTotal();
                    },
                    validator: (v) => (double.tryParse(v ?? '') ?? 0.0) <= 0.0
                        ? "Price > 0"
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Total Display
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Row Total",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          formattedRowTotal,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCostDisplay() {
    final formattedTotal = NumberFormat.currency(
      symbol: 'TSh',
      decimalDigits: 0,
    ).format(totalCost);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "TOTAL ORDER COST:",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          Text(
            formattedTotal,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _isCreating ? null : _createOrder,
          icon: _isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded),
          label: Text(_isCreating ? "Creating..." : "Create PO"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
