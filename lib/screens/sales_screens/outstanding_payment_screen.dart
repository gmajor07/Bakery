import 'package:bak/screens/sales_screens/record_payment_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/outstanding_payment.dart';
import '../../provider/payment_provider.dart';
import '../../widgets/token_error_widget.dart';
import 'payment_history_screen.dart';

class OutstandingPaymentsScreen extends ConsumerStatefulWidget {
  const OutstandingPaymentsScreen({super.key});

  @override
  ConsumerState<OutstandingPaymentsScreen> createState() =>
      _OutstandingPaymentsScreenState();
}

class _OutstandingPaymentsScreenState
    extends ConsumerState<OutstandingPaymentsScreen> {
  final searchController = TextEditingController();
  DateTimeRange? dateRange;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  bool _matchesFilter(OutstandingPayment p, String q) {
    if (q.isEmpty) return true;
    final lower = q.toLowerCase();
    return p.customer.toLowerCase().contains(lower) ||
        p.receiptNumber.toString().contains(lower);
  }

  @override
  Widget build(BuildContext context) {
    final outstandingAsync = ref.watch(outstandingPaymentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Outstanding Payments'),
        actions: [
          IconButton(
            tooltip: 'Payment history',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // search + date range
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by receipt # or customer',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    dateRange == null
                        ? 'Date range'
                        : '${DateFormat('MMM dd').format(dateRange!.start)} - ${DateFormat('MMM dd').format(dateRange!.end)}',
                  ),
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(now.year - 2),
                      lastDate: now,
                      initialDateRange: dateRange,
                    );
                    if (picked != null) setState(() => dateRange = picked);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: outstandingAsync.when(
                data: (list) {
                  // apply search & date range
                  List<OutstandingPayment> filtered = list.where((p) {
                    if (!_matchesFilter(p, searchController.text.trim()))
                      return false;
                    if (dateRange != null) {
                      final d = p.dueDate;
                      if (d.isBefore(dateRange!.start) ||
                          d.isAfter(dateRange!.end))
                        return false;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No outstanding payments found.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Receipt #${p.receiptNumber}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(p.customer),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total: ${p.totalAmount.toStringAsFixed(0)}',
                                    ),
                                    Text(
                                      'Paid: ${p.paidAmount.toStringAsFixed(0)}',
                                    ),
                                    Text(
                                      'Balance: ${p.balance.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                children: [
                                  Text(
                                    'Due: ${DateFormat.yMd().format(p.dueDate)}',
                                  ),
                                  const SizedBox(height: 6),

                                  ElevatedButton(
                                    onPressed: p.balance <= 0
                                        ? null
                                        : () async {
                                            final recorded = await showDialog<bool>(
                                              context: context,
                                              builder: (_) => RecordPaymentDialog(
                                                saleId: p.saleId,
                                                receiptNumber: p
                                                    .receiptNumber, // ✅ Pass correct receipt
                                                outstanding: p.balance,
                                              ),
                                            );
                                            if (recorded == true) {
                                              ref.refresh(
                                                outstandingPaymentsProvider,
                                              );
                                              ref.refresh(
                                                paymentHistoryProvider,
                                              );
                                            }
                                          },
                                    child: const Text('Record Payment'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
