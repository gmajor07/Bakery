import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/purchase_orders_provider.dart';

class CreatePurchaseOrderScreen extends ConsumerStatefulWidget {
  const CreatePurchaseOrderScreen({super.key});

  @override
  ConsumerState<CreatePurchaseOrderScreen> createState() =>
      _CreatePurchaseOrderScreenState();
}

class _CreatePurchaseOrderScreenState
    extends ConsumerState<CreatePurchaseOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  int? selectedSupplierId;
  List<Map<String, dynamic>> items = [];
  double totalCost = 0.0;

  void _addItem() {
    setState(() {
      items.add({
        'inventoryItemId': null,
        'quantity': 1,
        'unit': null,
        'price': 0.0,
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    totalCost = items.fold(
      0.0,
      (sum, item) => sum + ((item['quantity'] ?? 0) * (item['price'] ?? 0.0)),
    );
  }

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final api = ref.read(purchaseOrdersApiServiceProvider);

    try {
      await api.createPurchaseOrder({
        "supplierId": selectedSupplierId,
        "totalCost": totalCost,
        "status": "pending",
        "notes": "",
        "items": items
            .where((i) => i['inventoryItemId'] != null)
            .map(
              (i) => {
                "inventoryItemId": i['inventoryItemId'],
                "quantity": i['quantity'],
                "unit": i['unit'],
                "price": i['price'],
              },
            )
            .toList(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Purchase order created successfully!"),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Failed to create order: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Supplier *",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                suppliersAsync.when(
                  data: (suppliers) => DropdownButtonFormField<int>(
                    value: selectedSupplierId,
                    items: suppliers
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => selectedSupplierId = val),
                    decoration: const InputDecoration(
                      hintText: "Select a supplier",
                    ),
                    validator: (val) =>
                        val == null ? "Please select supplier" : null,
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text("Error loading suppliers"),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Items *",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          // Inventory item dropdown
                          Expanded(
                            flex: 3,
                            child: itemsAsync.when(
                              data: (inventoryItems) =>
                                  DropdownButtonFormField<int>(
                                    value: item['inventoryItemId'],
                                    items: inventoryItems
                                        .map(
                                          (i) => DropdownMenuItem(
                                            value: i.id,
                                            child: Text(i.name),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      final selected = inventoryItems
                                          .firstWhere((i) => i.id == val);
                                      setState(() {
                                        item['inventoryItemId'] = val;
                                        item['price'] = selected.cost;
                                        item['unit'] = selected.unit;
                                        _calculateTotal();
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      hintText: "Select item",
                                    ),
                                    validator: (val) =>
                                        val == null ? "Select item" : null,
                                  ),
                              loading: () => const CircularProgressIndicator(),
                              error: (e, _) => Text("Error loading items"),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Quantity
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              key: ValueKey('qty_${index}_${item['quantity']}'),
                              initialValue: item['quantity'].toString(),
                              decoration: const InputDecoration(
                                hintText: "Qty",
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                item['quantity'] = int.tryParse(v) ?? 1;
                                _calculateTotal();
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Unit dropdown
                          Expanded(
                            flex: 2,
                            child: unitsAsync.when(
                              data: (units) => DropdownButtonFormField<String>(
                                value: item['unit'],
                                items: units
                                    .map(
                                      (u) => DropdownMenuItem(
                                        value: u.name,
                                        child: Text(u.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    item['unit'] = val;
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: "Unit",
                                ),
                              ),
                              loading: () => const CircularProgressIndicator(),
                              error: (e, _) => Text("Error loading units"),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Price
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              key: ValueKey('price_${index}_${item['price']}'),
                              initialValue: item['price'].toString(),
                              decoration: const InputDecoration(
                                hintText: "Price",
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                item['price'] = double.tryParse(v) ?? 0.0;
                                _calculateTotal();
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.pinkAccent,
                            ),
                            onPressed: () => _removeItem(index),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Item"),
                ),
                const SizedBox(height: 16),
                Text(
                  "Total Cost: TSh ${totalCost.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _createOrder,
                      icon: const Icon(Icons.add),
                      label: const Text("Create PO"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
