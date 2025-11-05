import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/purchase_order.dart';
import '../../provider/purchase_orders_provider.dart';
import '../../purchases_model/inventory_item.dart';

class PurchaseOrderDetailScreen extends StatelessWidget {
  final PurchaseOrder order;

  const PurchaseOrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat(
      'dd-MM-yyyy',
    ).format(DateTime.parse(order.createdAt));
    final totalFormatted = NumberFormat('#,###').format(order.totalCost);

    return Scaffold(
      appBar: AppBar(title: Text('Purchase Order ${order.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // 🔹 Order Summary title
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // 🔹 Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor(order.status),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                order.status,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Supplier
            _buildLabelValue('Supplier', order.supplier.name),

            // 🔹 Order Date
            _buildLabelValue('Order Date', date),

            // 🔹 Total Cost
            _buildLabelValue('Total Cost', totalFormatted),

            const SizedBox(height: 20),

            // 🔹 Items list
            const Text(
              'Items List',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, _) => _buildItemsTable(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget for label/value pairs
  Widget _buildLabelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15)),
          const Divider(),
        ],
      ),
    );
  }

  /// Items table
  Widget _buildItemsTable(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    return inventoryAsync.when(
      data: (inventoryItems) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                columns: const [
                  DataColumn(label: Text('Item')),
                  DataColumn(label: Text('Quantity')),
                  DataColumn(label: Text('Unit')),
                  DataColumn(label: Text('Unit Cost')),
                  DataColumn(label: Text('Total')),
                ],
                rows: order.items.map((item) {
                  final inventoryItem = inventoryItems.firstWhere(
                    (i) => i.id == item.inventoryItemId,
                    orElse: () => InventoryItem(
                      id: 0,
                      name: 'Unknown',
                      unit: '',
                      cost: 0,
                    ),
                  );

                  final total = item.quantity * item.price;

                  return DataRow(
                    cells: [
                      DataCell(Text(inventoryItem.name)),
                      DataCell(Text(item.quantity.toString())),
                      DataCell(Text(inventoryItem.unit)),
                      DataCell(Text(NumberFormat('#,###').format(item.price))),
                      DataCell(Text(NumberFormat('#,###').format(total))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading inventory: $e')),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
