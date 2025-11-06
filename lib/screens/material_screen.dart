import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/material_provider.dart';
import '../widgets/token_error_widget.dart';

class MaterialsScreen extends ConsumerWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(materialsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Materials')),
      body: materialsAsync.when(
        data: (materials) {
          if (materials.isEmpty) {
            return const Center(child: Text('No materials found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
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
              rows: materials.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item.name)),
                    DataCell(Text(item.unit)),
                    DataCell(Text(item.quantity.toStringAsFixed(3))),
                    DataCell(Text(item.minLevel.toString())),
                    DataCell(Text(item.cost.toStringAsFixed(0))),
                    DataCell(
                      Text(
                        item.status,
                        style: TextStyle(
                          color: item.status == 'Out of stock'
                              ? Colors.red
                              : item.lowStock
                              ? Colors.orange
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
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
          return Center(child: Text('Error: ${error.toString()}'));
        },
      ),
    );
  }
}
