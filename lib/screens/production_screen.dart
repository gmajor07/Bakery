import 'package:bak/models/production_items.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../provider/production_provider.dart';
import '../services/api_service.dart';
import '../widgets/token_error_widget.dart';
import 'production_detail_screen.dart';

class ProductionScreen extends ConsumerStatefulWidget {
  const ProductionScreen({super.key});

  @override
  ConsumerState<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends ConsumerState<ProductionScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final productionAsync = ref.watch(productionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Production Records')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by product name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  setState(() => searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: productionAsync.when(
              data: (items) {
                // Remove duplicates by ID
                final uniqueItems = {
                  for (var item in items) item.id: item,
                }.values.toList();

                // Apply search filter
                final filtered = uniqueItems
                    .where(
                      (item) =>
                          item.product.toLowerCase().contains(searchQuery),
                    )
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No matching products found.'),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Product')),
                      DataColumn(label: Text('Quantity')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Cost')),
                      DataColumn(label: Text('Profit Margin')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: filtered.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(Text(item.product)),
                          DataCell(Text(item.quantity.toString())),
                          DataCell(
                            Text(item.date.toLocal().toString().split(' ')[0]),
                          ),
                          DataCell(Text('Tsh ${item.cost.toStringAsFixed(2)}')),
                          DataCell(
                            Text('${item.profitMargin.toStringAsFixed(2)}%'),
                          ),
                          DataCell(
                            Row(
                              children: [
                                // 🔹 View button
                                TextButton.icon(
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('View'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ProductionDetailScreen(item: item),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(width: 8),

                                // 🔹 Delete button
                                // 🔹 Delete button
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () async {
                                    // Ask for confirmation first
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Confirm Delete'),
                                        content: const Text(
                                          'Are you sure you want to delete this record?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        // ✅ Here we read the ApiService provider
                                        final apiService = ref.read(
                                          apiServiceProvider,
                                        );

                                        // 🔹 Call the delete API
                                        final token = await ref
                                            .read(authProvider.notifier)
                                            .getAccessToken();
                                        if (token == null)
                                          throw Exception('Token missing');

                                        await apiService.deleteProduction(
                                          item.id,
                                          token,
                                        );

                                        // Show success message
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Production record deleted',
                                            ),
                                          ),
                                        );

                                        // Refresh the production list
                                        ref.invalidate(productionProvider);
                                      } catch (e) {
                                        // Show error if delete fails
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to delete: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
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
                  return TokenErrorWidget(ref: ref);
                }

                return Center(child: Text('Login Again'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
