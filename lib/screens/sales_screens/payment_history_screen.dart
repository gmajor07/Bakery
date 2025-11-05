import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../provider/payment_provider.dart';
import '../../widgets/token_error_widget.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  String searchQuery = '';
  DateTimeRange? selectedRange;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(paymentHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 🔍 Search + 📅 Date Range
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search by receipt # or customer',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) =>
                        setState(() => searchQuery = value.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: const Text('Pick date range'),
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(now.year - 5),
                      lastDate: DateTime(now.year + 1),
                    );
                    if (picked != null) {
                      setState(() => selectedRange = picked);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 📋 Table or Loading/Error
            Expanded(
              child: historyAsync.when(
                data: (list) {
                  final filtered = list.where((p) {
                    final matchesSearch =
                        p.receiptNumber.toString().contains(searchQuery) ||
                        p.customerName.toLowerCase().contains(searchQuery);
                    final matchesDate =
                        selectedRange == null ||
                        (p.paymentDate.isAfter(
                              selectedRange!.start.subtract(
                                const Duration(days: 1),
                              ),
                            ) &&
                            p.paymentDate.isBefore(
                              selectedRange!.end.add(const Duration(days: 1)),
                            ));
                    return matchesSearch && matchesDate;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No matching payments found'),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Receipt #')),
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Amount')),
                        DataColumn(label: Text('Payment Date')),
                      ],
                      rows: filtered.map((p) {
                        return DataRow(
                          cells: [
                            DataCell(Text(p.receiptNumber.toString())),
                            DataCell(Text(p.customerName)),
                            DataCell(
                              Text(NumberFormat('#,##0').format(p.amount)),
                            ),
                            DataCell(
                              Text(
                                DateFormat('dd/MM/yyyy').format(p.paymentDate),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) {
                  final msg = err.toString().toLowerCase();
                  if (msg.contains('token') ||
                      msg.contains('401') ||
                      msg.contains('unauthorized')) {
                    return TokenErrorWidget(ref: ref);
                  }
                  return Center(child: Text('Error: $err'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
