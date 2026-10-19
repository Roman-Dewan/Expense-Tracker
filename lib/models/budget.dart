class Budget {
  final String id;
  final String categoryId;
  final String monthYear; // Format 'YYYY-MM'
  final double amountLimit;

  const Budget({
    required this.id,
    required this.categoryId,
    required this.monthYear,
    required this.amountLimit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'month_year': monthYear,
      'amount_limit': amountLimit,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      monthYear: map['month_year'] as String,
      amountLimit: (map['amount_limit'] as num).toDouble(),
    );
  }
}
