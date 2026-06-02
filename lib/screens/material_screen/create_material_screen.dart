import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for inputFormatters
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Required for number formatting

import '../../provider/material_provider.dart';

class CreateMaterialScreen extends ConsumerStatefulWidget {
  final String heading;
  final String type;

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
  final TextEditingController _maxLevelController = TextEditingController();
  final TextEditingController _costController = TextEditingController();

  String? _selectedUnit;
  bool _isLoading = false;

  // Manual Units List
  final List<String> units = ["pieces", "kg", "g", "l", "ml"];

  // Helper to remove commas before parsing to a number
  double _parseNum(String text) {
    final cleanText = text.replaceAll(',', '');
    return double.tryParse(cleanText) ?? 0;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedUnit == null) {
      if (_selectedUnit == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Please select a unit')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(materialsProvider.notifier).createMaterial(
        name: _nameController.text.trim(),
        type: widget.type,
        unit: _selectedUnit!,
        // Parsing values and removing commas
        currentQuantity: _parseNum(_quantityController.text),
        minLevel: _parseNum(_minLevelController.text).toInt(),
        maxLevel: _parseNum(_maxLevelController.text).toInt(),
        cost: _parseNum(_costController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.heading)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 1. Item Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Item Name is required' : null,
              ),

              const SizedBox(height: 12),

              // 2. Unit Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit *',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Select Unit', style: TextStyle(color: Colors.grey)),
                  ),
                  ...units.map((u) => DropdownMenuItem(value: u, child: Text(u))),
                ],
                onChanged: (String? v) => setState(() => _selectedUnit = v),
                validator: (v) => v == null ? 'Unit is required' : null,
              ),

              const SizedBox(height: 12),

              // 3. Unit Cost
              TextFormField(
                controller: _costController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Unit Cost *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v!.isEmpty) return 'Unit Cost is required';
                  if (double.tryParse(v.replaceAll(',', '')) == null) {
                    return 'Must be a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),
              const Divider(),
              const Text("Inventory Details (Optional)",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),

              // 4. Current Quantity
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Current Quantity',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // 5. Min Level
              TextFormField(
                controller: _minLevelController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Min Level (Safety Stock)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // 6. Max Level
              TextFormField(
                controller: _maxLevelController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Max Level (Capacity)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add material', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Input Formatter for Comma Separation ---
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###,###.##');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    // Remove old commas
    String newValueText = newValue.text.replaceAll(',', '');

    // Check if the current typing is just a decimal point
    if (newValueText.endsWith('.')) return newValue;

    double? value = double.tryParse(newValueText);
    if (value == null) return oldValue;

    String newText = _formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}