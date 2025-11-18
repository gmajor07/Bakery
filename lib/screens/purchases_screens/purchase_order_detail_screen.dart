import 'package:bak/provider/purchase_orders_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/purchase_inventory_item.dart';
import '../../models/purchase_order.dart';

class PurchaseOrderDetailScreen extends ConsumerStatefulWidget {
  final PurchaseOrder order;

  const PurchaseOrderDetailScreen({super.key, required this.order});

  @override
  ConsumerState<PurchaseOrderDetailScreen> createState() =>
      _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState
    extends ConsumerState<PurchaseOrderDetailScreen> {
  late PurchaseOrder _order;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd-MM-yyyy')
        .format(DateTime.parse(_order.createdAt));
    final totalFormatted =
    NumberFormat('#,###').format(_order.totalCost);

    return Scaffold(
      appBar: AppBar(title: Text('Purchase Order #${_order.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor(_order.status),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _order.status.toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 20),

            _buildLabelValue('Supplier', _order.supplier.name),
            _buildLabelValue('Order Date', date),
            _buildLabelValue('Total Cost', totalFormatted),

            if (_order.notes.isNotEmpty)
              _buildLabelValue('Notes', _order.notes),

            const SizedBox(height: 20),

            const Text(
              'Items List',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            _buildItemsTable(ref),

            const SizedBox(height: 20),

            _buildActionButtons(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15)),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildItemsTable(WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    return inventoryAsync.when(
      data: (inventoryItems) {
        final purchaseInventoryItems = inventoryItems
            .map((i) => PurchaseInventoryItem.fromInventoryItem(i))
            .toList();

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle:
                const TextStyle(fontWeight: FontWeight.bold),
                columns: const [
                  DataColumn(label: Text('Item')),
                  DataColumn(label: Text('Quantity')),
                  DataColumn(label: Text('Unit')),
                  DataColumn(label: Text('Unit Cost')),
                  DataColumn(label: Text('Total')),
                ],
                rows: _order.items.map((item) {
                  final qty =
                      int.tryParse(item.quantity.toString()) ?? 0;
                  final price =
                      int.tryParse(item.price.toString()) ?? 0;

                  final inventoryItem = purchaseInventoryItems.firstWhere(
                        (i) => i.id == item.inventoryItemId,
                    orElse: () => PurchaseInventoryItem(
                      id: 0,
                      name: item.itemName,
                      unit: '',
                    ),
                  );

                  final total = qty * price;

                  return DataRow(
                    cells: [
                      DataCell(Text(inventoryItem.name)),
                      DataCell(Text(qty.toString())),
                      DataCell(Text(inventoryItem.unit)),
                      DataCell(
                          Text(NumberFormat('#,###').format(price))),
                      DataCell(
                          Text(NumberFormat('#,###').format(total))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading inventory: $e'),
    );
  }

  Widget _buildActionButtons(WidgetRef ref) {
    final isPending = _order.status.toLowerCase() == 'pending';
    final isApproved = _order.status.toLowerCase() == 'approved';

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isPending)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: _isSubmitting ? null : () => _handleApprove(ref),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Approve Order'),
          ),

        if (isPending) const SizedBox(width: 8),

        if (isPending)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _isSubmitting ? null : () => _handleCancel(ref),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Cancel Order'),
          ),

        if (isApproved) const SizedBox(width: 8),

        if (isApproved)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: _isSubmitting ? null : () => _handleReceive(ref),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Receive Goods'),
          ),
      ],
    );
  }

  // --------------------- ACTION HANDLERS ------------------------

  Future<void> _handleApprove(WidgetRef ref) async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(purchaseOrdersApiServiceProvider)
          .updateOrderStatus(_order.id, 'approved');
      setState(() => _order = _order.copyWith(status: 'approved'));
      _show('Order Approved');
    } catch (e) {
      _show('Error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleCancel(WidgetRef ref) async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(purchaseOrdersApiServiceProvider)
          .updateOrderStatus(_order.id, 'cancelled');
      setState(() => _order = _order.copyWith(status: 'cancelled'));
      _show('Order Cancelled');
    } catch (e) {
      _show('Error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }


  Future<void> _handleReceive(WidgetRef ref) async {
    setState(() => _isSubmitting = true);
    try {
      final payloadItems = _order.items.map((i) {
        final qty = int.tryParse(i.quantity.toString()) ?? 0;
        return {
          "inventoryItemId": i.inventoryItemId,
          "receivedQuantity": qty,
        };
      }).toList();

      await ref
          .read(purchaseOrdersApiServiceProvider)
          .receiveGoods(orderId: _order.id, items: payloadItems);

      setState(() => _order = _order.copyWith(status: 'completed'));
      _show('Goods Received');
    } catch (e) {
      _show('Error receiving goods: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'approved':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
