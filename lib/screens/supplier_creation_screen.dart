// lib/screens/supplier_creation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../provider/suppliers_provider.dart';

class SupplierCreationScreen extends ConsumerStatefulWidget {
  const SupplierCreationScreen({super.key});

  @override
  ConsumerState<SupplierCreationScreen> createState() =>
      _SupplierCreationScreenState();
}

class _SupplierCreationScreenState
    extends ConsumerState<SupplierCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form Controllers
  final _nameController = TextEditingController();
  final _contactInfoController =
  TextEditingController(); // ⬅️ Renamed from _phoneController
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  // 🗑️ Removed _selectedStatus variable as it will be hardcoded to 'active'

  @override
  void dispose() {
    _nameController.dispose();
    _contactInfoController.dispose(); // ⬅️ Disposing the new controller
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // --- Form Submission Logic ---
  Future<void> _submitForm() async {
    // ⭐️ MODIFIED: Only validate fields that are truly required (Name)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final token = await ref.read(authProvider.notifier).getAccessToken();

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication failed. No token.')),
        );
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    final supplierData = {
      'name': _nameController.text.trim(),
      // Use null for empty strings for optional fields if your backend prefers it
      'contactInfo': _contactInfoController.text.trim(),
      'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      'status': 'active', // ⬅️ Hardcoded status to 'active'
    };

    try {
      // 💥 FIX: Retrieve the service instance via its provider to avoid WidgetRef/Ref error
      final apiService = ref.read(supplierApiService);

      await apiService.createSupplier(supplierData: supplierData, token: token);

      // FORCE REFRESH the main suppliers list
      ref.invalidate(suppliersProvider(token));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supplier created successfully!'),
            backgroundColor: Colors.brown,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create supplier: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Supplier',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 1,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name (REQUIRED)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (value) =>
                value!.isEmpty ? 'Name cannot be empty.' : null,
              ),
              const SizedBox(height: 16),

              // Contact Info (Phone) (REQUIRED)
              TextFormField(
                controller: _contactInfoController, // ⬅️ Used new controller
                decoration: const InputDecoration(
                  labelText: 'Phone *',
                ),
                keyboardType:
                TextInputType.text,
                // ⭐️ ADDED: Basic validation for contact info (assuming required)
                validator: (value) =>
                value!.isEmpty ? 'Contact information is required.' : null,
              ),
              const SizedBox(height: 16),

              // Email (OPTIONAL)
              TextFormField(
                controller: _emailController,
                // ⭐️ MODIFIED: Removed '*' from label
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                // ⭐️ MODIFIED: Removed validation, making it optional
                validator: (value) {
                  // Optional email validation: Check format only if value is provided
                  if (value != null && value.isNotEmpty && !value.contains('@')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address (OPTIONAL)
              TextFormField(
                controller: _addressController,
                // ⭐️ MODIFIED: Label is unchanged, validation removed
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
                // ⭐️ MODIFIED: Removed validation, making it optional
                validator: null,
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                    : const Text('Create Supplier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}