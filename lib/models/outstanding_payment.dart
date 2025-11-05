class OutstandingPayment {
  final int saleId;
  final int receiptNumber;
  final String customer;
  final double totalAmount;
  final double paidAmount;
  final double balance;
  final DateTime dueDate;

  OutstandingPayment({
    required this.saleId,
    required this.receiptNumber,
    required this.customer,
    required this.totalAmount,
    required this.paidAmount,
    required this.balance,
    required this.dueDate,
  });

  factory OutstandingPayment.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    return OutstandingPayment(
      saleId: json['saleId'] ?? json['id'] ?? 0,
      receiptNumber: json['receiptNumber'] ?? json['id'] ?? 0,
      customer: customer != null ? customer['name'] ?? 'Walk-in' : 'Walk-in',
      totalAmount: (json['totalAmount'] ?? json['total'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? json['paid'] ?? 0).toDouble(),
      balance: (json['balance'] ?? json['outstandingBalance'] ?? 0).toDouble(),
      dueDate:
          DateTime.tryParse(json['creditDueDate']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
