import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // ⭐️ NEW: Import for number formatting

// Import your necessary files
import '../../provider/material_pagination_provider.dart';
import '../../provider/material_provider.dart';
import '../../provider/materials_search_provider.dart';
// Assuming this file exists and contains ClientPaginationFilters
import '../../widgets/token_error_widget.dart';
import 'create_material_screen.dart';

// ⭐️ CONSTANT FOR FONT SIZE
const double _kDataFontSize = 15.0;

class MaterialsScreen extends ConsumerWidget {
  const MaterialsScreen({super.key});

  // ⭐️ CURRENCY FORMATTER (TSh with 0 decimal places)
  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_TZ',
    symbol: 'TSh',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(materialsProvider);
    final searchQuery = ref.watch(materialSearchQueryProvider).toLowerCase();

    // ⭐️ WATCH CLIENT-SIDE PAGINATION STATE
    final paginationFilters = ref.watch(materialClientPaginationProvider);

    final isTablet = MediaQuery.of(context).size.width >= 768;

    Future<void> refresh() async {
      await ref.read(materialsProvider.notifier).fetchMaterials();
      // Reset pagination on refresh
      ref.read(materialClientPaginationProvider.notifier).state =
          ClientPaginationFilters();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Materials List'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (!isTablet)
            IconButton(
              onPressed: () => _navigateToCreateScreen(context, ref),
              icon: const Icon(Icons.add),
              tooltip: 'Add New Material',
            ),
        ],
      ),
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

          // 1. Filter materials based on search
          final filteredMaterials = materials.where((item) {
            return item.name.toLowerCase().contains(searchQuery) ||
                item.unit.toLowerCase().contains(searchQuery) ||
                item.status.toLowerCase().contains(searchQuery);
          }).toList();

          if (filteredMaterials.isEmpty) {
            return _buildNoSearchResults(context, searchQuery, refresh);
          }

          // 2. Apply Client-Side Pagination
          final totalItems = filteredMaterials.length;
          final totalPages = (totalItems / paginationFilters.limit).ceil();
          final startIndex =
              (paginationFilters.page - 1) * paginationFilters.limit;
          final endIndex = startIndex + paginationFilters.limit;

          final pageMaterials = filteredMaterials.sublist(
            startIndex,
            endIndex > totalItems ? totalItems : endIndex,
          );

          final isLastPage =
              paginationFilters.page >= totalPages && totalPages > 0;
          final isFirstPage = paginationFilters.page <= 1;

          return RefreshIndicator(
            onRefresh: refresh,
            child: Column(
              children: [
                // Search Bar
                _buildSearchField(ref),

                // Results Count
                _buildResultsCount(
                  totalItems,
                  startIndex,
                  endIndex > totalItems ? totalItems : endIndex,
                  searchQuery,
                ),

                // Materials List/Table
                Expanded(
                  child: isTablet
                      ? _buildTableView(context, pageMaterials)
                      : _buildMobileView(pageMaterials),
                ),

                // ⭐️ PAGINATION CONTROLS
                if (totalItems > paginationFilters.limit)
                  _buildPagination(
                    ref,
                    paginationFilters,
                    isFirstPage,
                    isLastPage,
                    totalPages,
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

  // ⭐️ MODIFIED: To reflect current page view
  Widget _buildResultsCount(
    int totalItems,
    int startIndex,
    int endIndex,
    String searchQuery,
  ) {
    final displayedEnd = endIndex > totalItems ? totalItems : endIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${startIndex + 1}-$displayedEnd of $totalItems material${totalItems != 1 ? 's' : ''}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          if (searchQuery.isNotEmpty)
            Text(
              'Filtered',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
        ],
      ),
    );
  }

  // ⭐️ NEW: Pagination Widget
  Widget _buildPagination(
    WidgetRef ref,
    ClientPaginationFilters filters,
    bool isFirstPage,
    bool isLastPage,
    int totalPages,
  ) {
    void nextPage() {
      if (!isLastPage) {
        ref
            .read(materialClientPaginationProvider.notifier)
            .update((s) => s.copyWith(page: s.page + 1));
      }
    }

    void previousPage() {
      if (!isFirstPage) {
        ref
            .read(materialClientPaginationProvider.notifier)
            .update((s) => s.copyWith(page: s.page - 1));
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: previousPage,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
          ),

          const SizedBox(width: 16),

          Text(
            'Page ${filters.page} of $totalPages',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(width: 16),

          ElevatedButton.icon(
            onPressed: nextPage,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next'),
          ),
        ],
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
              // ⭐️ RESET PAGE ON CLEAR
              ref
                  .read(materialClientPaginationProvider.notifier)
                  .update((state) => state.copyWith(page: 1));
            },
          ),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) {
          ref.read(materialSearchQueryProvider.notifier).state = value;
          // ⭐️ RESET PAGE ON SEARCH
          ref
              .read(materialClientPaginationProvider.notifier)
              .update((state) => state.copyWith(page: 1));
        },
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
            (states) => Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          ),
          columns: const [
            DataColumn(
              label: Text(
                'Item Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Unit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Quantity',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Min Level',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Cost',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: materials.map((item) {
            final quantityText = NumberFormat('#,##0').format(item.quantity);

            return DataRow(
              cells: [
                DataCell(
                  Tooltip(
                    message: item.name,
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: _kDataFontSize,
                      ), // ⭐️ FONT SIZE
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    item.unit,
                    style: const TextStyle(fontSize: _kDataFontSize),
                  ),
                ), // ⭐️ FONT SIZE
                DataCell(
                  Text(
                    quantityText,
                    style: const TextStyle(fontSize: _kDataFontSize),
                  ),
                ), // ⭐️ FONT SIZE
                DataCell(
                  Text(
                    item.minLevel.toString(),
                    style: const TextStyle(fontSize: _kDataFontSize),
                  ),
                ), // ⭐️ FONT SIZE
                DataCell(
                  Text(
                    _currencyFormat.format(item.cost), // ⭐️ PRICE FORMAT
                    style: const TextStyle(
                      fontSize: _kDataFontSize,
                      fontWeight: FontWeight.bold,
                    ), // ⭐️ FONT SIZE & BOLD
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        item.status,
                        item.lowStock,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(item.status, item.lowStock),
                      ),
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
        final costText = _currencyFormat.format(item.cost); // ⭐️ PRICE FORMAT
        final quantityText = NumberFormat('#,##0').format(item.quantity);

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
                          fontSize: 17.0,
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
                        color: _getStatusColor(
                          item.status,
                          item.lowStock,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(item.status, item.lowStock),
                        ),
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
                    _buildDetailItem('Quantity', quantityText),
                    _buildDetailItem('Min Level', item.minLevel.toString()),
                    _buildDetailItem(
                      'Cost',
                      costText,
                      isCost: true,
                    ), // ⭐️ PRICE FORMATTING
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isCost = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: _kDataFontSize,
            fontWeight: isCost ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    Future<void> Function() refresh,
    WidgetRef ref,
  ) {
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
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
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

  Widget _buildNoSearchResults(
    BuildContext context,
    String query,
    Future<void> Function() refresh,
  ) {
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
      return const TokenErrorWidget();
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
    return Colors.brown;
  }

  void _navigateToCreateScreen(BuildContext context, WidgetRef ref) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateMaterialScreen(
          heading: "Add Material",
          type: "raw_material",
          screenTitle: '',
        ),
      ),
    );
    // ⭐️ FIX: Invalidate main data provider AND reset pagination
    ref.invalidate(materialsProvider);
    ref.read(materialClientPaginationProvider.notifier).state =
        ClientPaginationFilters();
  }
}
