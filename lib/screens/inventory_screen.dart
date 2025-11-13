import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/inventory_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Correct usage: specify which inventory type you want
    final inventoryAsync = ref.watch(inventoryProvider('supplies'));
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Supplies Inventory')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search + Add Supplies
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search supplies...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) =>
                        ref.read(searchQueryProvider.notifier).state = value,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to add supply page
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Supplies'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Inventory Table
            Expanded(
              child: inventoryAsync.when(
                data: (items) {
                  final filtered = items.where((item) {
                    final query = searchQuery.toLowerCase();
                    return item.name.toLowerCase().contains(query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No supplies found.'));
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Item Name')),
                        DataColumn(label: Text('Unit')),
                        DataColumn(label: Text('Quantity')),
                        DataColumn(label: Text('Min Level')),
                        DataColumn(label: Text('Cost')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: filtered.map((item) {
                        return DataRow(
                          cells: [
                            DataCell(Text(item.name)),
                            DataCell(Text(item.unit)),
                            DataCell(Text(item.currentQuantity.toString())),
                            DataCell(Text(item.minLevel.toString())),
                            DataCell(Text(item.cost.toString())),
                            DataCell(Text(item.status)),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) =>
                    Center(child: Text('Error loading inventory: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
