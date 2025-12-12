import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/purchase_order.dart';
import '../../models/purchase_inventory_item.dart';
import '../../provider/purchase_orders_provider.dart';

class PurchaseOrderDetailScreen extends ConsumerStatefulWidget {
  final PurchaseOrder order;

  const PurchaseOrderDetailScreen({super.key, required this.order});

  @override
  ConsumerState<PurchaseOrderDetailScreen> createState() =>
      _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState
    extends ConsumerState<PurchaseOrderDetailScreen> {
  late PurchaseOrder _order;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  // Helper function to capitalize the first letter
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Helper function to determine the color based on status
  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.brown;
      case 'received':
        return Colors.brown.shade700;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'approved':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Helper function to determine the background color based on status
  // 🚨 FIX: Made it theme-aware by blending it with the background or using a lighter shade.
  static Color _statusBackgroundColor(String status) {
    return _statusColor(status).withOpacity(0.1);
  }

  // --------------------- UI BUILDERS ------------------------

  @override
  Widget build(BuildContext context) {
    final date = DateFormat(
      'dd-MM-yyyy, hh:mm a', // Added time for better detail
    ).format(DateTime.parse(_order.createdAt));

    // Use a currency format for better visualization
    final totalFormatted = NumberFormat.currency(
      symbol: 'TSh', // Assuming currency symbol
      decimalDigits: 0,
    ).format(_order.totalCost);

    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase Order #${_order.id}'),
        elevation: 1,
        // The AppBar text color should be handled by the theme (onPrimary/onSurface)
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Summary Section ---
            _buildHeader('Order Summary 📝'),
            const SizedBox(height: 12),
            _buildStatusBadge(_order.status),
            const SizedBox(height: 16),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                // 🚨 FIX: Use theme-aware color for card border
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabelValue(
                      'Supplier',
                      _order.supplier.name,
                      Icons.business,
                    ),
                    _buildLabelValue('Order Date', date, Icons.calendar_today),
                    _buildLabelValue(
                      'Total Cost',
                      totalFormatted,
                      Icons.payments,
                      isTotal: true,
                    ),
                    if (_order.notes.isNotEmpty)
                      _buildLabelValue('Notes', _order.notes, Icons.notes),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- Items List Section ---
            _buildHeader('Items List 📦'),
            const SizedBox(height: 12),
            _buildItemsTable(ref),

            const SizedBox(height: 30),

            // --- Action Buttons Section ---
            _buildActionButtons(context, ref),
          ],
        ),
      ),
    );
  }

  // 🚨 MODIFIED: Ensure header text color is visible in dark theme
  Widget _buildHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        // Using onSurface ensures the text is visible against the background
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  // 🚨 MODIFIED: Ensure status is capitalized
  Widget _buildStatusBadge(String status) {
    final displayStatus = _capitalizeFirstLetter(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _statusBackgroundColor(status),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor(status), width: 1),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          color: _statusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  // 🚨 MODIFIED: Ensure label/value text colors are visible in dark theme
  Widget _buildLabelValue(
      String label,
      String value,
      IconData icon, {
        bool isTotal = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            // 🚨 FIX: Use theme-aware color for icons
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                    fontSize: 16,
                    // 🚨 FIX: Use theme-aware color for labels
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isTotal ? 18 : 15,
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                    // 🚨 FIX: Use onSurface for primary value text color
                    color: isTotal
                        ? Theme.of(context).colorScheme.primary // Keep primary for total
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryItemsProvider);
    final textTheme = Theme.of(context).textTheme.bodyMedium; // Base text style

    return inventoryAsync.when(
      data: (inventoryItems) {
        // Map inventory items for quick lookup
        final inventoryMap = {
          for (var item in inventoryItems)
            item.id: PurchaseInventoryItem.fromInventoryItem(item),
        };

        // 🚨 FIX: Formatter for Quantity (no currency symbol)
        final qtyFormatter = NumberFormat('#,##0');
        // Formatter for Currency/Cost (with commas)
        final costFormatter = NumberFormat('#,##0');

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 56,
              // 🚨 FIX: Ensure heading text color is visible in dark theme
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              columns: const [
                DataColumn(label: Text('Item')),
                DataColumn(label: Text('Qty'), numeric: true),
                DataColumn(label: Text('Uit')),
                DataColumn(label: Text('Unit Cost'), numeric: true),
                DataColumn(label: Text('Total'), numeric: true),
              ],
              rows: _order.items.map((item) {
                // Safely parse and format numbers
                final qty = item.quantity.toInt();
                final price = item.price.toInt();
                final total = qty * price;

                final inventoryItem =
                    inventoryMap[item.inventoryItemId] ??
                        PurchaseInventoryItem(
                          id: 0,
                          name: item.itemName,
                          unit: 'N/A',
                        );

                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(
                          inventoryItem.name,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme, // 🚨 FIX: Apply theme text style
                        ),
                      ),
                    ),
                    // 🚨 FIX: Format QTY
                    DataCell(
                      Text(
                        qtyFormatter.format(qty),
                        style: textTheme, // 🚨 FIX: Apply theme text style
                      ),
                    ),
                    DataCell(
                      Text(
                        inventoryItem.unit,
                        style: textTheme, // 🚨 FIX: Apply theme text style
                      ),
                    ),
                    DataCell(
                      Text(
                        costFormatter.format(price),
                        style: textTheme, // 🚨 FIX: Apply theme text style
                      ),
                    ),
                    DataCell(
                      Text(
                        costFormatter.format(total),
                        style: textTheme?.copyWith(fontWeight: FontWeight.bold), // 🚨 FIX: Apply theme text style
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
      loading: () => const Center(child: LinearProgressIndicator()),
      error: (e, _) {
        // Log the error for debug purposes
        debugPrint("❌ Error loading inventory: $e");
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Failed to load inventory details: ${e.toString().split(':')[0]}',
            style: const TextStyle(color: Colors.red),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    final isPending = _order.status.toLowerCase() == 'pending';
    final isApproved = _order.status.toLowerCase() == 'approved';
    final isCompleted =
        _order.status.toLowerCase() == 'completed' ||
            _order.status.toLowerCase() == 'received';

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Cancel/Delete Button (Visible for Pending)
          if (isPending)
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                label: const Text(
                  'Cancel Order',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSubmitting
                    ? null
                    : () => _showConfirmationDialog(
                  context,
                  'Cancel Order?',
                  'Are you sure you want to cancel this pending purchase order? This action cannot be undone.',
                      () => _handleUpdateStatus(ref, 'cancelled'),
                ),
              ),
            ),

          if (isPending) const SizedBox(width: 12),

          // Approve Button (Visible for Pending)
          if (isPending)
            Expanded(
              child: ElevatedButton.icon(
                icon: _isSubmitting
                    ? const SizedBox.shrink()
                    : const Icon(Icons.check_circle_outline),
                label: _isSubmitting
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                )
                    : const Text('Approve Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSubmitting
                    ? null
                    : () => _handleUpdateStatus(ref, 'approved'),
              ),
            ),

          // Receive Goods Button (Visible for Approved)
          if (isApproved)
            Expanded(
              child: ElevatedButton.icon(
                icon: _isSubmitting
                    ? const SizedBox.shrink()
                    : const Icon(Icons.move_to_inbox),
                label: _isSubmitting
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                )
                    : const Text('Receive Goods'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSubmitting
                    ? null
                    : () => _showConfirmationDialog(
                  context,
                  'Receive All Goods?',
                  'Confirm receipt of ALL items in this order. This will mark the order as Received/Completed.',
                      () => _handleReceiveGoods(ref),
                ),
              ),
            ),

          // Show status text if completed
          if (isCompleted)
            Chip(
              avatar: Icon(
                Icons.done_all,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: Text(
                'Order Finalized',
                // 🚨 FIX: Use onSurface for text color
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              // 🚨 FIX: Use theme-aware background color
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
        ],
      ),
    );
  }

  // --------------------- HANDLERS AND DIALOGS ------------------------

  // Utility to show a confirmation dialog for sensitive actions
  Future<void> _showConfirmationDialog(
      BuildContext context,
      String title,
      String content,
      VoidCallback onConfirm,
      ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                onConfirm(); // Execute action
              },
              child: Text(
                title.contains('Cancel') ? 'Yes, Cancel' : 'Yes, Confirm',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleUpdateStatus(WidgetRef ref, String status) async {
    setState(() => _isSubmitting = true);
    try {
      final updatedOrder = await ref
          .read(purchaseOrdersApiServiceProvider)
          .updateOrderStatus(_order.id, status);

      // Invalidate the provider so the list screen updates automatically
      ref.invalidate(purchaseOrdersProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order status updated to ${_capitalizeFirstLetter(status)}!',
          ), // 🚨 FIX: Capitalize status in SnackBar
        ),
      );

      setState(() => _order = updatedOrder);
    } catch (e) {
      debugPrint("❌ Status update failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update status: ${e.toString().split(':')[0]}',
          ),
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleReceiveGoods(WidgetRef ref) async {
    setState(() => _isSubmitting = true);

    if (kDebugMode) {
      print("🔄 ======== HANDLE RECEIVE GOODS START ========");
    }

    try {
      final payloadItems = _order.items.map((i) {
        // Convert quantity to INT, not double
        final qty = int.tryParse(i.quantity.toString()) ?? i.quantity.toInt();
        final inventoryId = i.inventoryItemId;

        return {
          "inventoryItemId": inventoryId,
          "receivedQuantity": qty,
        };
      }).toList();

      // Format date to match backend expectation
      final now = DateTime.now().toUtc(); // Use UTC timezone
      final formattedDate = DateFormat(
        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
      ).format(now);

      final payload = {
        "purchaseOrderId": _order.id,
        "receivedDate": formattedDate, // Properly formatted date
        "notes": "All items received.",
        "items": payloadItems,
      };

      if (kDebugMode) {
        print("🔍 Final Payload to send:");
        print(payload);
      }

      // Use the updated receiveGoods method that returns PurchaseOrder
      final updatedOrder = await ref
          .read(purchaseOrdersApiServiceProvider)
          .receiveGoods(payload: payload);

      if (kDebugMode) {
        print("✅ Goods received and order updated: ${updatedOrder.id}");
      }
      if (kDebugMode) {
        print("✅ New order status: ${updatedOrder.status}");
      }

      // Update the local state with the returned updated order
      setState(() => _order = updatedOrder);

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(content: Text('Goods received successfully!')),
      );
    } catch (e) {
      if (kDebugMode) {
        print("❌ Goods receipt failed: $e");
      }

      // Show error message to user
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to receive goods: ${e.toString().split(':')[0]}')));
    } finally {
      setState(() => _isSubmitting = false);
      if (kDebugMode) {
        print("🔄 ======== HANDLE RECEIVE GOODS END ========");
      }
    }
  }
}