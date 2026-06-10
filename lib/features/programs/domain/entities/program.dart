import 'package:equatable/equatable.dart';

/// Lifecycle of a training program.
enum ProgramStatus { active, upcoming, completed }

/// A training program with its enrolment and finance roll-ups.
///
/// Pure domain object — no Drift, no Flutter. The finance figures are stored
/// directly (income/spent/budget); the ratios below are derived.
class Program extends Equatable {
  const Program({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.status,
    required this.hue,
    required this.start,
    required this.end,
    required this.weeks,
    required this.location,
    required this.trainer,
    required this.capacity,
    required this.enrolled,
    required this.fee,
    required this.budget,
    required this.income,
    required this.spent,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String code;
  final String category;
  final ProgramStatus status;
  final double hue;
  final String start;
  final String end;
  final int weeks;
  final String location;
  final String trainer;
  final int capacity;
  final int enrolled;
  final double fee;
  final double budget;
  final double income;
  final double spent;
  final int sortOrder;

  double get profit => income - spent;
  int get budgetUsedPct => budget == 0 ? 0 : ((spent / budget) * 100).round();
  int get fillPct => capacity == 0 ? 0 : ((enrolled / capacity) * 100).round();
  int get marginPct => income == 0 ? 0 : ((profit / income) * 100).round();

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    category,
    status,
    hue,
    start,
    end,
    weeks,
    location,
    trainer,
    capacity,
    enrolled,
    fee,
    budget,
    income,
    spent,
    sortOrder,
  ];
}
