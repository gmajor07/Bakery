// models/material_receipt.dart

class OrderedItem {
  final int id;
  final String name;
  final double quantity;
  final double unitPrice;
  final double total;
  final String unit;

  OrderedItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.unit,
  });

  factory OrderedItem.fromJson(Map<String, dynamic> json) {
    final qty = json['quantity'] ?? json['receivedQuantity'] ?? 0;
    final price = json['unitPrice'] ?? json['price'] ?? json['unit_price'] ?? 0;
    final total =
        json['total'] ??
        json['lineTotal'] ??
        (qty is num && price is num ? qty * price : 0);

    return OrderedItem(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? json['itemName'] ?? '',
      quantity: (qty is num)
          ? qty.toDouble()
          : double.tryParse(qty.toString()) ?? 0.0,
      unitPrice: (price is num)
          ? price.toDouble()
          : double.tryParse(price.toString()) ?? 0.0,
      total: (total is num)
          ? total.toDouble()
          : double.tryParse(total.toString()) ?? 0.0,
      unit: json['unit'] ?? json['uom'] ?? '',
    );
  }
}

class MaterialReceipt {
  final int id;
  final int purchaseOrderId;
  final DateTime receivedDate;
  final double receivedQuantity;
  final String status;
  final String supplierName;
  final double total;
  final List<OrderedItem> items;

  MaterialReceipt({
    required this.id,
    required this.purchaseOrderId,
    required this.receivedDate,
    required this.receivedQuantity,
    required this.status,
    required this.supplierName,
    required this.total,
    required this.items,
  });

  factory MaterialReceipt.fromJson(Map<String, dynamic> json) {
    final purchaseOrder = json['purchaseOrder'] ?? {};
    final supplier = (purchaseOrder is Map && purchaseOrder['supplier'] != null)
        ? purchaseOrder['supplier']
        : json['supplier'] ?? {};

    // Items may be in `items`, `orderLines`, `purchaseOrder.items`, or not present
    List<dynamic> rawItems = [];
    if (json['items'] is List) {
      rawItems = json['items'];
    } else if (json['orderLines'] is List) {
      rawItems = json['orderLines'];
    } else if (purchaseOrder is Map && purchaseOrder['items'] is List) {
      rawItems = purchaseOrder['items'];
    } else if (json['purchaseOrder'] is Map &&
        json['purchaseOrder']['items'] is List) {
      rawItems = json['purchaseOrder']['items'];
    }

    final items = rawItems.map((e) {
      if (e is Map<String, dynamic>) return OrderedItem.fromJson(e);
      if (e is Map) return OrderedItem.fromJson(Map<String, dynamic>.from(e));
      return OrderedItem(
        id: 0,
        name: '',
        quantity: 0,
        unitPrice: 0,
        total: 0,
        unit: '',
      );
    }).toList();

    return MaterialReceipt(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      purchaseOrderId: json['purchaseOrderId'] is int
          ? json['purchaseOrderId']
          : int.tryParse(json['purchaseOrderId']?.toString() ?? '0') ?? 0,
      receivedDate:
          DateTime.tryParse(
            json['receivedDate']?.toString() ??
                json['createdAt']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      receivedQuantity: (json['receivedQuantity'] is num)
          ? (json['receivedQuantity'] as num).toDouble()
          : double.tryParse(json['receivedQuantity']?.toString() ?? '0') ?? 0.0,
      status: (json['status'] ?? '').toString(),
      supplierName:
          (json['supplierName'] ??
                  (supplier is Map ? supplier['name'] : supplier) ??
                  (purchaseOrder is Map && purchaseOrder['supplier'] is Map
                      ? purchaseOrder['supplier']['name']
                      : null) ??
                  '')
              .toString(),
      total: (json['total'] is num)
          ? (json['total'] as num).toDouble()
          : double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      items: items,
    );
  }
}
