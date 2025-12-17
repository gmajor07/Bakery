import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // ⬅️ NEW: Import for number formatting
import '../services/api_service.dart';
import '../models/production_items.dart';

// ----------------------------------------------------------------------
// ⭐️ NEW: Formatting Helpers
// ----------------------------------------------------------------------

String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_TZ', // Using a locale that supports TSh/African currencies
    symbol: 'TSh',
    decimalDigits: 0, // No decimal points for TSh
  );
  return formatter.format(amount);
}

String formatNumber(double number) {
  // Use a locale that uses commas for thousands separator
  return NumberFormat('#,##0.##').format(number);
}


class ProductionDetailScreen extends ConsumerWidget {
  final int productionId;

  const ProductionDetailScreen({super.key, required this.productionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ⭐️ FIX: API Service Fix - Removed token from call here too,
    // relying on the interceptor handled in the previous turn.
    final api = ref.read(apiServiceProvider);
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return FutureBuilder<ProductionItem>(
      // ⭐️ FIX: Call api.fetchProductionItemById without token, assuming fix in ApiService
      future: api.fetchProductionItemById(productionId),
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
    // ⭐️ PRICE & QUANTITY FORMATTING APPLIED HERE
    final formattedCostPerUnit = formatCurrency(item.cost / item.quantity);

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
        // ⭐️ FORMATTED QUANTITY
        _buildInfoRow(
            'Quantity Produced',
            '${formatNumber(item.quantity.toDouble())} units'
        ),
        const Divider(),
        // ⭐️ FORMATTED DATE/TIME
        _buildInfoRow('Date', _formatDate(item.date)),
        const Divider(),
        // ⭐️ FORMATTED TOTAL COST
        _buildInfoRow('Total Cost', formatCurrency(item.cost)),
        const Divider(),
        // ⭐️ FORMATTED COST PER UNIT
        _buildInfoRow(
            'Cost per Unit',
            formattedCostPerUnit
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
          'Ingredients Deducted',
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
        headingRowColor: WidgetStateColor.resolveWith(
              (states) => Colors.grey[50]!,
        ),
        columns: const [
          DataColumn(label: Text('Ingredient Name', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Amount Deducted', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Cost', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: ingredients.map((ing) {
          // ⭐️ FORMATTED QUANTITY
          final formattedAmount = formatNumber(ing.amountDeducted.toDouble());

          return DataRow(
            cells: [
              DataCell(Text(ing.name.toString())),
              DataCell(Text('$formattedAmount ${ing.unit}')),
              DataCell(Text(
                // ⭐️ FORMATTED COST
                formatCurrency(ing.cost),
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
    // ⭐️ FORMATTED QUANTITY
    final formattedAmount = formatNumber(ingredient.amountDeducted.toDouble());
    // ⭐️ FORMATTED COST
    final formattedCost = formatCurrency(ingredient.cost);

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
                Text('Amount: $formattedAmount ${ingredient.unit}'),
                Text(
                  'Cost: $formattedCost',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.brown,
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
    if (margin >= 20) return Colors.brown;
    if (margin >= 10) return Colors.orange;
    return Colors.red;
  }

  // ⭐️ MODIFIED: To include hours, minutes, and seconds
  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm:ss').format(date);
  }
}