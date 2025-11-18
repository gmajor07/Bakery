import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/inventory_provider.dart';
import '../widgets/token_error_widget.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider('supplies'));
    final searchQuery = ref.watch(searchQueryProvider);
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplies Inventory'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Search and Add Section
          _buildHeaderSection(context, ref, isTablet),

          // Results Count
          _buildResultsCount(inventoryAsync, searchQuery),

          // Inventory List/Table
          Expanded(
            child: inventoryAsync.when(
              data: (items) => _buildInventoryDisplay(context, items, searchQuery, isTablet, ref),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) {
                final msg = error.toString().toLowerCase();
                if (msg.contains('401') ||
                    msg.contains('unauthorized') ||
                    msg.contains('token') ||
                    msg.contains('expired')) {
                  return TokenErrorWidget(ref: ref);
                }
                return Center(child: Text('Error: $error'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, WidgetRef ref, bool isTablet) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isTablet
            ? _buildTabletHeader(ref)
            : _buildMobileHeader(ref),
      ),
    );
  }

  Widget _buildTabletHeader(WidgetRef ref) {
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
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Navigate to add supply page
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Supplies'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader(WidgetRef ref) {
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
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Navigate to add supply page
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Supplies'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsCount(AsyncValue<List<dynamic>> inventoryAsync, String searchQuery) {
    return inventoryAsync.when(
      data: (items) {
        final filtered = _filterItems(items, searchQuery);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${filtered.length} item${filtered.length != 1 ? 's' : ''} found',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildInventoryDisplay(BuildContext context, List<dynamic> items, String searchQuery, bool isTablet, WidgetRef ref) {
    final filtered = _filterItems(items, searchQuery);

    if (filtered.isEmpty) {
      return _buildEmptyState(context, searchQuery, ref);
    }

    return isTablet
        ? _buildTableView(context, filtered)
        : _buildMobileView(filtered);
  }

  Widget _buildTableView(BuildContext context, List<dynamic> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: DataTable(
          headingRowColor: WidgetStateColor.resolveWith(
                (states) => Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          ),
          columns: const [
            DataColumn(label: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Min Level', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Cost', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: items.map((item) {
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
                    item.currentQuantity.toString(),
                    style: TextStyle(
                      color: _getQuantityColor(item.currentQuantity, item.minLevel),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(Text(item.minLevel.toString())),
                DataCell(Text('Tsh ${item.cost.toStringAsFixed(0)}')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(item.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(item.status)),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        color: _getStatusColor(item.status),
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

  Widget _buildMobileView(List<dynamic> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(item.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getStatusColor(item.status)),
                      ),
                      child: Text(
                        item.status,
                        style: TextStyle(
                          color: _getStatusColor(item.status),
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
                    _buildDetailItem('Quantity', item.currentQuantity.toString()),
                    _buildDetailItem('Min Level', item.minLevel.toString()),
                    _buildDetailItem('Cost', 'Tsh ${item.cost.toStringAsFixed(0)}'),
                  ],
                ),

                // Quantity warning if low
                if (item.currentQuantity <= item.minLevel)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.warning, size: 16, color: Colors.orange[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Low stock - reorder needed',
                          style: TextStyle(
                            color: Colors.orange[700],
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

  Widget _buildDetailItem(String label, String value) {
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

  Widget _buildEmptyState(BuildContext context, String searchQuery, WidgetRef ref) {
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
              onPressed: () {
                // TODO: Navigate to add supply page
              },
            ),
        ],
      ),
    );
  }


  List<dynamic> _filterItems(List<dynamic> items, String searchQuery) {
    if (searchQuery.isEmpty) return items;

    final query = searchQuery.toLowerCase();
    return items.where((item) {
      return item.name.toLowerCase().contains(query) ||
          item.unit.toLowerCase().contains(query) ||
          item.status.toLowerCase().contains(query);
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in stock':
        return Colors.green;
      case 'low stock':
        return Colors.orange;
      case 'out of stock':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getQuantityColor(double currentQuantity, double minLevel) {
    if (currentQuantity <= minLevel) return Colors.red;
    if (currentQuantity <= minLevel * 2) return Colors.orange;
    return Colors.green;
  }
}