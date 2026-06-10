/// Plain data models for the Training Finance Management System module.
///
/// This is a self-contained, presentation-only feature ported from a Claude
/// Design handoff. The models mirror the prototype's mock dataset; there is no
/// persistence layer — see `tf_mock_data.dart` for the seeded values.
library;

/// Lifecycle of a training program.
enum ProgramStatus { active, upcoming, completed }

/// Whether a transaction brings money in or sends it out.
enum TxKind { income, expense }

/// A participant's payment standing.
enum PayStatus { paid, partial, pending }

/// Reconciliation state of an uploaded receipt.
enum ReceiptStatus { matched, unmatched, review }

/// A training program with its enrolment and finance roll-ups.
class Program {
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

  double get profit => income - spent;
  int get budgetUsedPct => ((spent / budget) * 100).round();
  int get fillPct => ((enrolled / capacity) * 100).round();
  int get marginPct => income == 0 ? 0 : ((profit / income) * 100).round();
}

/// A single income or expense line.
class Tx {
  const Tx({
    required this.id,
    required this.kind,
    required this.cat,
    required this.title,
    required this.amount,
    required this.date,
    required this.programId,
    required this.method,
    required this.receipt,
  });

  final String id;
  final TxKind kind;
  final String cat;
  final String title;
  final double amount;
  final String date;
  final String? programId;
  final String method;
  final bool receipt;

  bool get isIncome => kind == TxKind.income;
}

/// An enrolled trainee and their payment progress.
class Participant {
  const Participant({
    required this.id,
    required this.name,
    required this.programId,
    required this.pay,
    required this.paid,
    required this.fee,
    required this.enrolled,
    required this.hue,
  });

  final String id;
  final String name;
  final String programId;
  final PayStatus pay;
  final double paid;
  final double fee;
  final String enrolled;
  final double hue;

  double get due => fee - paid;
  int get pct => fee == 0 ? 0 : ((paid / fee) * 100).round();
}

/// An org-wide budget allocation for a spend category.
class BudgetLine {
  const BudgetLine({
    required this.cat,
    required this.label,
    required this.alloc,
    required this.spent,
    required this.hue,
  });

  final String cat;
  final String label;
  final double alloc;
  final double spent;
  final double hue;

  int get pct => alloc == 0 ? 0 : ((spent / alloc) * 100).round();
  bool get over => spent > alloc;
}

/// A captured receipt awaiting or holding a match to a transaction.
class Receipt {
  const Receipt({
    required this.id,
    required this.vendor,
    required this.amount,
    required this.date,
    required this.cat,
    required this.status,
    required this.programId,
  });

  final String id;
  final String vendor;
  final double amount;
  final String date;
  final String cat;
  final ReceiptStatus status;
  final String? programId;
}

/// A labelled, hue-tinted transaction category.
class Category {
  const Category({required this.id, required this.label, required this.hue});

  final String id;
  final String label;
  final double hue;
}

/// Static organisation profile shown in headers.
class Org {
  const Org({required this.name, required this.period, required this.cash});

  final String name;
  final String period;
  final double cash;
}
