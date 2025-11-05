import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/customer.dart';
import '../../models/sale_item.dart';
import '../../provider/customer_provider.dart';
import '../../provider/sales_provider.dart';
import '../../widgets/token_error_widget.dart';
import '../pos_screens/generate_pdf.dart';
import 'sale_detail_screen.dart';

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesHistoryProvider);
    final selectedCustomer = ref.watch(selectedCustomerProvider);
    final selectedDateRange = ref.watch(selectedDateRangeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sales History')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Sales', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildCustomerFilter(ref)),
                const SizedBox(width: 16),
                _buildDatePicker(context, ref, selectedDateRange),
              ],
            ),
            const SizedBox(height: 16),

            // ------- DATA LOADING -------
            Expanded(
              child: salesAsync.when(
                data: (sales) {
                  // ✅ Filter by customer
                  List<SaleItem> filtered = sales;
                  if (selectedCustomer != null) {
                    filtered = filtered
                        .where(
                          (s) =>
                              s.customer.toLowerCase() ==
                              selectedCustomer.name.toLowerCase(),
                        )
                        .toList();
                  }

                  // ✅ Filter by date range
                  if (selectedDateRange != null) {
                    filtered = filtered.where((s) {
                      final saleDate = DateTime.parse(s.date);
                      return saleDate.isAfter(
                            selectedDateRange.start.subtract(
                              const Duration(days: 1),
                            ),
                          ) &&
                          saleDate.isBefore(
                            selectedDateRange.end.add(const Duration(days: 1)),
                          );
                    }).toList();
                  }

                  return _buildSalesTable(context, filtered);
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
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Customer Filter Dropdown
  Widget _buildCustomerFilter(WidgetRef ref) {
    final selected = ref.watch(selectedCustomerProvider);
    final customersAsync = ref.watch(customerListProvider);

    return customersAsync.when(
      data: (customers) {
        final allOptions = [null, ...customers]; // null = All
        return DropdownButtonFormField<Customer?>(
          value: selected,
          decoration: const InputDecoration(labelText: 'Filter by Customer'),
          items: allOptions.map((c) {
            return DropdownMenuItem(value: c, child: Text(c?.name ?? 'All'));
          }).toList(),
          onChanged: (value) {
            ref.read(selectedCustomerProvider.notifier).state = value;
          },
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Text('Failed to load customers'),
    );
  }

  // ✅ Date Range Picker
  Widget _buildDatePicker(
    BuildContext context,
    WidgetRef ref,
    DateTimeRange? range,
  ) {
    final label = range == null
        ? 'Select date range'
        : '${DateFormat('MMM dd').format(range.start)} - ${DateFormat('MMM dd, yyyy').format(range.end)}';

    return TextButton.icon(
      icon: const Icon(Icons.date_range),
      label: Text(label),
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2023),
          lastDate: DateTime.now(),
          initialDateRange: range,
        );
        if (picked != null) {
          ref.read(selectedDateRangeProvider.notifier).state = picked;
        }
      },
    );
  }

  // ✅ Sales Table
  Widget _buildSalesTable(BuildContext context, List<SaleItem> sales) {
    if (sales.isEmpty) {
      return const Center(child: Text('No sales found.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Receipt #')),
          DataColumn(label: Text('Customer')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: sales.map((sale) {
          final formattedDate = DateFormat.yMMMd().format(
            DateTime.parse(sale.date),
          );
          final formattedAmount = 'TSh ${sale.amount.toStringAsFixed(2)}';

          return DataRow(
            cells: [
              DataCell(Text(sale.receiptNumber.toString())),
              DataCell(Text(sale.customer)),
              DataCell(Text(formattedDate)),
              DataCell(Text(formattedAmount)),
              DataCell(Text(sale.status)),
              DataCell(
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SaleDetailScreen(saleId: sale.receiptNumber),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('View'),
                    ),
                    TextButton.icon(
                      onPressed: () => generateSaleReceiptPdf(sale),
                      icon: const Icon(Icons.print),
                      label: const Text('Print'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
