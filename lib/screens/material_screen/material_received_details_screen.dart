import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../provider/material_received_provider.dart';
import '../../widgets/token_error_widget.dart';

class MaterialDetailsScreen extends ConsumerWidget {
  final int receiptId;

  const MaterialDetailsScreen({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(materialReceiptDetailProvider(receiptId));
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Receiving Summary'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: receiptAsync.when(
          data: (receipt) => isTablet
              ? _buildTabletLayout(receipt)
              : _buildMobileLayout(receipt),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _buildErrorWidget(err, ref),
        ),
      ),
    );
  }

  Widget _buildTabletLayout(dynamic receipt) {
    final dateStr = DateFormat('dd/MM/yyyy').format(receipt.receivedDate);
    final totalCost = NumberFormat('#,##0').format(receipt.total);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Material Receiving Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatusBadge(receipt.status),
                  const SizedBox(height: 16),
                  _buildInfoGrid(receipt.supplierName, dateStr, receipt.receivedBy, totalCost),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Items Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Received Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildItemsTable(receipt.items),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(dynamic receipt) {
    final dateStr = DateFormat('dd/MM/yyyy').format(receipt.receivedDate);
    final totalCost = NumberFormat('#,##0').format(receipt.total);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Receiving Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusBadge(receipt.status),
                  const SizedBox(height: 16),
                  _buildInfoList(receipt.supplierName, dateStr, receipt.receivedBy, totalCost),
                ],
              ),
            ),
          ),

          // Items Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Received Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildItemsList(receipt.items),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildInfoGrid(String supplier, String date, String receivedBy, String totalCost) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 4,
      children: [
        _buildInfoItem('Supplier', supplier),
        _buildInfoItem('Order Date', date),
        _buildInfoItem('Received By', receivedBy),
        _buildInfoItem('Total Cost', 'Tsh $totalCost'),
      ],
    );
  }

  Widget _buildInfoList(String supplier, String date, String receivedBy, String totalCost) {
    return Column(
      children: [
        _buildInfoRow('Supplier', supplier),
        const Divider(),
        _buildInfoRow('Order Date', date),
        const Divider(),
        _buildInfoRow('Received By', receivedBy),
        const Divider(),
        _buildInfoRow('Total Cost', 'Tsh $totalCost'),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(List<dynamic> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateColor.resolveWith(
              (states) => Colors.grey[50]!,
        ),
        columns: const [
          DataColumn(label: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Unit Cost', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: items.map((item) {
          return DataRow(
            cells: [
              DataCell(
                Tooltip(
                  message: item.name.isNotEmpty ? item.name : '-',
                  child: Text(
                    item.name.isNotEmpty ? item.name : '-',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              DataCell(Text(NumberFormat('#,##0').format(item.quantity))),
              DataCell(Text(NumberFormat('#,##0').format(item.unitPrice))),
              DataCell(
                Text(
                  NumberFormat('#,##0').format(item.total),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemsList(List<dynamic> items) {
    return Column(
      children: items.map((item) => _buildItemCard(item)).toList(),
    );
  }

  Widget _buildItemCard(dynamic item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name.isNotEmpty ? item.name : 'Unnamed Item',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              children: [
                _buildItemDetail('Quantity', NumberFormat('#,##0').format(item.quantity)),
                _buildItemDetail('Unit Cost', NumberFormat('#,##0').format(item.unitPrice)),
                _buildItemDetail('Total', NumberFormat('#,##0').format(item.total)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(Object error, WidgetRef ref) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('401') ||
        msg.contains('unauthorized') ||
        msg.contains('token') ||
        msg.contains('expired')) {
      return TokenErrorWidget();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error loading receipt details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            onPressed: () => ref.invalidate(materialReceiptDetailProvider(receiptId)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.brown;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}