import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/material_provider.dart';
import '../provider/materials_search_provider.dart';
import '../widgets/token_error_widget.dart';
import 'create_material_screen.dart';

class MaterialsScreen extends ConsumerWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(materialsProvider);
    final searchQuery = ref.watch(materialSearchQueryProvider).toLowerCase();
    final isTablet = MediaQuery.of(context).size.width >= 768;

    Future<void> refresh() async {
      await ref.read(materialsProvider.notifier).fetchMaterials();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Materials List'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Add button in app bar for mobile
          if (!isTablet)
            IconButton(
              onPressed: () => _navigateToCreateScreen(context, ref),
              icon: const Icon(Icons.add),
              tooltip: 'Add New Material',
            ),
        ],
      ),

      // Floating Action Button - Show only on tablet or when search is empty
      floatingActionButton: isTablet || searchQuery.isEmpty
          ? FloatingActionButton(
        onPressed: () => _navigateToCreateScreen(context, ref),
        child: const Icon(Icons.add),
      )
          : null,

      body: materialsAsync.when(
        data: (materials) {
          if (materials.isEmpty) {
            return _buildEmptyState(context, refresh, ref);
          }

          // 🔍 Filter materials based on search
          final filteredMaterials = materials.where((item) {
            return item.name.toLowerCase().contains(searchQuery) ||
                item.unit.toLowerCase().contains(searchQuery) ||
                item.status.toLowerCase().contains(searchQuery);
          }).toList();

          if (filteredMaterials.isEmpty) {
            return _buildNoSearchResults(context, searchQuery, refresh);
          }

          return RefreshIndicator(
            onRefresh: refresh,
            child: Column(
              children: [
                // Search Bar
                _buildSearchField(ref),

                // Results Count
                _buildResultsCount(filteredMaterials.length),

                // Materials List/Table
                Expanded(
                  child: isTablet
                      ? _buildTableView(context, filteredMaterials)
                      : _buildMobileView(filteredMaterials),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorWidget(context, error, ref),
      ),
    );
  }

  Widget _buildSearchField(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          labelText: 'Search materials...',
          hintText: 'Search by name, unit, or status',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              ref.read(materialSearchQueryProvider.notifier).state = '';
            },
          ),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) =>
        ref.read(materialSearchQueryProvider.notifier).state = value,
      ),
    );
  }

  Widget _buildResultsCount(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '$count material${count != 1 ? 's' : ''} found',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView(BuildContext context, List<dynamic> materials) {
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
          rows: materials.map((item) {
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
                DataCell(Text(item.quantity.toStringAsFixed(3))),
                DataCell(Text(item.minLevel.toString())),
                DataCell(Text('Tsh ${item.cost.toStringAsFixed(0)}')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(item.status, item.lowStock).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(item.status, item.lowStock)),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        color: _getStatusColor(item.status, item.lowStock),
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

  Widget _buildMobileView(List<dynamic> materials) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final item = materials[index];
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
                        color: _getStatusColor(item.status, item.lowStock).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getStatusColor(item.status, item.lowStock)),
                      ),
                      child: Text(
                        item.status,
                        style: TextStyle(
                          color: _getStatusColor(item.status, item.lowStock),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Material details in grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3,
                  children: [
                    _buildDetailItem('Unit', item.unit),
                    _buildDetailItem('Quantity', item.quantity.toStringAsFixed(3)),
                    _buildDetailItem('Min Level', item.minLevel.toString()),
                    _buildDetailItem('Cost', 'Tsh ${item.cost.toStringAsFixed(0)}'),
                  ],
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

  Widget _buildEmptyState(BuildContext context, Future<void> Function() refresh, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No materials found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add your first material to get started',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Material'),
                  onPressed: () => _navigateToCreateScreen(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResults(BuildContext context, String query, Future<void> Function() refresh) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No materials found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'No results for "$query"',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try adjusting your search terms',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object error, WidgetRef ref) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('401') ||
        msg.contains('unauthorized') ||
        msg.contains('token') ||
        msg.contains('expired')) {
      return TokenErrorWidget(ref: ref);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error loading materials',
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
            onPressed: () => ref.invalidate(materialsProvider),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, bool lowStock) {
    if (status == 'Out of stock') return Colors.red;
    if (lowStock) return Colors.orange;
    return Colors.green;
  }

  void _navigateToCreateScreen(BuildContext context, WidgetRef ref) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateMaterialScreen()),
    );
    // refresh the list after returning
    ref.read(materialsProvider.notifier).fetchMaterials();
  }
}