import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../services/api_service.dart';
import '../models/production_items.dart';

class ProductionDetailScreen extends ConsumerWidget {
  final int productionId;

  const ProductionDetailScreen({super.key, required this.productionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.read(authProvider).accessToken ?? '';
    final api = ref.read(apiServiceProvider);
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return FutureBuilder<ProductionItem>(
      future: api.fetchProductionItemById(token, productionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Production Details')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to load production details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final item = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text('Production #${item.id}'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: isTablet
              ? _buildTabletLayout(context, item)
              : _buildMobileLayout(context, item),
        );
      },
    );
  }

  Widget _buildTabletLayout(BuildContext context, ProductionItem item) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Production Information Card
          Expanded(
            flex: 2,
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildProductionInfo(item),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Ingredients Card
          Expanded(
            flex: 3,
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildIngredientsSection(context, item),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, ProductionItem item) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Production Information Card
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildProductionInfo(item),
            ),
          ),

          // Ingredients Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildIngredientsSection(context, item),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionInfo(ProductionItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Production Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow('Product', item.product),
        const Divider(),
        _buildInfoRow('Quantity Produced', '${item.quantity} units'),
        const Divider(),
        _buildInfoRow('Date', _formatDate(item.date)),
        const Divider(),
        _buildInfoRow('Total Cost', 'Tsh ${item.cost.toStringAsFixed(0)}'),
        const Divider(),
        _buildInfoRow(
            'Cost per Unit',
            'Tsh ${(item.cost / item.quantity).toStringAsFixed(3)}'
        ),
        const Divider(),
        _buildProfitMarginRow(item.profitMargin),
        const Divider(),
        _buildInfoRow('Notes', item.notes ?? 'No notes provided'),
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
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

  Widget _buildProfitMarginRow(double margin) {
    final color = _getProfitMarginColor(margin);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Profit Margin',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color),
              ),
              child: Text(
                '${margin.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(BuildContext context, ProductionItem item) {
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ingredients Used',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 16),

        if (item.ingredientsDeducted.isEmpty) ...[
          const Center(
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'No ingredients were used',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ] else if (isTablet) ...[
          _buildIngredientsTable(item.ingredientsDeducted),
        ] else ...[
          _buildIngredientsList(item.ingredientsDeducted),
        ],
      ],
    );
  }

  Widget _buildIngredientsTable(List<dynamic> ingredients) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateColor.resolveWith(
              (states) => Colors.grey[50]!,
        ),
        columns: const [
          DataColumn(label: Text('Ingredient Name', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Amount Deducted', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Cost', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: ingredients.map((ing) {
          return DataRow(
            cells: [
              DataCell(Text(ing.name.toString())),
              DataCell(Text('${ing.amountDeducted} ${ing.unit}')),
              DataCell(Text(
                'Tsh ${ing.cost.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIngredientsList(List<dynamic> ingredients) {
    return Column(
      children: ingredients.map((ing) => _buildIngredientCard(ing)).toList(),
    );
  }

  Widget _buildIngredientCard(dynamic ingredient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ingredient.name.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Amount: ${ingredient.amountDeducted} ${ingredient.unit}'),
                Text(
                  'Cost: Tsh ${ingredient.cost.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getProfitMarginColor(double margin) {
    if (margin >= 20) return Colors.green;
    if (margin >= 10) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}