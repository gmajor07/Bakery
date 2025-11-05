import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/sale_item.dart';
import '../../provider/sales_provider.dart';
import '../../widgets/token_error_widget.dart';

class SaleDetailScreen extends ConsumerWidget {
  final int saleId;
  const SaleDetailScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(saleDetailProvider(saleId));

    return Scaffold(
      appBar: AppBar(title: Text('Sale #$saleId')),

      body: saleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          if (err.toString().toLowerCase().contains('token')) {
            return TokenErrorWidget(ref: ref);
          }
          return Center(child: Text('Error: $err'));
        },
        data: (sale) => _buildSaleDetails(context, sale),
      ),
    );
  }

  Widget _buildSaleDetails(BuildContext context, SaleItem sale) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('🧾 Sale Information', style: Theme.of(context).textTheme.titleLarge),
          const Divider(),
          _infoRow('Date', sale.date),
          _infoRow('Status', sale.status),
          _infoRow('Customer', sale.customer),
          _infoRow('Amount', 'TSh ${sale.amount.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          Text('🛒 Items Sold', style: Theme.of(context).textTheme.titleLarge),
          const Divider(),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Qty')),
                DataColumn(label: Text('Unit Price')),
                DataColumn(label: Text('Subtotal')),
              ],
              rows: sale.items.map((item) {
                return DataRow(cells: [
                  DataCell(Text(item.name)),
                  DataCell(Text(item.quantity.toString())),
                  DataCell(Text(item.price.toStringAsFixed(2))),
                  DataCell(Text((item.price * item.quantity).toStringAsFixed(2))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    ),
  );
}
