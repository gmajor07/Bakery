import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/auth_provider.dart';
import '../../models/purchase_order.dart';
import '../../provider/purchase_orders_provider.dart';
import '../../purchases_model/inventory_item.dart';
import '../../purchases_model/unit_type.dart';
// Note: You must ensure the following models/providers exist in your project:
// - Supplier
// - InventoryItem
// - UnitType
// - suppliersProvider (AsyncValue<List<Supplier>>)
// - inventoryItemsProvider (AsyncValue<List<InventoryItem>>)
// - unitTypesProvider (AsyncValue<List<UnitType>>)

// 💡 NEW PROVIDERS for State Persistence and Search
// These should ideally be defined in a dedicated provider file (e.g., purchase_orders_provider.dart)
final purchaseOrderDraftProvider =
StateProvider<Map<String, dynamic>>((ref) => {
  'supplierId': null,
  'items': <Map<String, dynamic>>[],
});
final purchaseItemSearchQueryProvider = StateProvider<String>((ref) => '');

class CreatePurchaseOrderScreen extends ConsumerStatefulWidget {
  const CreatePurchaseOrderScreen({super.key});

  @override
  ConsumerState<CreatePurchaseOrderScreen> createState() =>
      _CreatePurchaseOrderScreenState();
}

class _CreatePurchaseOrderScreenState
    extends ConsumerState<CreatePurchaseOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();

  // Form State Variables
  int? selectedSupplierId;
  List<Map<String, dynamic>> items = [];
  // ❌ Removed: String notes = '';
  double totalCost = 0.0;
  bool _isCreating = false;

  // 🚨 Number formatter for Unit Price and currency (no decimals, with commas)
  final _priceFormatter = NumberFormat('#,##0');

  @override
  void initState() {
    super.initState();

    // 5. State Persistence: Load draft on init
    final draft = ref.read(purchaseOrderDraftProvider);
    if (draft['items']?.isNotEmpty == true) {
      // Load saved state
      selectedSupplierId = draft['supplierId'] as int?;
      items = (draft['items'] as List).cast<Map<String, dynamic>>().toList();
    } else {
      // Start fresh
      _addItem();
    }

    // 2. Item Search: Listener for search field
    _searchController.addListener(() {
      ref.read(purchaseItemSearchQueryProvider.notifier).state =
          _searchController.text.toLowerCase();
    });

    _calculateTotal();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ------------------------- STATE MANAGEMENT -------------------------

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

  // 5. State Persistence & 6. Cancellation Confirmation: Handle back button press
  Future<bool> _onWillPop() async {
    // If an order is being created, prevent pop.
    if (_isCreating) return false;

    // Check if any data has been entered
    final hasData = selectedSupplierId != null ||
        items.any((i) => i['inventoryItemId'] != null);

    if (!hasData) {
      // No data entered, allow pop immediately
      return true;
    }

    // Show confirmation dialog for cancellation
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order Creation?'),
        content: const Text(
            'Are you sure you want to exit? Your current data will be saved as a draft.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // No
            child: const Text('Continue Editing'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true), // Yes
            child: const Text('Save Draft and Exit'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Save draft before exiting
      _saveDraft();
      return true;
    }

    // User chose to continue editing
    return false;
  }

  void _saveDraft() {
    // Ensure form fields that aren't calculated are saved
    _formKey.currentState?.save();

    final draftPayload = {
      'supplierId': selectedSupplierId,
      // Only save items that have an inventory selected, or the first empty one
      'items': items
          .where((i) =>
      i['inventoryItemId'] != null ||
          (items.indexOf(i) == 0 && items.length == 1))
          .toList(),
    };
    ref.read(purchaseOrderDraftProvider.notifier).state = draftPayload;
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

      // 🚨 'notes' field removed from the payload
      final payload = {
        "supplierId": selectedSupplierId,
        "totalCost": totalCost,
        "status": "pending", // Default status for new POs
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

      // Invalidate providers and clear draft upon success
      ref.invalidate(purchaseOrdersProvider);
      ref.read(purchaseOrderDraftProvider.notifier).state = {
        'supplierId': null,
        'items': <Map<String, dynamic>>[],
      };

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

    // 5. Cancellation Confirmation: Wrap with PopScope
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Create Purchase Order")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader('Supplier Details'),
                  const SizedBox(height: 12),

                  // --- 1. Supplier Dropdown ---
                  _buildSupplierDropdown(suppliersAsync),
                  const SizedBox(height: 30),

                  // --- 2. Items Search and Header ---
                  _buildHeader('Order Items'),
                  const SizedBox(height: 12),
                  _buildItemSearch(), // Item Search: Search bar
                  const SizedBox(height: 16),

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

                  // --- 3. Total Cost Display ---
                  _buildTotalCostDisplay(),

                  const SizedBox(height: 30),

                  // --- 4. Action Buttons ---
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 2. Item Search: Search bar implementation
  Widget _buildItemSearch() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search Items',
        hintText: 'Type to filter items in dropdowns',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
            ref.read(purchaseItemSearchQueryProvider.notifier).state = '';
          },
        )
            : null,
        border: const OutlineInputBorder(),
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
        final supplierList = suppliers.cast<Supplier>();

        return DropdownButtonFormField<int>(
          value: selectedSupplierId,
          items: supplierList
              .map<DropdownMenuItem<int>>(
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
    final searchQuery = ref.watch(purchaseItemSearchQueryProvider);

    final List<InventoryItem> allInventoryItems =
        itemsAsync.valueOrNull?.cast<InventoryItem>() ?? [];

    final filteredInventoryItems = allInventoryItems
        .where((i) => i.name.toLowerCase().contains(searchQuery))
        .toList();

    final InventoryItem? selectedInventoryItem = allInventoryItems
        .cast<InventoryItem?>()
        .firstWhere(
          (i) => i?.id == item['inventoryItemId'],
      orElse: () => null,
    );

    // Fix for DropdownButton assertion: ensure selected item is in the filtered list
    if (selectedInventoryItem != null &&
        !filteredInventoryItems.any((i) => i.id == selectedInventoryItem.id)) {
      filteredInventoryItems.add(selectedInventoryItem);
    }

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
                      items: filteredInventoryItems
                          .map<DropdownMenuItem<int>>(
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
                        final selected = allInventoryItems.firstWhere(
                              (i) => i.id == val,
                        );
                        setState(() {
                          item['inventoryItemId'] = val;
                          item['price'] = selected.cost; // Set the default cost
                          item['unit'] = selected.unit;
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
                    error: (e, _) => const Text("Error loading items"),
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
                    // 3. Focus Fix: No ValueKey needed for Qty
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
                      final unitList = units.cast<UnitType>();

                      return DropdownButtonFormField<String>(
                        value: item['unit'],
                        items: unitList
                            .map<DropdownMenuItem<String>>(
                              (u) => DropdownMenuItem<String>(
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
                    error: (e, _) => const Text("Error loading units"),
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
                    // 🚨 Price Fix: Key forces rebuild when item ID changes
                    key: ValueKey('price_field_${item['inventoryItemId'] ?? index}'),

                    // Display the formatted price from the state
                    initialValue: _priceFormatter.format(item['price'] ?? 0.0),

                    decoration: InputDecoration(
                      labelText: "Price", // Renamed label
                      hintText: selectedInventoryItem != null
                          ? 'Default: ${_priceFormatter.format(selectedInventoryItem.cost)}'
                          : null,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      // Remove formatting characters before parsing
                      final rawValue = v.replaceAll(RegExp(r'[^\d.]'), '');
                      item['price'] = double.tryParse(rawValue) ?? 0.0;
                      _calculateTotal();
                    },
                    validator: (v) {
                      final rawValue = v?.replaceAll(RegExp(r'[^\d.]'), '');
                      return (double.tryParse(rawValue ?? '') ?? 0.0) <= 0.0
                          ? "Price > 0"
                          : null;
                    },
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
            "Total Order Cost:",
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

  // ------------------------- NEW HANDLER METHOD -------------------------

  Future<void> _onCancelOrder() async {
    // Show confirmation dialog to ensure user wants to discard the draft
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Order Draft?'),
        content: const Text(
            'Are you sure you want to cancel and discard this purchase order? All entered data will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // No
            child: const Text('Continue Editing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true), // Yes
            child: const Text('Discard Order'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Clear the draft state immediately
      ref.read(purchaseOrderDraftProvider.notifier).state = {
        'supplierId': null,
        'items': <Map<String, dynamic>>[],
      };

      // Clear search query
      ref.read(purchaseItemSearchQueryProvider.notifier).state = '';

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }


// ------------------------- UPDATED ACTION BUTTONS -------------------------

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          // 🚨 FIX: Call the new handler for confirmation and draft clearing
          onPressed: _isCreating ? null : _onCancelOrder,
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