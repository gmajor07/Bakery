class PurchaseSummary {
  final double totalPurchasesThisMonth;
  final int pendingPurchaseOrders;
  final String purchaseGrowth;
  final List<WeeklyPurchase> weeklyPurchasesList;

  PurchaseSummary({
    required this.totalPurchasesThisMonth,
    required this.pendingPurchaseOrders,
    required this.purchaseGrowth,
    required this.weeklyPurchasesList,
  });

  factory PurchaseSummary.fromJson(Map<String, dynamic> json) {
    return PurchaseSummary(
      totalPurchasesThisMonth: (json['totalPurchasesThisMonth'] as num).toDouble(),
      pendingPurchaseOrders: json['pendingPurchaseOrders'],
      purchaseGrowth: json['purchaseGrowth'],
      weeklyPurchasesList: (json['weeklyPurchasesList'] as List)
          .map((e) => WeeklyPurchase.fromJson(e))
          .toList(),
    );
  }
}

class WeeklyPurchase {
  final String weekStart;
  final double total;

  WeeklyPurchase({required this.weekStart, required this.total});

  factory WeeklyPurchase.fromJson(Map<String, dynamic> json) {
    return WeeklyPurchase(
      weekStart: json['weekStart'],
      total: (json['total'] as num).toDouble(),
    );
  }
}
