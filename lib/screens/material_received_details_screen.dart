import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../provider/material_received_provider.dart';
import '../widgets/token_error_widget.dart';
import '../models/material_received.dart';

class MaterialDetailsScreen extends ConsumerWidget {
  final int receiptId;

  const MaterialDetailsScreen({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(materialReceiptDetailProvider(receiptId));

    return Scaffold(
      appBar: AppBar(title: const Text('Material Receiving Summary')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: receiptAsync.when(
            data: (receipt) {
              final dateStr = DateFormat(
                'dd-MM-yyyy',
              ).format(receipt.receivedDate);
              final totalCost = NumberFormat('#,##0').format(receipt.total);

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Material Receiving Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Status
                    Row(
                      children: [
                        const Text(
                          'Status: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          receipt.status,
                          style: TextStyle(
                            color: receipt.status.toLowerCase() == 'completed'
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Supplier
                    _infoRow('Supplier', receipt.supplierName),
                    _infoRow('Order Date', dateStr),
                    _infoRow('Received By', receipt.receivedBy),
                    _infoRow('Total Cost', 'Tsh $totalCost'),

                    const SizedBox(height: 20),
                    const Text(
                      'Ordered Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Items Table
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          Colors.grey[200],
                        ),
                        columns: const [
                          DataColumn(label: Text('Item Name')),
                          DataColumn(label: Text('Ordered Quantity')),
                          DataColumn(label: Text('Received Quantity')),
                          DataColumn(label: Text('Unit Cost')),
                          DataColumn(label: Text('Total Cost')),
                        ],
                        rows: receipt.items.map((item) {
                          return DataRow(
                            cells: [
                              DataCell(Text(item.name)),
                              DataCell(
                                Text(
                                  '${NumberFormat('#,##0').format(item.quantity)} ${item.unit}',
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${NumberFormat('#,##0').format(receipt.receivedQuantity)} ${item.unit}',
                                ),
                              ),
                              DataCell(
                                Text(
                                  NumberFormat('#,##0').format(item.unitPrice),
                                ),
                              ),
                              DataCell(
                                Text(NumberFormat('#,##0').format(item.total)),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) {
              final msg = err.toString().toLowerCase();
              if (msg.contains('401') ||
                  msg.contains('unauthorized') ||
                  msg.contains('token') ||
                  msg.contains('expired')) {
                return TokenErrorWidget(ref: ref);
              }
              return Center(child: Text('Error: $err'));
            },
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
