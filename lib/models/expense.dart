// lib/models/expense.dart

class ExpenseCategory {
  final int id;
  final String name;

  ExpenseCategory({
    required this.id,
    required this.name,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'N/A',
    );
  }
}

class Expense {
  final int id;
  final int amount;
  // NOTE: Keeping date as String/dynamic in the model is safer for quick serialization/deserialization,
  // but if we need a DateTime object:
  final String date; // Changed to String to simplify parsing/data handling in the model
  final String status;
  final String notes;
  final String paymentMethod;
  final ExpenseCategory category;
  final String updatedByName;

  Expense({
    required this.id,
    required this.amount,
    required this.date,
    required this.status,
    required this.notes,
    required this.paymentMethod,
    required this.category,
    required this.updatedByName,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) =>
        val is int ? val : (int.tryParse(val.toString()) ?? 0);

    return Expense(
      id: parseInt(json['id']),
      amount: parseInt(json['amount']),
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'N/A',
      notes: json['notes']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? 'N/A',

      // ✅ SAFE category parsing
      category: json['expenseCategory'] is Map<String, dynamic>
          ? ExpenseCategory.fromJson(
        json['expenseCategory'] as Map<String, dynamic>,
      )
          : ExpenseCategory(
        id: parseInt(json['expenseCategoryId']),
        name: 'Unknown',
      ),

      // ✅ SAFE updatedBy parsing
      updatedByName: json['updatedBy'] is Map<String, dynamic>
          ? json['updatedBy']['name']?.toString() ?? 'Unknown'
          : 'Unknown',
    );
  }

}