import 'package:equatable/equatable.dart';

/// Whether a transaction adds money (income) or removes it (expense).
enum TransactionType { income, expense }

/// A single money movement.
///
/// Pure domain object — no Drift, no Flutter. [amount] is always positive; the
/// [type] gives it direction, exposed conveniently via [signedAmount].
class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.createdAt,
    this.category = 'General',
    this.note,
  });

  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  bool get isIncome => type == TransactionType.income;

  /// Positive for income, negative for expense — handy for balance maths.
  double get signedAmount => isIncome ? amount : -amount;

  Transaction copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    String? note,
    DateTime? date,
  }) {
    return Transaction(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    type,
    category,
    note,
    date,
    createdAt,
  ];
}
