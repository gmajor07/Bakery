// customer_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/customer_provider.dart';

class CustomerCreationScreen extends ConsumerStatefulWidget {
  const CustomerCreationScreen({super.key});

  @override
  ConsumerState<CustomerCreationScreen> createState() => _CustomerCreationScreenState();
}

class _CustomerCreationScreenState extends ConsumerState<CustomerCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Information Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // ⭐️ EXTRA INFORMATION STATE/CONTROLLERS
  String _status = 'Active'; // Default to Active
  final _creditLimitController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isCredit = false;

  @override
  void initState() {
    super.initState();
    // Initialize credit limit controller with 0.00 for good UX
    _creditLimitController.text = '0';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Safely parse credit limit
    final double creditLimit = _isCredit
        ? double.tryParse(_creditLimitController.text) ?? 0.0
        : 0.0;

    // 1. Build the request body map (matching your POST request body)
    final customerData = {
      // Basic Information
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),

      // Extra Information
      'isCredit': _isCredit,
      'status': _status, // Use the selected status
      'creditLimit': creditLimit, // Use the parsed limit
      'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(), // Optional notes
    };

    try {
      // 2. Call the notifier to create the customer
      await ref.read(customerCreationProvider.notifier).createCustomer(customerData);

      // 3. Success: Show message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Customer created successfully!')),
        );
        // Invalidate the customers list provider if necessary (assuming you have one)
        // ref.invalidate(customersListProvider);
        Navigator.of(context).pop();
      }
    } catch (e) {
      // 4. Error: Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to create customer: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    // ⭐️ Dispose new controllers
    _creditLimitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ⭐️ NEW: Helper to build section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary, // Using primary color for emphasis
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerCreationProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Create New Customer ➕')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ===============================================
              // 1. BASIC INFORMATION SECTION
              // ===============================================
              _buildSectionHeader('Basic Information'),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email *'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
              ),

              // ===============================================
              // 2. EXTRA INFORMATION SECTION
              // ===============================================
              _buildSectionHeader('Extra Information'),

              // 2.1 Status Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                ],
                onChanged: isLoading ? null : (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _status = newValue;
                    });
                  }
                },
                validator: (value) => value == null ? 'Status is required' : null,
              ),

              const SizedBox(height: 16),

              // 2.2 Allow Credit Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Allow Credit?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: _isCredit,
                    onChanged: isLoading ? null : (bool value) {
                      setState(() {
                        _isCredit = value;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2.3 Credit Limit Input (Conditional)
              if (_isCredit) ...[
                TextFormField(
                  controller: _creditLimitController,
                  decoration: const InputDecoration(
                    labelText: 'Credit Limit *',
                    prefixText: 'TSh ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (!_isCredit) return null; // If credit is disabled, validation is skipped
                    if (value == null || value.isEmpty) {
                      return 'Credit Limit is required when credit is allowed';
                    }
                    if (double.tryParse(value) == null || double.tryParse(value)! <= 0) {
                      return 'Enter a valid positive number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // 2.4 Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Any special notes about customer'),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton.icon(
                onPressed: isLoading ? null : _submitForm,
                icon: isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.save),
                label: Text(isLoading ? 'Creating...' : 'Create Customer'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}