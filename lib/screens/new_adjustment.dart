import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/adjustment_provider.dart';
import '../provider/material_provider.dart';
import '../widgets/token_error_widget.dart';

class NewAdjustmentScreen extends ConsumerStatefulWidget {
  const NewAdjustmentScreen({super.key});

  @override
  ConsumerState<NewAdjustmentScreen> createState() =>
      _NewAdjustmentScreenState();
}

class _NewAdjustmentScreenState extends ConsumerState<NewAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();

  String? selectedItemId;
  String? selectedAction = 'Add';
  String? selectedUnit = 'kg';
  String? selectedReason;

  bool isLoading = false;

  final List<String> reasons = [
    'Damaged goods',
    'Stock correction',
    'New shipment',
    'Adjustment error',
  ];

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(materialsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Adjustment')),
      body: materialsAsync.when(
        data: (materials) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Item',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select item'),
                  value: selectedItemId,
                  items: materials
                      .map(
                        (m) => DropdownMenuItem<String>(
                          value: m.id.toString(),
                          child: Text(m.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedItemId = value;
                      final selected = materials.firstWhere(
                        (m) => m.id.toString() == value,
                        orElse: () => materials.first,
                      );
                      selectedUnit = selected.unit;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select an item' : null,
                ),
                const SizedBox(height: 20),

                const Text(
                  'Action',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButtonFormField<String>(
                  value: selectedAction,
                  items: ['Add', 'Subtract']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedAction = value),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Unit',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButtonFormField<String>(
                  value: selectedUnit,
                  items: ['kg', 'l', 'pcs']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedUnit = value),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Enter quantity',
                    hintText: 'Enter quantity in selected unit',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Quantity is required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                const Text(
                  'Reason',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  hint: const Text('Select reason'),
                  items: reasons
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedReason = value),
                  validator: (value) =>
                      value == null ? 'Please select a reason' : null,
                ),
                const SizedBox(height: 30),

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
                              if (_formKey.currentState!.validate()) {
                                setState(() => isLoading = true);
                                try {
                                  await ref
                                      .read(adjustmentsApiServiceProvider)
                                      .createAdjustment(
                                        itemId: selectedItemId!,
                                        action: selectedAction!,
                                        quantity: double.parse(
                                          _quantityController.text,
                                        ),
                                        unit: selectedUnit!,
                                        reason: selectedReason!,
                                      );

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Adjustment added successfully!',
                                        ),
                                      ),
                                    );
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => isLoading = false);
                                  }
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
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          final msg = error.toString().toLowerCase();
          if (msg.contains('401') ||
              msg.contains('unauthorized') ||
              msg.contains('token') ||
              msg.contains('expired')) {
            return TokenErrorWidget(ref: ref);
          }
          return Center(child: Text('Error: $error'));
        },
      ),
    );
  }
}
