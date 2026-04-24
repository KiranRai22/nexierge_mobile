class Budget {
  final String id;
  final String category;
  final double limit;
  final double spent;

  Budget({
    required this.id,
    required this.category,
    required this.limit,
    this.spent = 0.0,
  });

  Budget copyWith({
    String? id,
    String? category,
    double? limit,
    double? spent,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      limit: limit ?? this.limit,
      spent: spent ?? this.spent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'budget_limit': limit,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      category: map['category'] as String,
      limit: (map['budget_limit'] as num).toDouble(),
      spent: 0.0,
    );
  }
}
