import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../provider/material_received_provider.dart';

class MaterialDetailsScreen extends ConsumerWidget {
  final int receiptId;
  const MaterialDetailsScreen({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(materialDetailProvider(receiptId));

    return Scaffold(
      appBar: AppBar(title: const Text('Material Receiving Summary')),
      body: detailAsync.when(
        data: (r) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Summary
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    r.status.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          r.status.toLowerCase() == 'completed'
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Spacer(),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Supplier',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                r.supplierName,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Order Date',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('dd-MM-yyyy').format(r.receivedDate),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Total Cost',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                r.total.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ordered Items',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Item Name')),
                        DataColumn(label: Text('Quantity')),
                        DataColumn(label: Text('Unit Price')),
                        DataColumn(label: Text('Total')),
                      ],
                      rows: r.items.map((it) {
                        return DataRow(
                          cells: [
                            DataCell(Text(it.name)),
                            DataCell(
                              Text(
                                '${it.quantity.toStringAsFixed(0)} ${it.unit}',
                              ),
                            ),
                            DataCell(Text(it.unitPrice.toStringAsFixed(0))),
                            DataCell(Text(it.total.toStringAsFixed(0))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
