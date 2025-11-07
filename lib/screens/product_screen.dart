import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../provider/products_provider.dart';
import '../provider/products_search_provider.dart';
import '../widgets/token_error_widget.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  late TextEditingController _searchController;
  String? _token;
  bool _isLoadingToken = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.text = ref.read(productSearchQueryProvider);
    _searchController.addListener(() {
      ref.read(productSearchQueryProvider.notifier).state =
          _searchController.text;
    });

    ref.read(authProvider.notifier).getAccessToken().then((value) {
      setState(() {
        _token = value;
        _isLoadingToken = false;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(productSearchQueryProvider).toLowerCase();

    if (_isLoadingToken) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_token == null) {
      return const Scaffold(
        body: Center(child: Text('Token not found. Please log in again.')),
      );
    }

    final productsAsync = ref.watch(productsProvider(_token!));

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: productsAsync.when(
        data: (products) {
          final filteredProducts = products.where((product) {
            return product.name.toLowerCase().contains(searchQuery) ||
                product.description.toLowerCase().contains(searchQuery);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search products',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                      .read(productSearchQueryProvider.notifier)
                                      .state =
                                  '';
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Product Name')),
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('Quantity')),
                      DataColumn(label: Text('Price')),
                    ],
                    rows: filteredProducts.map((product) {
                      return DataRow(
                        cells: [
                          DataCell(Text(product.name)),
                          DataCell(Text(product.description)),
                          DataCell(Text(product.quantity.toString())),
                          DataCell(
                            Text(
                              'TSh ${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
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
    );
  }
}
