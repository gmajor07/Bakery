import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/purchase_order.dart';
import '../../provider/purchase_orders_provider.dart';

import '../../widgets/token_error_widget.dart';
import 'create_purchase_order_screen.dart';
import 'purchase_order_detail_screen.dart';

class PurchaseOrdersScreen extends ConsumerWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrders = ref.watch(purchaseOrdersProvider);
    final selectedStatus = ref.watch(selectedPurchaseStatusProvider);
    final selectedDate = ref.watch(selectedPurchaseDateRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchase Orders"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(purchaseOrdersProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // 🔁 Force reload of the purchase orders provider
            ref.invalidate(purchaseOrdersProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearch(ref),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    // 🚀 Navigate to creation screen
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreatePurchaseOrderScreen(),
                      ),
                    );

                    // 🔄 Refresh automatically after successful creation
                    if (result == true) {
                      ref.invalidate(purchaseOrdersProvider);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Order'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatusFilter(ref, selectedStatus)),
                    const SizedBox(width: 16),
                    _buildDatePicker(context, ref, selectedDate),
                  ],
                ),
                const SizedBox(height: 16),
                asyncOrders.when(
                  data: (orders) => _buildTable(context, orders),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) {
                    final msg = err.toString().toLowerCase();
                    if (msg.contains("token") || msg.contains("unauthorized")) {
                      return TokenErrorWidget(ref: ref);
                    }
                    return Center(child: Text("Error: $err"));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearch(WidgetRef ref) {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Search...',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        ref.read(purchaseSearchQueryProvider.notifier).state = value;
      },
    );
  }

  Widget _buildStatusFilter(WidgetRef ref, String? selected) {
    const statuses = [null, "Pending", "Completed", "Cancelled"];
    return DropdownButtonFormField<String?>(
      value: selected,
      decoration: const InputDecoration(labelText: "Status"),
      items: statuses
          .map((s) => DropdownMenuItem(value: s, child: Text(s ?? "All")))
          .toList(),
      onChanged: (value) =>
          ref.read(selectedPurchaseStatusProvider.notifier).state = value,
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    WidgetRef ref,
    DateTimeRange? range,
  ) {
    final label = range == null
        ? "Pick date range"
        : "${DateFormat('dd-MM-yyyy').format(range.start)} → ${DateFormat('dd-MM-yyyy').format(range.end)}";

    return TextButton.icon(
      icon: const Icon(Icons.date_range),
      label: Text(label),
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2024),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          ref.read(selectedPurchaseDateRangeProvider.notifier).state = picked;
          ref.invalidate(purchaseOrdersProvider);
        }
      },
    );
  }

  Widget _buildTable(BuildContext context, List<PurchaseOrder> orders) {
    if (orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: Text("No orders found.")),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Order #")),
          DataColumn(label: Text("Date")),
          DataColumn(label: Text("Supplier")),
          DataColumn(label: Text("Items")),
          DataColumn(label: Text("Total")),
          DataColumn(label: Text("Status")),
          DataColumn(label: Text("Actions")),
        ],
        rows: orders.map((o) {
          return DataRow(
            cells: [
              DataCell(Text(o.id.toString())),
              DataCell(
                Text(
                  DateFormat("dd-MM-yyyy").format(DateTime.parse(o.createdAt)),
                ),
              ),
              DataCell(Text(o.supplier.name)),
              DataCell(Text(o.items.length.toString())),
              DataCell(Text("TSh ${o.totalCost.toStringAsFixed(0)}")),
              DataCell(Text(o.status)),
              DataCell(
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PurchaseOrderDetailScreen(order: o),
                      ),
                    );
                  },
                  child: const Text("View"),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
