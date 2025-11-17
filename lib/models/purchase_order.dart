class PurchaseOrder {
  final int id;
  final int supplierId;
  final double totalCost;
  final String status;
  final String notes;
  final String createdAt;
  final Supplier supplier;
  final List<PurchaseOrderItem> items;

  PurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.totalCost,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.supplier,
    required this.items,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['id'],
      supplierId: json['supplierId'],
      totalCost: (json['totalCost'] as num).toDouble(),
      status: json['status'],
      notes: json['notes'] ?? '',
      createdAt: json['createdAt'],
      supplier: Supplier.fromJson(json['supplier']),
      items: (json['items'] as List<dynamic>)
          .map((e) => PurchaseOrderItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  /// ✅ Correct copyWith
  PurchaseOrder copyWith({
    int? id,
    int? supplierId,
    double? totalCost,
    String? status,
    String? notes,
    String? createdAt,
    Supplier? supplier,
    List<PurchaseOrderItem>? items,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      totalCost: totalCost ?? this.totalCost,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      supplier: supplier ?? this.supplier,
      items: items ?? this.items,
    );
  }
}

class Supplier {
  final int id;
  final String name;

  Supplier({required this.id, required this.name});

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(id: json['id'], name: json['name']);
  }
}

class PurchaseOrderItem {
  final int id;
  final int inventoryItemId;
  final String itemName;
  final int quantity;
  final double price;

  PurchaseOrderItem({
    required this.id,
    required this.inventoryItemId,
    required this.itemName,
    required this.quantity,
    required this.price,
  });

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItem(
      id: json['id'],
      inventoryItemId: json['inventoryItemId'],
      itemName: json['inventoryItem'] != null
          ? json['inventoryItem']['name']
          : 'Unknown',
      quantity: json['quantity'],
      price: (json['price'] as num).toDouble(),
    );
  }

  /// Optional, but recommended
  PurchaseOrderItem copyWith({
    int? id,
    int? inventoryItemId,
    String? itemName,
    int? quantity,
    double? price,
  }) {
    return PurchaseOrderItem(
      id: id ?? this.id,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }
}
