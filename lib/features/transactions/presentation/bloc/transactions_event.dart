part of 'transactions_bloc.dart';

sealed class TransactionsEvent extends Equatable {
  const TransactionsEvent();

  @override
  List<Object?> get props => [];
}

/// Start listening to the live stream of transactions.
class TransactionsSubscriptionRequested extends TransactionsEvent {
  const TransactionsSubscriptionRequested();
}

class TransactionAdded extends TransactionsEvent {
  const TransactionAdded({
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    this.category = 'General',
    this.note,
  });

  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final String? note;
  final DateTime date;

  @override
  List<Object?> get props => [title, amount, type, category, note, date];
}

class TransactionDeleted extends TransactionsEvent {
  const TransactionDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
