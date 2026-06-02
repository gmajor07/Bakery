import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/adjustment_provider.dart';
import '../../provider/products_provider.dart';
import '../../widgets/token_error_widget.dart';

class NewProductAdjustmentScreen extends ConsumerStatefulWidget {
  const NewProductAdjustmentScreen({super.key});

  @override
  ConsumerState<NewProductAdjustmentScreen> createState() =>
      _NewProductAdjustmentScreenState();
}

class _NewProductAdjustmentScreenState
    extends ConsumerState<NewProductAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();

  int? selectedProductId;
  String? selectedReason;
  bool isLoading = false;

  final List<String> reasons = [
    'Damaged goods',
    'Stock correction',
    'New shipment',
    'Adjustment error',
    'Expired Goods',
    'Wrong Entry',
  ];

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Product Adjustment')),
      body: productsAsync.when(
        data: (products) => RefreshIndicator(
          onRefresh: () => ref.refresh(productsProvider.future),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 10),
                  const Text('Product',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<int>(
                    decoration:
                    const InputDecoration(labelText: 'Select product'),
                    initialValue: selectedProductId,
                    items: products
                        .map((product) => DropdownMenuItem<int>(
                      value: product.id,
                      child: Text(product.name),
                    ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedProductId = value),
                    validator: (value) =>
                    value == null ? 'Please select a product' : null,
                  ),

                  // ✅ Show current stock
                  if (selectedProductId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                      child: Text(
                        'Current Stock: ${products.firstWhere((p) => p.id == selectedProductId).quantity}',
                        style:
                        const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),

                  TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity to Reduce',
                      hintText: 'Enter quantity to reduce',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Quantity is required';
                      final qty = int.tryParse(value);
                      if (qty == null) return 'Invalid number';
                      if (selectedProductId != null) {
                        final stock = products
                            .firstWhere((p) => p.id == selectedProductId)
                            .quantity;
                        if (qty > stock) return 'Cannot reduce more than current stock ($stock)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Reason',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
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
                                  .createProductAdjustment(
                                productId: selectedProductId!,
                                quantityToReduce: int.parse(
                                    _quantityController.text),
                                reason: selectedReason!,
                              );

                              if (mounted) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Success'),
                                    content: const Text(
                                        'Product adjustment added successfully!'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                                // Close screen after success
                                Future.delayed(
                                    const Duration(milliseconds: 500),
                                        () => Navigator.pop(context));
                              }
                            } catch (e) {
                              if (!mounted) return;
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Error'),
                                  content: Text(e.toString()),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            } finally {
                              if (mounted) setState(() => isLoading = false);
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
        ),
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
