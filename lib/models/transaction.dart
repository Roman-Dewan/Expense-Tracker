enum TransactionType { income, expense, transfer }

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String? categoryId;
  final String accountId;
  final String? toAccountId; // Populated only when type == TransactionType.transfer
  final String? notes;
  final String? receiptImagePath;
  final bool isRecurring;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    this.categoryId,
    this.accountId = 'acc_cash',
    this.toAccountId,
    this.notes,
    this.receiptImagePath,
    this.isRecurring = false,
  });

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    TransactionType? type,
    String? categoryId,
    String? accountId,
    String? toAccountId,
    String? notes,
    String? receiptImagePath,
    bool? isRecurring,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      notes: notes ?? this.notes,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }

  // SQLite database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.name, // Store as string 'income', 'expense', 'transfer' for clarity
      'category_id': categoryId,
      'account_id': accountId,
      'to_account_id': toAccountId,
      'notes': notes,
      'receipt_image_path': receiptImagePath,
      'is_recurring': isRecurring ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    TransactionType parsedType = TransactionType.expense;
    final typeVal = map['type'];
    if (typeVal is int) {
      if (typeVal >= 0 && typeVal < TransactionType.values.length) {
        parsedType = TransactionType.values[typeVal];
      }
    } else if (typeVal is String) {
      parsedType = TransactionType.values.firstWhere(
        (e) => e.name.toLowerCase() == typeVal.toLowerCase(),
        orElse: () => TransactionType.expense,
      );
    }

    return Transaction(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      type: parsedType,
      categoryId: map['category_id'] as String?,
      accountId: (map['account_id'] as String?) ?? 'acc_cash',
      toAccountId: map['to_account_id'] as String?,
      notes: map['notes'] as String?,
      receiptImagePath: map['receipt_image_path'] as String?,
      isRecurring: (map['is_recurring'] as int?) == 1,
    );
  }

  // Backward compatibility with previous JSON format and JSON backup
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.name,
      'category_id': categoryId,
      'account_id': accountId,
      'to_account_id': toAccountId,
      'notes': notes,
      'receipt_image_path': receiptImagePath,
      'is_recurring': isRecurring,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    TransactionType parsedType = TransactionType.expense;
    final typeVal = json['type'];
    if (typeVal is int) {
      if (typeVal >= 0 && typeVal < TransactionType.values.length) {
        parsedType = TransactionType.values[typeVal];
      }
    } else if (typeVal is String) {
      parsedType = TransactionType.values.firstWhere(
        (e) => e.name.toLowerCase() == typeVal.toLowerCase(),
        orElse: () => TransactionType.expense,
      );
    }

    return Transaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      type: parsedType,
      categoryId: json['category_id'] as String?,
      accountId: (json['account_id'] as String?) ?? 'acc_cash',
      toAccountId: json['to_account_id'] as String?,
      notes: json['notes'] as String?,
      receiptImagePath: json['receipt_image_path'] as String?,
      isRecurring: json['is_recurring'] == true,
    );
  }
}
