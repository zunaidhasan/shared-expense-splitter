class Expense {
  final String id;
  final String title;
  final double amount;
  final String payerId;
  final List<String> participantIds;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.payerId,
    required this.participantIds,
    required this.createdAt,
  });

  /// Equal share per participant
  double get sharePerPerson {
    if (participantIds.isEmpty) return 0;
    return amount / participantIds.length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'payerId': payerId,
        'participantIds': participantIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      payerId: json['payerId'] as String,
      participantIds: List<String>.from(json['participantIds'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
