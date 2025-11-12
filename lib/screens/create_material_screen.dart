import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/material_provider.dart';

class CreateMaterialScreen extends ConsumerStatefulWidget {
  const CreateMaterialScreen({super.key});

  @override
  ConsumerState<CreateMaterialScreen> createState() =>
      _CreateMaterialScreenState();
}

class _CreateMaterialScreenState extends ConsumerState<CreateMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _minLevelController = TextEditingController();
  final TextEditingController _costController = TextEditingController();

  String _selectedType = 'raw_material';
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(materialsProvider.notifier)
          .createMaterial(
            name: _nameController.text.trim(),
            type: _selectedType,
            unit: _unitController.text.trim(),
            currentQuantity: double.tryParse(_quantityController.text) ?? 0,
            minLevel: int.tryParse(_minLevelController.text) ?? 0,
            cost: double.tryParse(_costController.text) ?? 0,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Material created successfully')),
      );

      // Optional: Pop back to list screen
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to create material: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Material')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Material Name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter material name' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(
                    value: 'raw_material',
                    child: Text('Raw Material'),
                  ),
                  DropdownMenuItem(value: 'supply', child: Text('Supply')),
                ],
                onChanged: (v) => setState(() => _selectedType = v!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(labelText: 'Unit (e.g. kg)'),
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
                    : const Text('Save Material'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
