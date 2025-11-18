import 'package:bak/screens/production_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/production_items.dart';
import '../../provider/production_provider.dart';
import '../../widgets/token_error_widget.dart';

class ProductionScreen extends ConsumerStatefulWidget {
  const ProductionScreen({super.key});

  @override
  ConsumerState<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends ConsumerState<ProductionScreen> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productionAsync = ref.watch(productionProvider);
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Production Records'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Search Section
          _buildSearchField(),
          const SizedBox(height: 8),

          // Results Count
          _buildResultsCount(productionAsync),

          // Data Display - Responsive based on screen size
          Expanded(
            child: productionAsync.when(
              data: (items) => isTablet
                  ? _buildTabletView(items)
                  : _buildMobileView(items),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorWidget(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by product name',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() => searchQuery = '');
            },
          )
              : null,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildResultsCount(AsyncValue<List<ProductionItem>> productionAsync) {
    return productionAsync.when(
      data: (items) {
        final filteredItems = _getFilteredItems(items);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${filteredItems.length} record${filteredItems.length != 1 ? 's' : ''} found',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
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

  // Tablet View - DataTable with horizontal scrolling
  Widget _buildTabletView(List<ProductionItem> items) {
    final filteredItems = _getFilteredItems(items);

    if (filteredItems.isEmpty) {
      return _buildEmptyState();
    }

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
            DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Cost', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Profit Margin', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: filteredItems.map((item) => _buildTabletDataRow(item)).toList(),
        ),
      ),
    );
  }

  DataRow _buildTabletDataRow(ProductionItem item) {
    return DataRow(
      cells: [
        DataCell(
          Tooltip(
            message: item.product,
            child: Text(
              item.product,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        DataCell(Text(item.quantity.toString())),
        DataCell(Text(_formatDate(item.date))),
        DataCell(Text(
          'Tsh ${item.cost.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        )),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getProfitMarginColor(item.profitMargin).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getProfitMarginColor(item.profitMargin)),
            ),
            child: Text(
              '${item.profitMargin.toStringAsFixed(2)}%',
              style: TextStyle(
                color: _getProfitMarginColor(item.profitMargin),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'View details',
            onPressed: () => _navigateToDetail(item.id),
          ),
        ),
      ],
    );
  }

  // Mobile View - Card-based layout
  Widget _buildMobileView(List<ProductionItem> items) {
    final filteredItems = _getFilteredItems(items);

    if (filteredItems.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildProductionCard(item);
      },
    );
  }

  Widget _buildProductionCard(ProductionItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with product name and view button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.product,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.visibility_outlined),
                  onPressed: () => _navigateToDetail(item.id),
                  tooltip: 'View details',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Production details in a compact grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              children: [
                _buildDetailItem('Quantity', item.quantity.toString()),
                _buildDetailItem('Date', _formatDate(item.date)),
                _buildDetailItem('Cost', 'Tsh ${item.cost.toStringAsFixed(2)}'),
                _buildProfitMarginItem(item.profitMargin),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProfitMarginItem(double margin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profit Margin',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _getProfitMarginColor(margin).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getProfitMarginColor(margin)),
          ),
          child: Text(
            '${margin.toStringAsFixed(2)}%',
            style: TextStyle(
              color: _getProfitMarginColor(margin),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No production records found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
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
          Text(
            'Error loading data',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: () => ref.invalidate(productionProvider),
          ),
        ],
      ),
    );
  }

  List<ProductionItem> _getFilteredItems(List<ProductionItem> items) {
    // Remove duplicates by ID
    final uniqueItems = {
      for (var item in items) item.id: item,
    }.values.toList();

    // Apply search filter
    return uniqueItems
        .where((item) => item.product.toLowerCase().contains(searchQuery))
        .toList();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getProfitMarginColor(double margin) {
    if (margin >= 20) return Colors.green;
    if (margin >= 10) return Colors.orange;
    return Colors.red;
  }

  void _navigateToDetail(int productionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductionDetailScreen(productionId: productionId),
      ),
    );
  }
}