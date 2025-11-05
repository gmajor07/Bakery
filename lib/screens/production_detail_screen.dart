import 'package:flutter/material.dart';
import '../models/production_items.dart';

class ProductionDetailScreen extends StatelessWidget {
  final ProductionItem item;

  const ProductionDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Production #${item.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Production Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 🔹 Basic Info
            _buildLabelValue('Product', item.product),
            _buildLabelValue('Quantity Produced', item.quantity.toString()),
            _buildLabelValue('Date', _formatDate(item.date)),
            _buildLabelValue('Cost', 'Tsh ${item.cost.toStringAsFixed(0)}'),
            _buildLabelValue(
              'Cost per Product',
              'Tsh ${(item.cost / item.quantity).toStringAsFixed(2)}',
            ),
            _buildLabelValue(
              'Profit Margin',
              '${item.profitMargin.toStringAsFixed(2)}%',
            ),
            _buildLabelValue('Notes', item.notes ?? 'N/A'),

            const SizedBox(height: 20),
            const Text(
              'Ingredients Deducted',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // 🔹 Ingredients table
            item.ingredientsDeducted.isEmpty
                ? const Text('No ingredients deducted')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Ingredient Name')),
                        DataColumn(label: Text('Amount Deducted')),
                        DataColumn(label: Text('Cost')),
                      ],
                      rows: item.ingredientsDeducted.map((ing) {
                        return DataRow(
                          cells: [
                            DataCell(Text(ing.name)),
                            DataCell(Text('${ing.amountDeducted} ${ing.unit}')),
                            DataCell(
                              Text('Tsh ${ing.cost.toStringAsFixed(0)}'),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  /// Helper for displaying label/value pairs
  Widget _buildLabelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }
}
