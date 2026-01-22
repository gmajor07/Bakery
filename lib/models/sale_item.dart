import 'package:flutter/material.dart';

class SaleItem {
  final int id;
  final String customer;
  final String date;
  final double amount;
  final String status;
  final String paymentStatus;
  final List<SaleProduct> items;
  final bool isCredit;
  final double outstandingBalance;

  int get receiptNumber => id;

  SaleItem({
    required this.id,
    required this.customer,
    required this.date,
    required this.amount,
    required this.status,
    required this.paymentStatus,
    required this.items,
    required this.isCredit,
    required this.outstandingBalance,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'] ?? 0,
      customer: json['customer'] is Map
          ? json['customer']['name'] ?? 'Cash'
          : json['customer']?.toString() ?? 'Cash',
      date: json['createdAt'] ?? '',
      amount: double.tryParse(json['total'].toString()) ?? 0.0,
      status: json['status']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => SaleProduct.fromJson(item))
          .toList(),
      isCredit: json['isCredit'] ?? false,
      outstandingBalance:
      double.tryParse(json['outstandingBalance']?.toString() ?? '0') ??
          0.0,
    );
  }
  // Add inside SaleItem class

  double get subtotal {
    return items.fold(
      0.0,
          (sum, item) => sum + (item.price * item.quantity),
    );
  }

  double get vat {
    // Change 0.18 if your VAT rate is different
    return subtotal * 0.18;
  }


  // 💡 NEW GETTER: Provides the payment method type as a string
  String get paymentMethod {
    return isCredit ? 'Credit' : 'Cash';
  }

  // Helper method to get proper status display (Unchanged)
  String get displayStatus {
    if (isCredit) {
      if (outstandingBalance <= 0) {
        return 'Credit Paid';
      } else {
        return 'Credit Unpaid';
      }
    } else {
      if (outstandingBalance <= 0) {
        return 'Paid';
      } else {
        return 'Unpaid';
      }
    }
  }

  // Helper method to check if fully paid (Unchanged)
  bool get isFullyPaid => outstandingBalance <= 0;

  // Helper method to get status color (Unchanged)
  Color get statusColor {
    if (isCredit) {
      return outstandingBalance <= 0 ? Colors.brown : Colors.orange;
    } else {
      return outstandingBalance <= 0 ? Colors.brown : Colors.red;
    }
  }
}

class SaleProduct {
  final String name;
  final int quantity;
  final double price;

  SaleProduct({
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory SaleProduct.fromJson(Map<String, dynamic> json) {
    return SaleProduct(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }
}