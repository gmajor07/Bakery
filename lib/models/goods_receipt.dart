class GoodsReceipt {
  final int id;
  final int purchaseOrderId;
  final String receivedDate;
  final double receivedQuantity;
  final String status;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final int createdById;
  final String? supplierName;
  final double? total;

  GoodsReceipt({
    required this.id,
    required this.purchaseOrderId,
    required this.receivedDate,
    required this.receivedQuantity,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.createdById,
    this.supplierName,
    this.total,
  });

  factory GoodsReceipt.fromJson(Map<String, dynamic> json) {
    return GoodsReceipt(
      id: json['id'],
      purchaseOrderId: json['purchaseOrderId'],
      receivedDate: json['receivedDate'],
      receivedQuantity: (json['receivedQuantity'] as num).toDouble(),
      status: json['status'],
      notes: json['notes'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      createdById: json['createdById'],
      supplierName: json['supplierName'],
      total: json['total'] != null ? (json['total'] as num).toDouble() : null,
    );
  }
}
