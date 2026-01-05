import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// NOTE: You must ensure this import path is correct for your project
import '../provider/inventory_provider.dart';
import '../widgets/token_error_widget.dart';
import 'material_screen/create_material_screen.dart';

// --- TOP-LEVEL PROVIDERS AND HELPER FUNCTIONS ---

final searchQueryProvider = StateProvider<String>((ref) => '');

// Helper to capitalize the first letter of a word (used for status)
String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}

// Global Formatters (Defined once for efficiency)
final _currencyFormat = NumberFormat.currency(
  locale: 'en_US',
  symbol: 'Tsh ',
  decimalDigits: 0,
);

// Formatter for quantities and min levels (no decimals, use comma separators)
final _qtyFormat = NumberFormat('#,##0', 'en_US');

// Filters the list based on the search query
List<dynamic> _filterItems(List<dynamic> items, String searchQuery) {
  if (searchQuery.isEmpty) return items;

  final query = searchQuery.toLowerCase();
  return items.where((item) {
    // Assuming 'item' objects have 'name', 'unit', and 'status' properties
    return item.name.toLowerCase().contains(query) ||
        item.unit.toLowerCase().contains(query) ||
        item.status.toLowerCase().contains(query);
  }).toList();
}

// 🎯 CALCULATES STATUS: The single source of truth based only on quantity
String _calculateInventoryStatus(double currentQuantity, double minLevel) {
  if (currentQuantity <= 0) {
    return 'Critical';
  } else if (currentQuantity <= minLevel) {
    return 'Low Stock';
  } else {
    return 'In Stock';
  }
}

// Determines the final displayed text (Capitalization and "Critical" naming)
String _getDisplayStatus(double currentQuantity, double minLevel) {
  final rawStatus = _calculateInventoryStatus(currentQuantity, minLevel);
  final lowerStatus = rawStatus.toLowerCase();

  if (lowerStatus == 'low stock') {
    return 'Critical';
  }

  // Capitalize other statuses (e.g., 'in stock' -> 'In Stock')
  final words = lowerStatus.split(' ');
  return words.map(_capitalize).join(' ');
}

// Determines the color based on the calculated status
Color _getStatusColor(double currentQuantity, double minLevel) {
  final status = _calculateInventoryStatus(currentQuantity, minLevel).toLowerCase();

  switch (status) {
    case 'in stock':
      return Colors.brown;
    case 'low stock':
      return Colors.red.shade700; // Strong red for critical
    case 'critical':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

// Quantity color logic (stronger color for critical levels)
Color _getQuantityColor(double currentQuantity, double minLevel) {
  if (currentQuantity <= minLevel) return Colors.red.shade700;
  if (currentQuantity <= minLevel * 2) return Colors.orange;
  return Colors.brown;
}


// --- InventoryScreen Widget ---

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  void _navigateToAddSupply(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateMaterialScreen(
          heading: "Add Supplies",
          type: "supply",
          screenTitle: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider('supplies'));
    final searchQuery = ref.watch(searchQueryProvider);
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
        appBar: AppBar(
          title: const Text('Supplies List'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Column(
          children: [
            _buildHeaderSection(context, ref, isTablet),
            _buildResultsCount(inventoryAsync, searchQuery),
            Expanded(
              child: inventoryAsync.when(
                data: (items) => _buildInventoryDisplay(
                  context,
                  items,
                  searchQuery,
                  isTablet,
                  ref,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) {
                  final msg = error.toString().toLowerCase();
                  if (msg.contains('401') ||
                      msg.contains('unauthorized') ||
                      msg.contains('token') ||
                      msg.contains('expired')) {
                    return const TokenErrorWidget();
                  }
                  return Center(child: Text('Error: $error'));
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateToAddSupply(context),
          child: const Icon(Icons.add),
        )
    );
  }

  Widget _buildHeaderSection(
      BuildContext context,
      WidgetRef ref,
      bool isTablet,
      ) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isTablet
            ? _buildTabletHeader(context, ref)
            : _buildMobileHeader(context, ref),
      ),
    );
  }

  Widget _buildTabletHeader(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search supplies...',
              hintText: 'Search by item name',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  ref.read(searchQueryProvider.notifier).state = '';
                },
              ),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) =>
            ref.read(searchQueryProvider.notifier).state = value,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Search supplies...',
            hintText: 'Search by item name',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) =>
          ref.read(searchQueryProvider.notifier).state = value,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildResultsCount(
      AsyncValue<List<dynamic>> inventoryAsync,
      String searchQuery,
      ) {
    return inventoryAsync.when(
      data: (items) {
        final filtered = _filterItems(items, searchQuery);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${filtered.length} item${filtered.length != 1 ? 's' : ''} found',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildInventoryDisplay(
      BuildContext context,
      List<dynamic> items,
      String searchQuery,
      bool isTablet,
      WidgetRef ref,
      ) {
    final filtered = _filterItems(items, searchQuery);

    if (filtered.isEmpty) {
      return _buildEmptyState(context, searchQuery, ref);
    }

    return isTablet
        ? _buildTableView(context, filtered)
        : _buildMobileView(filtered);
  }

  // --- Tablet/Desktop View (DataTable) ---
  Widget _buildTableView(BuildContext context, List<dynamic> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: DataTable(
          headingRowColor: WidgetStateColor.resolveWith(
                (states) => Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          ),
          columns: const [
            DataColumn(
              label: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Min Level', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Cost', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          rows: items.map((item) {
            // Get consistent, calculated values
            final displayQty = _qtyFormat.format(item.currentQuantity);
            final displayMinLevel = _qtyFormat.format(item.minLevel);
            final displayCost = _currencyFormat.format(item.cost);

            // Use calculated status for display and color
            final displayStatus = _getDisplayStatus(item.currentQuantity, item.minLevel);
            final statusColor = _getStatusColor(item.currentQuantity, item.minLevel);

            return DataRow(
              cells: [
                DataCell(
                  Tooltip(
                    message: item.name,
                    child: Text(
                      item.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                DataCell(Text(item.unit)),
                DataCell(
                  Text(
                    displayQty,
                    style: TextStyle(
                      color: _getQuantityColor(
                        item.currentQuantity,
                        item.minLevel,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(Text(displayMinLevel)),
                DataCell(Text(displayCost)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      // Use calculated status color
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      displayStatus, // Use calculated status text
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- Mobile View (ListView) ---
  Widget _buildMobileView(List<dynamic> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        final displayQty = _qtyFormat.format(item.currentQuantity);
        final displayMinLevel = _qtyFormat.format(item.minLevel);
        final displayCost = _currencyFormat.format(item.cost);

        // Use calculated status for display and color
        final displayStatus = _getDisplayStatus(item.currentQuantity, item.minLevel);
        final statusColor = _getStatusColor(item.currentQuantity, item.minLevel);

        // Determine if it's critical (used for the warning banner)
        final isCritical = item.currentQuantity <= item.minLevel;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with name and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        // Use calculated status color
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        displayStatus, // Use calculated status text
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Item details in grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3,
                  children: [
                    _buildDetailItem('Unit', item.unit),
                    _buildDetailItem(
                      'Quantity',
                      displayQty,
                      valueColor: _getQuantityColor(
                        item.currentQuantity,
                        item.minLevel,
                      ),
                    ),
                    _buildDetailItem('Min Level', displayMinLevel),
                    _buildDetailItem(
                      'Cost',
                      displayCost,
                    ),
                  ],
                ),

                // Quantity warning if low (Critical)
                if (isCritical)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Critical - Immediate reorder needed',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
      BuildContext context,
      String searchQuery,
      WidgetRef ref,
      ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? 'No supplies found' : 'No matching supplies',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Add your first supply to get started'
                : 'Try adjusting your search terms',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          if (searchQuery.isEmpty)
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Supply'),
              onPressed: () =>
                  _navigateToAddSupply(context),
            ),
        ],
      ),
    );
  }
}