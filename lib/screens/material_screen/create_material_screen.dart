import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/material_provider.dart';

class CreateMaterialScreen extends ConsumerStatefulWidget {
  final String heading; // ⭐ dynamic heading
  final String type; // ⭐ passed type: raw_material OR supply

  const CreateMaterialScreen({
    super.key,
    required this.heading,
    required this.type,
    required String screenTitle,
  });

  @override
  ConsumerState<CreateMaterialScreen> createState() =>
      _CreateMaterialScreenState();
}

class _CreateMaterialScreenState extends ConsumerState<CreateMaterialScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _minLevelController = TextEditingController();
  // ⭐ NEW: Max Level Controller
  final TextEditingController _maxLevelController = TextEditingController();
  final TextEditingController _costController = TextEditingController();

  // ⭐ CHANGED: Initial value is null to start with a blank/hint
  String? _selectedUnit;
  bool _isLoading = false;

  // ⭐ CHANGED: Updated the display names to be cleaner, e.g., 'kg' instead of 'kilograms (kg)'
  final List<String> units = [
    "kg",
    "g",
    "l",
    "ml",
    "pcs",
    "pair",
    "m", // Added common units
    "box",
  ];

  Future<void> _submit() async {
    // ⭐ CHANGED: Validate form and check if unit is selected
    if (!_formKey.currentState!.validate() || _selectedUnit == null) {
      if (_selectedUnit == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('❌ Please select a unit')));
      }
      return;
    }
    setState(() => _isLoading = true);

    try {
      await ref
          .read(materialsProvider.notifier)
          .createMaterial(
            name: _nameController.text.trim(),
            type: widget.type, // ⭐ type controlled by parent screen
            unit: _selectedUnit!, // _selectedUnit is guaranteed not null here
            currentQuantity: double.tryParse(_quantityController.text) ?? 0,
            minLevel: int.tryParse(_minLevelController.text) ?? 0,
            // ⭐ NEW: Pass maxLevel
            maxLevel: int.tryParse(_maxLevelController.text) ?? 0,
            cost: double.tryParse(_costController.text) ?? 0,
          );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Saved successfully')));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.heading)), // ⭐ dynamic title
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 12),

              // ⭐ UNIT DROPDOWN - Starts with a blank/hint
              DropdownButtonFormField<String>(
                // value: _selectedUnit, // Removed value, as it can be null
                decoration: const InputDecoration(labelText: 'Unit'),
                // ⭐ Added the 'Please Select' item with a null value
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Please Select Unit'),
                  ),
                  ...units
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                ],
                onChanged: (String? v) => setState(() => _selectedUnit = v),
                // ⭐ Validator for unit selection
                validator: (v) => v == null ? 'Required' : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Current Quantity',
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _minLevelController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Minimum Level'),
              ),

              const SizedBox(height: 12),

              // ⭐ NEW: Max Level Input
              TextFormField(
                controller: _maxLevelController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Maximum Level'),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cost'),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
