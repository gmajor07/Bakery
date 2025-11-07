class PaymentRecord {
  final int id;
  final int saleId;
  final int receiptNumber;
  final String customerName;
  final double amount;
  final DateTime paymentDate;
  final String? notes;

  PaymentRecord({
    required this.id,
    required this.saleId,
    required this.receiptNumber,
    required this.customerName,
    required this.amount,
    required this.paymentDate,
    this.notes,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    return PaymentRecord(
      id: json['id'],
      saleId: json['saleId'] ?? 0,
      receiptNumber: json['receiptNumber'] ?? json['id'] ?? 0,

      customerName: customer != null
          ? customer['name'] ?? 'Unknown'
          : 'Unknown',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate']),
      notes: json['notes']?.toString(),
    );
  }
}
