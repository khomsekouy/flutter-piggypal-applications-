import 'package:flutter_piggypal_app/features/training_finance/data/tf_models.dart';
import 'package:intl/intl.dart';

/// Seeded, read-only dataset backing the Training Finance module.
///
/// Mirrors the prototype's `window.DB`. Everything is computed once at
/// construction; screens read from the singleton [TFData.instance].
class TFData {
  TFData._();

  static final TFData instance = TFData._();

  // ── Formatting ────────────────────────────────────────────────────────────
  static final NumberFormat _whole = NumberFormat('#,##0', 'en_US');

  /// `$1,234` — whole-dollar currency.
  static String fmt(num n) => '\$${_whole.format(n.round())}';

  /// `$1.2k` / `$12k` — compact currency for tight spaces.
  static String fmtK(num n) {
    final a = n.abs();
    if (a >= 1000) {
      final sign = n < 0 ? '-' : '';
      final scaled = a / 1000;
      final digits = a >= 10000 ? 0 : 1;
      return '$sign\$${scaled.toStringAsFixed(digits)}k';
    }
    return fmt(n);
  }

  // ── Programs ──────────────────────────────────────────────────────────────
  final List<Program> programs = const [
    Program(
      id: 'p1',
      name: 'Advanced Data Analytics Bootcamp',
      code: 'DAB-204',
      category: 'Data & AI',
      status: ProgramStatus.active,
      hue: 262,
      start: 'May 12',
      end: 'Jul 04, 2026',
      weeks: 8,
      location: 'Hybrid · Austin HQ',
      trainer: 'Dr. Lena Ortiz',
      capacity: 28,
      enrolled: 24,
      fee: 1200,
      budget: 19000,
      income: 26400,
      spent: 13850,
    ),
    Program(
      id: 'p2',
      name: 'Cybersecurity Fundamentals',
      code: 'CSF-118',
      category: 'Security',
      status: ProgramStatus.active,
      hue: 192,
      start: 'Apr 28',
      end: 'Jun 20, 2026',
      weeks: 7,
      location: 'On-site · Denver',
      trainer: 'Marcus Webb',
      capacity: 30,
      enrolled: 30,
      fee: 900,
      budget: 16500,
      income: 27000,
      spent: 14200,
    ),
    Program(
      id: 'p3',
      name: 'Leadership Essentials Workshop',
      code: 'LEW-091',
      category: 'Management',
      status: ProgramStatus.active,
      hue: 28,
      start: 'Jun 02',
      end: 'Jun 27, 2026',
      weeks: 4,
      location: 'Online · Live',
      trainer: 'Priya Nair',
      capacity: 20,
      enrolled: 18,
      fee: 650,
      budget: 7200,
      income: 9750,
      spent: 4980,
    ),
    Program(
      id: 'p4',
      name: 'UX Design Intensive',
      code: 'UXD-330',
      category: 'Design',
      status: ProgramStatus.upcoming,
      hue: 326,
      start: 'Jul 14',
      end: 'Aug 22, 2026',
      weeks: 6,
      location: 'On-site · Seattle',
      trainer: 'Tom Becker',
      capacity: 16,
      enrolled: 9,
      fee: 1500,
      budget: 14000,
      income: 7500,
      spent: 6100,
    ),
    Program(
      id: 'p5',
      name: 'Digital Marketing Certification',
      code: 'DMC-150',
      category: 'Marketing',
      status: ProgramStatus.active,
      hue: 152,
      start: 'May 05',
      end: 'Jun 30, 2026',
      weeks: 8,
      location: 'Online · Live',
      trainer: 'Sara Klein',
      capacity: 32,
      enrolled: 28,
      fee: 750,
      budget: 11800,
      income: 18900,
      spent: 8700,
    ),
    Program(
      id: 'p6',
      name: 'PMP Certification Prep',
      code: 'PMP-202',
      category: 'Management',
      status: ProgramStatus.completed,
      hue: 218,
      start: 'Feb 10',
      end: 'Apr 18, 2026',
      weeks: 10,
      location: 'Hybrid · Austin HQ',
      trainer: 'Dr. Lena Ortiz',
      capacity: 24,
      enrolled: 22,
      fee: 1100,
      budget: 15500,
      income: 24200,
      spent: 15050,
    ),
  ];

  // ── Categories ────────────────────────────────────────────────────────────
  final List<Category> expenseCats = const [
    Category(id: 'venue', label: 'Venue & Facilities', hue: 262),
    Category(id: 'trainer', label: 'Trainer Fees', hue: 192),
    Category(id: 'materials', label: 'Materials & Print', hue: 28),
    Category(id: 'catering', label: 'Catering', hue: 152),
    Category(id: 'marketing', label: 'Marketing', hue: 326),
    Category(id: 'equipment', label: 'Equipment', hue: 218),
    Category(id: 'travel', label: 'Travel', hue: 96),
  ];

  final List<Category> incomeCats = const [
    Category(id: 'tuition', label: 'Tuition & Fees', hue: 152),
    Category(id: 'corporate', label: 'Corporate Sponsor', hue: 192),
    Category(id: 'grant', label: 'Grants', hue: 262),
    Category(id: 'materials_sale', label: 'Materials Sales', hue: 28),
  ];

  // ── Transactions ──────────────────────────────────────────────────────────
  final List<Tx> tx = const [
    Tx(
      id: 't1',
      kind: TxKind.income,
      cat: 'tuition',
      title: 'Tuition — A. Mensah',
      amount: 1200,
      date: 'Jun 07',
      programId: 'p1',
      method: 'Card',
      receipt: true,
    ),
    Tx(
      id: 't2',
      kind: TxKind.expense,
      cat: 'catering',
      title: 'Catering — Week 4 lunch',
      amount: 640,
      date: 'Jun 07',
      programId: 'p1',
      method: 'Card',
      receipt: true,
    ),
    Tx(
      id: 't3',
      kind: TxKind.income,
      cat: 'corporate',
      title: 'Corporate sponsorship — Northwind',
      amount: 5000,
      date: 'Jun 06',
      programId: 'p2',
      method: 'Transfer',
      receipt: true,
    ),
    Tx(
      id: 't4',
      kind: TxKind.expense,
      cat: 'venue',
      title: 'Venue rental — Denver hall',
      amount: 2200,
      date: 'Jun 05',
      programId: 'p2',
      method: 'Transfer',
      receipt: true,
    ),
    Tx(
      id: 't5',
      kind: TxKind.income,
      cat: 'tuition',
      title: 'Tuition — R. Silva',
      amount: 650,
      date: 'Jun 05',
      programId: 'p3',
      method: 'Card',
      receipt: false,
    ),
    Tx(
      id: 't6',
      kind: TxKind.expense,
      cat: 'materials',
      title: 'Workbooks print run',
      amount: 480,
      date: 'Jun 04',
      programId: 'p3',
      method: 'Card',
      receipt: true,
    ),
    Tx(
      id: 't7',
      kind: TxKind.expense,
      cat: 'trainer',
      title: 'Guest trainer honorarium',
      amount: 1500,
      date: 'Jun 03',
      programId: 'p1',
      method: 'Transfer',
      receipt: true,
    ),
    Tx(
      id: 't8',
      kind: TxKind.income,
      cat: 'tuition',
      title: 'Tuition — J. Park',
      amount: 750,
      date: 'Jun 03',
      programId: 'p5',
      method: 'Card',
      receipt: false,
    ),
    Tx(
      id: 't9',
      kind: TxKind.expense,
      cat: 'marketing',
      title: 'Social ads — June push',
      amount: 920,
      date: 'Jun 02',
      programId: 'p5',
      method: 'Card',
      receipt: true,
    ),
    Tx(
      id: 't10',
      kind: TxKind.expense,
      cat: 'equipment',
      title: 'Lab laptops (rental)',
      amount: 1340,
      date: 'Jun 01',
      programId: 'p2',
      method: 'Transfer',
      receipt: false,
    ),
    Tx(
      id: 't11',
      kind: TxKind.income,
      cat: 'grant',
      title: 'Workforce grant — Cohort 12',
      amount: 4000,
      date: 'May 30',
      programId: 'p1',
      method: 'Transfer',
      receipt: true,
    ),
    Tx(
      id: 't12',
      kind: TxKind.income,
      cat: 'tuition',
      title: 'Tuition — M. Adler',
      amount: 1200,
      date: 'May 29',
      programId: 'p1',
      method: 'Card',
      receipt: true,
    ),
    Tx(
      id: 't13',
      kind: TxKind.expense,
      cat: 'travel',
      title: 'Trainer flights — SEA',
      amount: 560,
      date: 'May 28',
      programId: 'p4',
      method: 'Card',
      receipt: true,
    ),
    Tx(
      id: 't14',
      kind: TxKind.expense,
      cat: 'catering',
      title: 'Coffee service — week 3',
      amount: 210,
      date: 'May 27',
      programId: 'p3',
      method: 'Cash',
      receipt: false,
    ),
    Tx(
      id: 't15',
      kind: TxKind.income,
      cat: 'tuition',
      title: 'Tuition — F. Costa',
      amount: 900,
      date: 'May 26',
      programId: 'p2',
      method: 'Card',
      receipt: true,
    ),
  ];

  // ── Participants ──────────────────────────────────────────────────────────
  final List<Participant> participants = const [
    Participant(
      id: 'u1',
      name: 'Amara Mensah',
      programId: 'p1',
      pay: PayStatus.paid,
      paid: 1200,
      fee: 1200,
      enrolled: 'May 02',
      hue: 262,
    ),
    Participant(
      id: 'u2',
      name: 'Mateo Adler',
      programId: 'p1',
      pay: PayStatus.paid,
      paid: 1200,
      fee: 1200,
      enrolled: 'May 03',
      hue: 192,
    ),
    Participant(
      id: 'u3',
      name: 'Yuki Tanaka',
      programId: 'p1',
      pay: PayStatus.partial,
      paid: 600,
      fee: 1200,
      enrolled: 'May 05',
      hue: 28,
    ),
    Participant(
      id: 'u4',
      name: 'Fatima Costa',
      programId: 'p2',
      pay: PayStatus.paid,
      paid: 900,
      fee: 900,
      enrolled: 'Apr 20',
      hue: 152,
    ),
    Participant(
      id: 'u5',
      name: 'Robert Silva',
      programId: 'p3',
      pay: PayStatus.pending,
      paid: 0,
      fee: 650,
      enrolled: 'May 25',
      hue: 326,
    ),
    Participant(
      id: 'u6',
      name: 'Jin Park',
      programId: 'p5',
      pay: PayStatus.partial,
      paid: 375,
      fee: 750,
      enrolled: 'Apr 28',
      hue: 218,
    ),
    Participant(
      id: 'u7',
      name: 'Nadia Rahman',
      programId: 'p2',
      pay: PayStatus.paid,
      paid: 900,
      fee: 900,
      enrolled: 'Apr 21',
      hue: 96,
    ),
    Participant(
      id: 'u8',
      name: 'Owen Brooks',
      programId: 'p5',
      pay: PayStatus.paid,
      paid: 750,
      fee: 750,
      enrolled: 'Apr 30',
      hue: 262,
    ),
    Participant(
      id: 'u9',
      name: 'Lucia Romano',
      programId: 'p1',
      pay: PayStatus.pending,
      paid: 0,
      fee: 1200,
      enrolled: 'May 09',
      hue: 192,
    ),
    Participant(
      id: 'u10',
      name: 'David Kim',
      programId: 'p3',
      pay: PayStatus.paid,
      paid: 650,
      fee: 650,
      enrolled: 'May 22',
      hue: 28,
    ),
    Participant(
      id: 'u11',
      name: 'Sofia Marin',
      programId: 'p2',
      pay: PayStatus.partial,
      paid: 450,
      fee: 900,
      enrolled: 'Apr 24',
      hue: 152,
    ),
    Participant(
      id: 'u12',
      name: 'Ethan Walsh',
      programId: 'p4',
      pay: PayStatus.pending,
      paid: 0,
      fee: 1500,
      enrolled: 'Jun 01',
      hue: 326,
    ),
  ];

  // ── Budget ────────────────────────────────────────────────────────────────
  final List<BudgetLine> budget = const [
    BudgetLine(
      cat: 'venue',
      label: 'Venue & Facilities',
      alloc: 14000,
      spent: 9400,
      hue: 262,
    ),
    BudgetLine(
      cat: 'trainer',
      label: 'Trainer Fees',
      alloc: 22000,
      spent: 16800,
      hue: 192,
    ),
    BudgetLine(
      cat: 'materials',
      label: 'Materials & Print',
      alloc: 6000,
      spent: 4120,
      hue: 28,
    ),
    BudgetLine(
      cat: 'catering',
      label: 'Catering',
      alloc: 5000,
      spent: 5380,
      hue: 152,
    ),
    BudgetLine(
      cat: 'marketing',
      label: 'Marketing',
      alloc: 7000,
      spent: 3260,
      hue: 326,
    ),
    BudgetLine(
      cat: 'equipment',
      label: 'Equipment',
      alloc: 9000,
      spent: 7640,
      hue: 218,
    ),
    BudgetLine(
      cat: 'travel',
      label: 'Travel',
      alloc: 4000,
      spent: 1280,
      hue: 96,
    ),
  ];

  // ── Receipts ──────────────────────────────────────────────────────────────
  final List<Receipt> receipts = const [
    Receipt(
      id: 'r1',
      vendor: 'Brew & Bites Catering',
      amount: 640,
      date: 'Jun 07',
      cat: 'catering',
      status: ReceiptStatus.matched,
      programId: 'p1',
    ),
    Receipt(
      id: 'r2',
      vendor: 'Denver Conference Hall',
      amount: 2200,
      date: 'Jun 05',
      cat: 'venue',
      status: ReceiptStatus.matched,
      programId: 'p2',
    ),
    Receipt(
      id: 'r3',
      vendor: 'PrintWorks Co.',
      amount: 480,
      date: 'Jun 04',
      cat: 'materials',
      status: ReceiptStatus.matched,
      programId: 'p3',
    ),
    Receipt(
      id: 'r4',
      vendor: 'MetaAds Invoice',
      amount: 920,
      date: 'Jun 02',
      cat: 'marketing',
      status: ReceiptStatus.matched,
      programId: 'p5',
    ),
    Receipt(
      id: 'r5',
      vendor: 'Uber Receipt',
      amount: 48,
      date: 'Jun 02',
      cat: 'travel',
      status: ReceiptStatus.unmatched,
      programId: null,
    ),
    Receipt(
      id: 'r6',
      vendor: 'Office Depot',
      amount: 134,
      date: 'Jun 01',
      cat: 'materials',
      status: ReceiptStatus.unmatched,
      programId: null,
    ),
    Receipt(
      id: 'r7',
      vendor: 'SkyHigh Airlines',
      amount: 560,
      date: 'May 28',
      cat: 'travel',
      status: ReceiptStatus.matched,
      programId: 'p4',
    ),
    Receipt(
      id: 'r8',
      vendor: 'Cloud Lab Rentals',
      amount: 1340,
      date: 'Jun 01',
      cat: 'equipment',
      status: ReceiptStatus.review,
      programId: 'p2',
    ),
  ];

  // ── Report series ─────────────────────────────────────────────────────────
  final List<String> months = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
  final List<double> incomeSeries = const [
    18200,
    21400,
    24800,
    31200,
    38600,
    41900,
  ];
  final List<double> expenseSeries = const [
    12400,
    15100,
    17900,
    20400,
    24800,
    26200,
  ];

  // ── Org totals (this period) ──────────────────────────────────────────────
  final double totalIncome = 113700;
  final double totalExpense = 64850;
  double get netProfit => totalIncome - totalExpense;

  final Org org = const Org(
    name: 'Northpeak Training Co.',
    period: 'This quarter · Q2 2026',
    cash: 84260,
  );

  double get totalBudget => budget.fold(0, (s, b) => s + b.alloc);
  double get totalSpent => budget.fold(0, (s, b) => s + b.spent);
  double get outstanding => participants.fold(0, (s, u) => s + u.due);

  int get budgetUsedPct => ((totalSpent / totalBudget) * 100).round();

  // ── Lookups ───────────────────────────────────────────────────────────────
  Program program(String id) => programs.firstWhere((p) => p.id == id);

  Program? programOrNull(String? id) {
    if (id == null) return null;
    for (final p in programs) {
      if (p.id == id) return p;
    }
    return null;
  }

  String catLabel(String id) {
    for (final c in expenseCats) {
      if (c.id == id) return c.label;
    }
    for (final c in incomeCats) {
      if (c.id == id) return c.label;
    }
    for (final b in budget) {
      if (b.cat == id) return b.label;
    }
    return id;
  }

  double catHue(String id) {
    for (final c in expenseCats) {
      if (c.id == id) return c.hue;
    }
    for (final c in incomeCats) {
      if (c.id == id) return c.hue;
    }
    for (final b in budget) {
      if (b.cat == id) return b.hue;
    }
    return 250;
  }
}
