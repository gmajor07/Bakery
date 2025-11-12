import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../provider/adjustment_provider.dart';
import '../widgets/token_error_widget.dart';
import 'new_adjustment.dart';

class AdjustmentsScreen extends ConsumerStatefulWidget {
  const AdjustmentsScreen({super.key});

  @override
  ConsumerState<AdjustmentsScreen> createState() => _AdjustmentsScreenState();
}

class _AdjustmentsScreenState extends ConsumerState<AdjustmentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final filters = ref.read(adjustmentFiltersProvider);
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
          .read(adjustmentFiltersProvider.notifier)
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
    final filters = ref.watch(adjustmentFiltersProvider);
    final adjustmentsAsync = ref.watch(adjustmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Adjustments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to AdjustmentsScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NewAdjustmentScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Adjustment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search by item name',
                    ),
                    onChanged: (value) {
                      ref
                          .read(adjustmentFiltersProvider.notifier)
                          .update((s) => s.copyWith(search: value, page: 1));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _pickDateRange,
                  child: const Text('Pick Date Range'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: adjustmentsAsync.when(
                data: (adjustments) {
                  if (adjustments.isEmpty) {
                    return const Center(child: Text('No adjustments found.'));
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Item Name')),
                        DataColumn(label: Text('Unit')),
                        DataColumn(label: Text('Quantity')),
                        DataColumn(label: Text('Reason')),
                      ],
                      rows: adjustments.map((adj) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                DateFormat(
                                  'dd-MM-yyyy',
                                ).format(DateTime.parse(adj.createdAt)),
                              ),
                            ),
                            DataCell(Text(adj.inventoryItem.name)),
                            DataCell(
                              Text(adj.inventoryItem.unit),
                            ), // Assuming `unit` is available
                            DataCell(
                              Text(
                                adj.amount > 0
                                    ? '+${adj.amount}'
                                    : adj.amount.toString(),
                              ),
                            ),
                            DataCell(
                              Text(adj.reason.isNotEmpty ? adj.reason : ''),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
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
                  return Center(child: Text('Error: ${error.toString()}'));
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: filters.page > 1
                      ? () {
                          ref
                              .read(adjustmentFiltersProvider.notifier)
                              .update((s) => s.copyWith(page: s.page - 1));
                        }
                      : null,
                  child: const Text('Previous'),
                ),
                Text('Page ${filters.page}'),
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(adjustmentFiltersProvider.notifier)
                        .update((s) => s.copyWith(page: s.page + 1));
                  },
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
