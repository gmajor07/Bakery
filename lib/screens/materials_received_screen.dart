import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../provider/material_received_provider.dart';
import '../widgets/token_error_widget.dart';
import 'material_received_details_screen.dart';

class MaterialsReceivedScreen extends ConsumerStatefulWidget {
  const MaterialsReceivedScreen({super.key});

  @override
  ConsumerState<MaterialsReceivedScreen> createState() =>
      _MaterialsReceivedScreenState();
}

class _MaterialsReceivedScreenState
    extends ConsumerState<MaterialsReceivedScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final filters = ref.read(materialFiltersProvider);
    _searchController.text = filters.search ?? '';
  }

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      ref
          .read(materialFiltersProvider.notifier)
          .update(
            (s) => s.copyWith(
              startDate: picked.start.toIso8601String(),
              endDate: picked.end.toIso8601String(),
              page: 1,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(materialFiltersProvider);
    final receiptsAsync = ref.watch(materialsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Materials Received')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(labelText: 'Search'),
                      onChanged: (value) {
                        ref
                            .read(materialFiltersProvider.notifier)
                            .update((s) => s.copyWith(search: value, page: 1));
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _pickDateRange,
                    child: const Text('Pick date range'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: receiptsAsync.when(
                  data: (receipts) {
                    if (receipts.isEmpty) {
                      return const Center(child: Text('No receipts found.'));
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width,
                        ),
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Order #')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Supplier')),
                            DataColumn(label: Text('Total')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: receipts.map((r) {
                            final dateStr = DateFormat(
                              'dd-MM-yyyy',
                            ).format(r.receivedDate);
                            return DataRow(
                              cells: [
                                DataCell(Text(r.purchaseOrderId.toString())),
                                DataCell(Text(dateStr)),
                                DataCell(Text(r.supplierName)),
                                DataCell(Text(r.total.toStringAsFixed(0))),
                                DataCell(
                                  Text(
                                    r.status,
                                    style: TextStyle(
                                      color:
                                          r.status.toLowerCase() == 'completed'
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MaterialDetailsScreen(
                                            receiptId: r.id,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.visibility),
                                    label: const Text('View'),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) {
                    final msg = err.toString().toLowerCase();
                    if (msg.contains('401') ||
                        msg.contains('unauthorized') ||
                        msg.contains('token') ||
                        msg.contains('expired')) {
                      return TokenErrorWidget(ref: ref);
                    }
                    return Center(child: Text('Error: $err'));
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: filters.page > 1
                        ? () => ref
                              .read(materialFiltersProvider.notifier)
                              .update((s) => s.copyWith(page: s.page - 1))
                        : null,
                    child: const Text('Previous'),
                  ),
                  Text('Page ${filters.page}'),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(materialFiltersProvider.notifier)
                        .update((s) => s.copyWith(page: s.page + 1)),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
