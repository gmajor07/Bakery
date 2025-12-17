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
  final TextEditingController _costController = TextEditingController();

  String _selectedUnit = 'kg'; // default unit
  bool _isLoading = false;

  final List<String> units = [
    "kilograms (kg)",
    "grams (g)",
    "liters (l)",
    "milliliters (ml)",
    "piece (pcs)",
    "pair",
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref
          .read(materialsProvider.notifier)
          .createMaterial(
            name: _nameController.text.trim(),
            type: widget.type, // ⭐ type controlled by parent screen
            unit: _selectedUnit,
            currentQuantity: double.tryParse(_quantityController.text) ?? 0,
            minLevel: int.tryParse(_minLevelController.text) ?? 0,
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

              // ⭐ UNIT DROPDOWN
              DropdownButtonFormField<String>(
                value: units.first,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: units
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedUnit = v!),
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
