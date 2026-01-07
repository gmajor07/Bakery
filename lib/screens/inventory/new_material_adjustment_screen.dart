import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/adjustment_provider.dart';
import '../../provider/material_provider.dart';
import '../../provider/inventory_provider.dart';
import '../../widgets/token_error_widget.dart';

class NewMaterialAdjustmentScreen extends ConsumerStatefulWidget {
  /// type = 'raw_material' OR 'supplies'
  final String type;

  const NewMaterialAdjustmentScreen({super.key, required this.type});

  @override
  ConsumerState<NewMaterialAdjustmentScreen> createState() =>
      _NewMaterialAdjustmentScreenState();
}

class _NewMaterialAdjustmentScreenState
    extends ConsumerState<NewMaterialAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();

  int? selectedItemId;
  String selectedAction = 'Add';
  String selectedUnit = 'kg';
  String? selectedReason;
  bool isLoading = false;

  final List<String> reasons = [
    'Damaged goods',
    'Stock correction',
    'New shipment',
    'Adjustment error',
  ];

  @override
  void initState() {
    super.initState();
    selectedUnit = 'kg';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = widget.type == 'raw_material'
        ? ref.watch(materialsProvider)
        : ref.watch(inventoryProvider(widget.type));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add ${widget.type == 'raw_material' ? 'Material' : 'Supply'} Adjustment',
        ),
      ),
      body: inventoryAsync.when(
        data: (items) {
          final List<dynamic> itemList = items as List<dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // ---------------- ITEM ----------------
                  const Text(
                    'Item',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: selectedItemId,
                    decoration: const InputDecoration(labelText: 'Select item'),
                    items: itemList
                        .map(
                          (item) => DropdownMenuItem<int>(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedItemId = value;
                        if (value != null) {
                          final selected = itemList.firstWhere(
                            (m) => m.id == value,
                          );
                          selectedUnit = selected.unit ?? selectedUnit;
                        }
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select an item' : null,
                  ),

                  const SizedBox(height: 20),

                  // ---------------- ACTION ----------------
                  const Text(
                    'Action',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedAction,
                    items: const [
                      DropdownMenuItem(value: 'Add', child: Text('Add')),
                      DropdownMenuItem(
                        value: 'Subtract',
                        child: Text('Subtract'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => selectedAction = value!),
                  ),

                  const SizedBox(height: 20),

                  // ---------------- UNIT ----------------
                  const Text(
                    'Unit',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedUnit,
                    items: const [
                      DropdownMenuItem(value: 'kg', child: Text('kg')),
                      DropdownMenuItem(value: 'l', child: Text('l')),
                      DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                    ],
                    onChanged: (value) => setState(() => selectedUnit = value!),
                  ),

                  const SizedBox(height: 20),

                  // ---------------- QUANTITY ----------------
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Enter quantity',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Quantity is required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      if (double.parse(value) <= 0) {
                        return 'Quantity must be greater than zero';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // ---------------- REASON ----------------
                  const Text(
                    'Reason',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    hint: const Text('Select reason'),
                    items: reasons
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedReason = value),
                    validator: (value) =>
                        value == null ? 'Please select a reason' : null,
                  ),

                  const SizedBox(height: 30),

                  // ---------------- BUTTONS ----------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade400,
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;

                                setState(() => isLoading = true);

                                try {
                                  await ref
                                      .read(adjustmentsApiServiceProvider)
                                      .createAdjustment(
                                        itemId: selectedItemId!,
                                        action: selectedAction,
                                        quantity: double.parse(
                                          _quantityController.text,
                                        ),
                                        unit: selectedUnit,
                                        reason: selectedReason!,
                                        type: widget.type,
                                      );

                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Material adjustment added successfully',
                                      ),
                                    ),
                                  );

                                  // refresh lists
                                  ref.invalidate(adjustmentsProvider);

                                  Navigator.pop(context);
                                } catch (e) {
                                  // Show full widget dialog instead of SnackBar
                                  if (!mounted) return;
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Error'),
                                      content: Text(e.toString()),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => isLoading = false);
                                  }
                                }
                              },
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Add Adjustment'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          final msg = error.toString().toLowerCase();
          if (msg.contains('401') ||
              msg.contains('unauthorized') ||
              msg.contains('token') ||
              msg.contains('expired')) {
            return const TokenErrorWidget();
          }
          return Center(child: Text('Error: $error'));
        },
      ),
    );
  }
}
