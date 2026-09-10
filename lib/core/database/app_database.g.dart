// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SavingsGoalsTable extends SavingsGoals
    with TableInfo<$SavingsGoalsTable, SavingsGoalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetAmountMeta = const VerificationMeta(
    'targetAmount',
  );
  @override
  late final GeneratedColumn<double> targetAmount = GeneratedColumn<double>(
    'target_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentAmountMeta = const VerificationMeta(
    'currentAmount',
  );
  @override
  late final GeneratedColumn<double> currentAmount = GeneratedColumn<double>(
    'current_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deadlineMeta = const VerificationMeta(
    'deadline',
  );
  @override
  late final GeneratedColumn<DateTime> deadline = GeneratedColumn<DateTime>(
    'deadline',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF8E4DFF),
  );
  static const VerificationMeta _iconNameMeta = const VerificationMeta(
    'iconName',
  );
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
    'icon_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('savings'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    targetAmount,
    currentAmount,
    deadline,
    colorValue,
    iconName,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavingsGoalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_amount')) {
      context.handle(
        _targetAmountMeta,
        targetAmount.isAcceptableOrUnknown(
          data['target_amount']!,
          _targetAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetAmountMeta);
    }
    if (data.containsKey('current_amount')) {
      context.handle(
        _currentAmountMeta,
        currentAmount.isAcceptableOrUnknown(
          data['current_amount']!,
          _currentAmountMeta,
        ),
      );
    }
    if (data.containsKey('deadline')) {
      context.handle(
        _deadlineMeta,
        deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta),
      );
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    }
    if (data.containsKey('icon_name')) {
      context.handle(
        _iconNameMeta,
        iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavingsGoalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsGoalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      targetAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_amount'],
      )!,
      currentAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_amount'],
      )!,
      deadline: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deadline'],
      ),
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      iconName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SavingsGoalsTable createAlias(String alias) {
    return $SavingsGoalsTable(attachedDatabase, alias);
  }
}

class SavingsGoalRow extends DataClass implements Insertable<SavingsGoalRow> {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final int colorValue;
  final String iconName;
  final DateTime createdAt;
  const SavingsGoalRow({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.colorValue,
    required this.iconName,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['target_amount'] = Variable<double>(targetAmount);
    map['current_amount'] = Variable<double>(currentAmount);
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<DateTime>(deadline);
    }
    map['color_value'] = Variable<int>(colorValue);
    map['icon_name'] = Variable<String>(iconName);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SavingsGoalsCompanion toCompanion(bool nullToAbsent) {
    return SavingsGoalsCompanion(
      id: Value(id),
      name: Value(name),
      targetAmount: Value(targetAmount),
      currentAmount: Value(currentAmount),
      deadline: deadline == null && nullToAbsent
          ? const Value.absent()
          : Value(deadline),
      colorValue: Value(colorValue),
      iconName: Value(iconName),
      createdAt: Value(createdAt),
    );
  }

  factory SavingsGoalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsGoalRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      targetAmount: serializer.fromJson<double>(json['targetAmount']),
      currentAmount: serializer.fromJson<double>(json['currentAmount']),
      deadline: serializer.fromJson<DateTime?>(json['deadline']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      iconName: serializer.fromJson<String>(json['iconName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'targetAmount': serializer.toJson<double>(targetAmount),
      'currentAmount': serializer.toJson<double>(currentAmount),
      'deadline': serializer.toJson<DateTime?>(deadline),
      'colorValue': serializer.toJson<int>(colorValue),
      'iconName': serializer.toJson<String>(iconName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SavingsGoalRow copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    Value<DateTime?> deadline = const Value.absent(),
    int? colorValue,
    String? iconName,
    DateTime? createdAt,
  }) => SavingsGoalRow(
    id: id ?? this.id,
    name: name ?? this.name,
    targetAmount: targetAmount ?? this.targetAmount,
    currentAmount: currentAmount ?? this.currentAmount,
    deadline: deadline.present ? deadline.value : this.deadline,
    colorValue: colorValue ?? this.colorValue,
    iconName: iconName ?? this.iconName,
    createdAt: createdAt ?? this.createdAt,
  );
  SavingsGoalRow copyWithCompanion(SavingsGoalsCompanion data) {
    return SavingsGoalRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
      currentAmount: data.currentAmount.present
          ? data.currentAmount.value
          : this.currentAmount,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingsGoalRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('currentAmount: $currentAmount, ')
          ..write('deadline: $deadline, ')
          ..write('colorValue: $colorValue, ')
          ..write('iconName: $iconName, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    targetAmount,
    currentAmount,
    deadline,
    colorValue,
    iconName,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsGoalRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.targetAmount == this.targetAmount &&
          other.currentAmount == this.currentAmount &&
          other.deadline == this.deadline &&
          other.colorValue == this.colorValue &&
          other.iconName == this.iconName &&
          other.createdAt == this.createdAt);
}

class SavingsGoalsCompanion extends UpdateCompanion<SavingsGoalRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> targetAmount;
  final Value<double> currentAmount;
  final Value<DateTime?> deadline;
  final Value<int> colorValue;
  final Value<String> iconName;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SavingsGoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.currentAmount = const Value.absent(),
    this.deadline = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.iconName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavingsGoalsCompanion.insert({
    required String id,
    required String name,
    required double targetAmount,
    this.currentAmount = const Value.absent(),
    this.deadline = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.iconName = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       targetAmount = Value(targetAmount),
       createdAt = Value(createdAt);
  static Insertable<SavingsGoalRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? targetAmount,
    Expression<double>? currentAmount,
    Expression<DateTime>? deadline,
    Expression<int>? colorValue,
    Expression<String>? iconName,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (currentAmount != null) 'current_amount': currentAmount,
      if (deadline != null) 'deadline': deadline,
      if (colorValue != null) 'color_value': colorValue,
      if (iconName != null) 'icon_name': iconName,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavingsGoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double>? targetAmount,
    Value<double>? currentAmount,
    Value<DateTime?>? deadline,
    Value<int>? colorValue,
    Value<String>? iconName,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SavingsGoalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<double>(targetAmount.value);
    }
    if (currentAmount.present) {
      map['current_amount'] = Variable<double>(currentAmount.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<DateTime>(deadline.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavingsGoalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('currentAmount: $currentAmount, ')
          ..write('deadline: $deadline, ')
          ..write('colorValue: $colorValue, ')
          ..write('iconName: $iconName, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('General'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    amount,
    type,
    category,
    note,
    date,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final String id;
  final String title;
  final double amount;
  final String type;
  final String category;
  final String? note;
  final DateTime date;
  final DateTime createdAt;
  const TransactionRow({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    this.note,
    required this.date,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['amount'] = Variable<double>(amount);
    map['type'] = Variable<String>(type);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['date'] = Variable<DateTime>(date);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      title: Value(title),
      amount: Value(amount),
      type: Value(type),
      category: Value(category),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      date: Value(date),
      createdAt: Value(createdAt),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      amount: serializer.fromJson<double>(json['amount']),
      type: serializer.fromJson<String>(json['type']),
      category: serializer.fromJson<String>(json['category']),
      note: serializer.fromJson<String?>(json['note']),
      date: serializer.fromJson<DateTime>(json['date']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'amount': serializer.toJson<double>(amount),
      'type': serializer.toJson<String>(type),
      'category': serializer.toJson<String>(category),
      'note': serializer.toJson<String?>(note),
      'date': serializer.toJson<DateTime>(date),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TransactionRow copyWith({
    String? id,
    String? title,
    double? amount,
    String? type,
    String? category,
    Value<String?> note = const Value.absent(),
    DateTime? date,
    DateTime? createdAt,
  }) => TransactionRow(
    id: id ?? this.id,
    title: title ?? this.title,
    amount: amount ?? this.amount,
    type: type ?? this.type,
    category: category ?? this.category,
    note: note.present ? note.value : this.note,
    date: date ?? this.date,
    createdAt: createdAt ?? this.createdAt,
  );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      amount: data.amount.present ? data.amount.value : this.amount,
      type: data.type.present ? data.type.value : this.type,
      category: data.category.present ? data.category.value : this.category,
      note: data.note.present ? data.note.value : this.note,
      date: data.date.present ? data.date.value : this.date,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, amount, type, category, note, date, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.amount == this.amount &&
          other.type == this.type &&
          other.category == this.category &&
          other.note == this.note &&
          other.date == this.date &&
          other.createdAt == this.createdAt);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<double> amount;
  final Value<String> type;
  final Value<String> category;
  final Value<String?> note;
  final Value<DateTime> date;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.amount = const Value.absent(),
    this.type = const Value.absent(),
    this.category = const Value.absent(),
    this.note = const Value.absent(),
    this.date = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String title,
    required double amount,
    required String type,
    this.category = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime date,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       amount = Value(amount),
       type = Value(type),
       date = Value(date),
       createdAt = Value(createdAt);
  static Insertable<TransactionRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<double>? amount,
    Expression<String>? type,
    Expression<String>? category,
    Expression<String>? note,
    Expression<DateTime>? date,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (amount != null) 'amount': amount,
      if (type != null) 'type': type,
      if (category != null) 'category': category,
      if (note != null) 'note': note,
      if (date != null) 'date': date,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<double>? amount,
    Value<String>? type,
    Value<String>? category,
    Value<String?>? note,
    Value<DateTime>? date,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProgramsTable extends Programs
    with TableInfo<$ProgramsTable, ProgramRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgramsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hueMeta = const VerificationMeta('hue');
  @override
  late final GeneratedColumn<double> hue = GeneratedColumn<double>(
    'hue',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startLabelMeta = const VerificationMeta(
    'startLabel',
  );
  @override
  late final GeneratedColumn<String> startLabel = GeneratedColumn<String>(
    'start_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endLabelMeta = const VerificationMeta(
    'endLabel',
  );
  @override
  late final GeneratedColumn<String> endLabel = GeneratedColumn<String>(
    'end_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weeksMeta = const VerificationMeta('weeks');
  @override
  late final GeneratedColumn<int> weeks = GeneratedColumn<int>(
    'weeks',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trainerMeta = const VerificationMeta(
    'trainer',
  );
  @override
  late final GeneratedColumn<String> trainer = GeneratedColumn<String>(
    'trainer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capacityMeta = const VerificationMeta(
    'capacity',
  );
  @override
  late final GeneratedColumn<int> capacity = GeneratedColumn<int>(
    'capacity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enrolledMeta = const VerificationMeta(
    'enrolled',
  );
  @override
  late final GeneratedColumn<int> enrolled = GeneratedColumn<int>(
    'enrolled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feeMeta = const VerificationMeta('fee');
  @override
  late final GeneratedColumn<double> fee = GeneratedColumn<double>(
    'fee',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _budgetMeta = const VerificationMeta('budget');
  @override
  late final GeneratedColumn<double> budget = GeneratedColumn<double>(
    'budget',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _incomeMeta = const VerificationMeta('income');
  @override
  late final GeneratedColumn<double> income = GeneratedColumn<double>(
    'income',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _spentMeta = const VerificationMeta('spent');
  @override
  late final GeneratedColumn<double> spent = GeneratedColumn<double>(
    'spent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    code,
    category,
    status,
    hue,
    startLabel,
    endLabel,
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
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'programs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgramRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('hue')) {
      context.handle(
        _hueMeta,
        hue.isAcceptableOrUnknown(data['hue']!, _hueMeta),
      );
    } else if (isInserting) {
      context.missing(_hueMeta);
    }
    if (data.containsKey('start_label')) {
      context.handle(
        _startLabelMeta,
        startLabel.isAcceptableOrUnknown(data['start_label']!, _startLabelMeta),
      );
    } else if (isInserting) {
      context.missing(_startLabelMeta);
    }
    if (data.containsKey('end_label')) {
      context.handle(
        _endLabelMeta,
        endLabel.isAcceptableOrUnknown(data['end_label']!, _endLabelMeta),
      );
    } else if (isInserting) {
      context.missing(_endLabelMeta);
    }
    if (data.containsKey('weeks')) {
      context.handle(
        _weeksMeta,
        weeks.isAcceptableOrUnknown(data['weeks']!, _weeksMeta),
      );
    } else if (isInserting) {
      context.missing(_weeksMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('trainer')) {
      context.handle(
        _trainerMeta,
        trainer.isAcceptableOrUnknown(data['trainer']!, _trainerMeta),
      );
    } else if (isInserting) {
      context.missing(_trainerMeta);
    }
    if (data.containsKey('capacity')) {
      context.handle(
        _capacityMeta,
        capacity.isAcceptableOrUnknown(data['capacity']!, _capacityMeta),
      );
    } else if (isInserting) {
      context.missing(_capacityMeta);
    }
    if (data.containsKey('enrolled')) {
      context.handle(
        _enrolledMeta,
        enrolled.isAcceptableOrUnknown(data['enrolled']!, _enrolledMeta),
      );
    } else if (isInserting) {
      context.missing(_enrolledMeta);
    }
    if (data.containsKey('fee')) {
      context.handle(
        _feeMeta,
        fee.isAcceptableOrUnknown(data['fee']!, _feeMeta),
      );
    } else if (isInserting) {
      context.missing(_feeMeta);
    }
    if (data.containsKey('budget')) {
      context.handle(
        _budgetMeta,
        budget.isAcceptableOrUnknown(data['budget']!, _budgetMeta),
      );
    } else if (isInserting) {
      context.missing(_budgetMeta);
    }
    if (data.containsKey('income')) {
      context.handle(
        _incomeMeta,
        income.isAcceptableOrUnknown(data['income']!, _incomeMeta),
      );
    } else if (isInserting) {
      context.missing(_incomeMeta);
    }
    if (data.containsKey('spent')) {
      context.handle(
        _spentMeta,
        spent.isAcceptableOrUnknown(data['spent']!, _spentMeta),
      );
    } else if (isInserting) {
      context.missing(_spentMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProgramRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgramRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      hue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hue'],
      )!,
      startLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_label'],
      )!,
      endLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_label'],
      )!,
      weeks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weeks'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      trainer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trainer'],
      )!,
      capacity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}capacity'],
      )!,
      enrolled: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}enrolled'],
      )!,
      fee: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fee'],
      )!,
      budget: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}budget'],
      )!,
      income: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}income'],
      )!,
      spent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}spent'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ProgramsTable createAlias(String alias) {
    return $ProgramsTable(attachedDatabase, alias);
  }
}

class ProgramRow extends DataClass implements Insertable<ProgramRow> {
  final String id;
  final String name;
  final String code;
  final String category;
  final String status;
  final double hue;
  final String startLabel;
  final String endLabel;
  final int weeks;
  final String location;
  final String trainer;
  final int capacity;
  final int enrolled;
  final double fee;
  final double budget;
  final double income;
  final double spent;

  /// Display order on the list (mirrors the design's fixed ordering).
  final int sortOrder;
  const ProgramRow({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.status,
    required this.hue,
    required this.startLabel,
    required this.endLabel,
    required this.weeks,
    required this.location,
    required this.trainer,
    required this.capacity,
    required this.enrolled,
    required this.fee,
    required this.budget,
    required this.income,
    required this.spent,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['code'] = Variable<String>(code);
    map['category'] = Variable<String>(category);
    map['status'] = Variable<String>(status);
    map['hue'] = Variable<double>(hue);
    map['start_label'] = Variable<String>(startLabel);
    map['end_label'] = Variable<String>(endLabel);
    map['weeks'] = Variable<int>(weeks);
    map['location'] = Variable<String>(location);
    map['trainer'] = Variable<String>(trainer);
    map['capacity'] = Variable<int>(capacity);
    map['enrolled'] = Variable<int>(enrolled);
    map['fee'] = Variable<double>(fee);
    map['budget'] = Variable<double>(budget);
    map['income'] = Variable<double>(income);
    map['spent'] = Variable<double>(spent);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ProgramsCompanion toCompanion(bool nullToAbsent) {
    return ProgramsCompanion(
      id: Value(id),
      name: Value(name),
      code: Value(code),
      category: Value(category),
      status: Value(status),
      hue: Value(hue),
      startLabel: Value(startLabel),
      endLabel: Value(endLabel),
      weeks: Value(weeks),
      location: Value(location),
      trainer: Value(trainer),
      capacity: Value(capacity),
      enrolled: Value(enrolled),
      fee: Value(fee),
      budget: Value(budget),
      income: Value(income),
      spent: Value(spent),
      sortOrder: Value(sortOrder),
    );
  }

  factory ProgramRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgramRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String>(json['code']),
      category: serializer.fromJson<String>(json['category']),
      status: serializer.fromJson<String>(json['status']),
      hue: serializer.fromJson<double>(json['hue']),
      startLabel: serializer.fromJson<String>(json['startLabel']),
      endLabel: serializer.fromJson<String>(json['endLabel']),
      weeks: serializer.fromJson<int>(json['weeks']),
      location: serializer.fromJson<String>(json['location']),
      trainer: serializer.fromJson<String>(json['trainer']),
      capacity: serializer.fromJson<int>(json['capacity']),
      enrolled: serializer.fromJson<int>(json['enrolled']),
      fee: serializer.fromJson<double>(json['fee']),
      budget: serializer.fromJson<double>(json['budget']),
      income: serializer.fromJson<double>(json['income']),
      spent: serializer.fromJson<double>(json['spent']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String>(code),
      'category': serializer.toJson<String>(category),
      'status': serializer.toJson<String>(status),
      'hue': serializer.toJson<double>(hue),
      'startLabel': serializer.toJson<String>(startLabel),
      'endLabel': serializer.toJson<String>(endLabel),
      'weeks': serializer.toJson<int>(weeks),
      'location': serializer.toJson<String>(location),
      'trainer': serializer.toJson<String>(trainer),
      'capacity': serializer.toJson<int>(capacity),
      'enrolled': serializer.toJson<int>(enrolled),
      'fee': serializer.toJson<double>(fee),
      'budget': serializer.toJson<double>(budget),
      'income': serializer.toJson<double>(income),
      'spent': serializer.toJson<double>(spent),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ProgramRow copyWith({
    String? id,
    String? name,
    String? code,
    String? category,
    String? status,
    double? hue,
    String? startLabel,
    String? endLabel,
    int? weeks,
    String? location,
    String? trainer,
    int? capacity,
    int? enrolled,
    double? fee,
    double? budget,
    double? income,
    double? spent,
    int? sortOrder,
  }) => ProgramRow(
    id: id ?? this.id,
    name: name ?? this.name,
    code: code ?? this.code,
    category: category ?? this.category,
    status: status ?? this.status,
    hue: hue ?? this.hue,
    startLabel: startLabel ?? this.startLabel,
    endLabel: endLabel ?? this.endLabel,
    weeks: weeks ?? this.weeks,
    location: location ?? this.location,
    trainer: trainer ?? this.trainer,
    capacity: capacity ?? this.capacity,
    enrolled: enrolled ?? this.enrolled,
    fee: fee ?? this.fee,
    budget: budget ?? this.budget,
    income: income ?? this.income,
    spent: spent ?? this.spent,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  ProgramRow copyWithCompanion(ProgramsCompanion data) {
    return ProgramRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      category: data.category.present ? data.category.value : this.category,
      status: data.status.present ? data.status.value : this.status,
      hue: data.hue.present ? data.hue.value : this.hue,
      startLabel: data.startLabel.present
          ? data.startLabel.value
          : this.startLabel,
      endLabel: data.endLabel.present ? data.endLabel.value : this.endLabel,
      weeks: data.weeks.present ? data.weeks.value : this.weeks,
      location: data.location.present ? data.location.value : this.location,
      trainer: data.trainer.present ? data.trainer.value : this.trainer,
      capacity: data.capacity.present ? data.capacity.value : this.capacity,
      enrolled: data.enrolled.present ? data.enrolled.value : this.enrolled,
      fee: data.fee.present ? data.fee.value : this.fee,
      budget: data.budget.present ? data.budget.value : this.budget,
      income: data.income.present ? data.income.value : this.income,
      spent: data.spent.present ? data.spent.value : this.spent,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgramRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('category: $category, ')
          ..write('status: $status, ')
          ..write('hue: $hue, ')
          ..write('startLabel: $startLabel, ')
          ..write('endLabel: $endLabel, ')
          ..write('weeks: $weeks, ')
          ..write('location: $location, ')
          ..write('trainer: $trainer, ')
          ..write('capacity: $capacity, ')
          ..write('enrolled: $enrolled, ')
          ..write('fee: $fee, ')
          ..write('budget: $budget, ')
          ..write('income: $income, ')
          ..write('spent: $spent, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    code,
    category,
    status,
    hue,
    startLabel,
    endLabel,
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
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgramRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.code == this.code &&
          other.category == this.category &&
          other.status == this.status &&
          other.hue == this.hue &&
          other.startLabel == this.startLabel &&
          other.endLabel == this.endLabel &&
          other.weeks == this.weeks &&
          other.location == this.location &&
          other.trainer == this.trainer &&
          other.capacity == this.capacity &&
          other.enrolled == this.enrolled &&
          other.fee == this.fee &&
          other.budget == this.budget &&
          other.income == this.income &&
          other.spent == this.spent &&
          other.sortOrder == this.sortOrder);
}

class ProgramsCompanion extends UpdateCompanion<ProgramRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> code;
  final Value<String> category;
  final Value<String> status;
  final Value<double> hue;
  final Value<String> startLabel;
  final Value<String> endLabel;
  final Value<int> weeks;
  final Value<String> location;
  final Value<String> trainer;
  final Value<int> capacity;
  final Value<int> enrolled;
  final Value<double> fee;
  final Value<double> budget;
  final Value<double> income;
  final Value<double> spent;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const ProgramsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.category = const Value.absent(),
    this.status = const Value.absent(),
    this.hue = const Value.absent(),
    this.startLabel = const Value.absent(),
    this.endLabel = const Value.absent(),
    this.weeks = const Value.absent(),
    this.location = const Value.absent(),
    this.trainer = const Value.absent(),
    this.capacity = const Value.absent(),
    this.enrolled = const Value.absent(),
    this.fee = const Value.absent(),
    this.budget = const Value.absent(),
    this.income = const Value.absent(),
    this.spent = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgramsCompanion.insert({
    required String id,
    required String name,
    required String code,
    required String category,
    required String status,
    required double hue,
    required String startLabel,
    required String endLabel,
    required int weeks,
    required String location,
    required String trainer,
    required int capacity,
    required int enrolled,
    required double fee,
    required double budget,
    required double income,
    required double spent,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       code = Value(code),
       category = Value(category),
       status = Value(status),
       hue = Value(hue),
       startLabel = Value(startLabel),
       endLabel = Value(endLabel),
       weeks = Value(weeks),
       location = Value(location),
       trainer = Value(trainer),
       capacity = Value(capacity),
       enrolled = Value(enrolled),
       fee = Value(fee),
       budget = Value(budget),
       income = Value(income),
       spent = Value(spent);
  static Insertable<ProgramRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? code,
    Expression<String>? category,
    Expression<String>? status,
    Expression<double>? hue,
    Expression<String>? startLabel,
    Expression<String>? endLabel,
    Expression<int>? weeks,
    Expression<String>? location,
    Expression<String>? trainer,
    Expression<int>? capacity,
    Expression<int>? enrolled,
    Expression<double>? fee,
    Expression<double>? budget,
    Expression<double>? income,
    Expression<double>? spent,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
      if (hue != null) 'hue': hue,
      if (startLabel != null) 'start_label': startLabel,
      if (endLabel != null) 'end_label': endLabel,
      if (weeks != null) 'weeks': weeks,
      if (location != null) 'location': location,
      if (trainer != null) 'trainer': trainer,
      if (capacity != null) 'capacity': capacity,
      if (enrolled != null) 'enrolled': enrolled,
      if (fee != null) 'fee': fee,
      if (budget != null) 'budget': budget,
      if (income != null) 'income': income,
      if (spent != null) 'spent': spent,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgramsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? code,
    Value<String>? category,
    Value<String>? status,
    Value<double>? hue,
    Value<String>? startLabel,
    Value<String>? endLabel,
    Value<int>? weeks,
    Value<String>? location,
    Value<String>? trainer,
    Value<int>? capacity,
    Value<int>? enrolled,
    Value<double>? fee,
    Value<double>? budget,
    Value<double>? income,
    Value<double>? spent,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return ProgramsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      category: category ?? this.category,
      status: status ?? this.status,
      hue: hue ?? this.hue,
      startLabel: startLabel ?? this.startLabel,
      endLabel: endLabel ?? this.endLabel,
      weeks: weeks ?? this.weeks,
      location: location ?? this.location,
      trainer: trainer ?? this.trainer,
      capacity: capacity ?? this.capacity,
      enrolled: enrolled ?? this.enrolled,
      fee: fee ?? this.fee,
      budget: budget ?? this.budget,
      income: income ?? this.income,
      spent: spent ?? this.spent,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (hue.present) {
      map['hue'] = Variable<double>(hue.value);
    }
    if (startLabel.present) {
      map['start_label'] = Variable<String>(startLabel.value);
    }
    if (endLabel.present) {
      map['end_label'] = Variable<String>(endLabel.value);
    }
    if (weeks.present) {
      map['weeks'] = Variable<int>(weeks.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (trainer.present) {
      map['trainer'] = Variable<String>(trainer.value);
    }
    if (capacity.present) {
      map['capacity'] = Variable<int>(capacity.value);
    }
    if (enrolled.present) {
      map['enrolled'] = Variable<int>(enrolled.value);
    }
    if (fee.present) {
      map['fee'] = Variable<double>(fee.value);
    }
    if (budget.present) {
      map['budget'] = Variable<double>(budget.value);
    }
    if (income.present) {
      map['income'] = Variable<double>(income.value);
    }
    if (spent.present) {
      map['spent'] = Variable<double>(spent.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgramsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('category: $category, ')
          ..write('status: $status, ')
          ..write('hue: $hue, ')
          ..write('startLabel: $startLabel, ')
          ..write('endLabel: $endLabel, ')
          ..write('weeks: $weeks, ')
          ..write('location: $location, ')
          ..write('trainer: $trainer, ')
          ..write('capacity: $capacity, ')
          ..write('enrolled: $enrolled, ')
          ..write('fee: $fee, ')
          ..write('budget: $budget, ')
          ..write('income: $income, ')
          ..write('spent: $spent, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationsTable extends Notifications
    with TableInfo<$NotificationsTable, NotificationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<String> target = GeneratedColumn<String>(
    'target',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetParamsMeta = const VerificationMeta(
    'targetParams',
  );
  @override
  late final GeneratedColumn<String> targetParams = GeneratedColumn<String>(
    'target_params',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    title,
    body,
    receivedAt,
    isRead,
    target,
    targetParams,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('target')) {
      context.handle(
        _targetMeta,
        target.isAcceptableOrUnknown(data['target']!, _targetMeta),
      );
    }
    if (data.containsKey('target_params')) {
      context.handle(
        _targetParamsMeta,
        targetParams.isAcceptableOrUnknown(
          data['target_params']!,
          _targetParamsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target'],
      ),
      targetParams: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_params'],
      )!,
    );
  }

  @override
  $NotificationsTable createAlias(String alias) {
    return $NotificationsTable(attachedDatabase, alias);
  }
}

class NotificationRow extends DataClass implements Insertable<NotificationRow> {
  final String id;
  final String kind;
  final String title;
  final String body;
  final DateTime receivedAt;

  /// Named `isRead` because `read` reads as a verb on a database row.
  final bool isRead;
  final String? target;
  final String targetParams;
  const NotificationRow({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.isRead,
    this.target,
    required this.targetParams,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['received_at'] = Variable<DateTime>(receivedAt);
    map['is_read'] = Variable<bool>(isRead);
    if (!nullToAbsent || target != null) {
      map['target'] = Variable<String>(target);
    }
    map['target_params'] = Variable<String>(targetParams);
    return map;
  }

  NotificationsCompanion toCompanion(bool nullToAbsent) {
    return NotificationsCompanion(
      id: Value(id),
      kind: Value(kind),
      title: Value(title),
      body: Value(body),
      receivedAt: Value(receivedAt),
      isRead: Value(isRead),
      target: target == null && nullToAbsent
          ? const Value.absent()
          : Value(target),
      targetParams: Value(targetParams),
    );
  }

  factory NotificationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationRow(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      target: serializer.fromJson<String?>(json['target']),
      targetParams: serializer.fromJson<String>(json['targetParams']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'isRead': serializer.toJson<bool>(isRead),
      'target': serializer.toJson<String?>(target),
      'targetParams': serializer.toJson<String>(targetParams),
    };
  }

  NotificationRow copyWith({
    String? id,
    String? kind,
    String? title,
    String? body,
    DateTime? receivedAt,
    bool? isRead,
    Value<String?> target = const Value.absent(),
    String? targetParams,
  }) => NotificationRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    body: body ?? this.body,
    receivedAt: receivedAt ?? this.receivedAt,
    isRead: isRead ?? this.isRead,
    target: target.present ? target.value : this.target,
    targetParams: targetParams ?? this.targetParams,
  );
  NotificationRow copyWithCompanion(NotificationsCompanion data) {
    return NotificationRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      target: data.target.present ? data.target.value : this.target,
      targetParams: data.targetParams.present
          ? data.targetParams.value
          : this.targetParams,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('isRead: $isRead, ')
          ..write('target: $target, ')
          ..write('targetParams: $targetParams')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    title,
    body,
    receivedAt,
    isRead,
    target,
    targetParams,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.body == this.body &&
          other.receivedAt == this.receivedAt &&
          other.isRead == this.isRead &&
          other.target == this.target &&
          other.targetParams == this.targetParams);
}

class NotificationsCompanion extends UpdateCompanion<NotificationRow> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> title;
  final Value<String> body;
  final Value<DateTime> receivedAt;
  final Value<bool> isRead;
  final Value<String?> target;
  final Value<String> targetParams;
  final Value<int> rowid;
  const NotificationsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.isRead = const Value.absent(),
    this.target = const Value.absent(),
    this.targetParams = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationsCompanion.insert({
    required String id,
    required String kind,
    required String title,
    required String body,
    required DateTime receivedAt,
    this.isRead = const Value.absent(),
    this.target = const Value.absent(),
    this.targetParams = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       title = Value(title),
       body = Value(body),
       receivedAt = Value(receivedAt);
  static Insertable<NotificationRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? body,
    Expression<DateTime>? receivedAt,
    Expression<bool>? isRead,
    Expression<String>? target,
    Expression<String>? targetParams,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (receivedAt != null) 'received_at': receivedAt,
      if (isRead != null) 'is_read': isRead,
      if (target != null) 'target': target,
      if (targetParams != null) 'target_params': targetParams,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? title,
    Value<String>? body,
    Value<DateTime>? receivedAt,
    Value<bool>? isRead,
    Value<String?>? target,
    Value<String>? targetParams,
    Value<int>? rowid,
  }) {
    return NotificationsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      body: body ?? this.body,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
      target: target ?? this.target,
      targetParams: targetParams ?? this.targetParams,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (target.present) {
      map['target'] = Variable<String>(target.value);
    }
    if (targetParams.present) {
      map['target_params'] = Variable<String>(targetParams.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('isRead: $isRead, ')
          ..write('target: $target, ')
          ..write('targetParams: $targetParams, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SavingsGoalsTable savingsGoals = $SavingsGoalsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $ProgramsTable programs = $ProgramsTable(this);
  late final $NotificationsTable notifications = $NotificationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    savingsGoals,
    transactions,
    programs,
    notifications,
  ];
}

typedef $$SavingsGoalsTableCreateCompanionBuilder =
    SavingsGoalsCompanion Function({
      required String id,
      required String name,
      required double targetAmount,
      Value<double> currentAmount,
      Value<DateTime?> deadline,
      Value<int> colorValue,
      Value<String> iconName,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SavingsGoalsTableUpdateCompanionBuilder =
    SavingsGoalsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<double> targetAmount,
      Value<double> currentAmount,
      Value<DateTime?> deadline,
      Value<int> colorValue,
      Value<String> iconName,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$SavingsGoalsTableFilterComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentAmount => $composableBuilder(
    column: $table.currentAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavingsGoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentAmount => $composableBuilder(
    column: $table.currentAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavingsGoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentAmount => $composableBuilder(
    column: $table.currentAmount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SavingsGoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavingsGoalsTable,
          SavingsGoalRow,
          $$SavingsGoalsTableFilterComposer,
          $$SavingsGoalsTableOrderingComposer,
          $$SavingsGoalsTableAnnotationComposer,
          $$SavingsGoalsTableCreateCompanionBuilder,
          $$SavingsGoalsTableUpdateCompanionBuilder,
          (
            SavingsGoalRow,
            BaseReferences<_$AppDatabase, $SavingsGoalsTable, SavingsGoalRow>,
          ),
          SavingsGoalRow,
          PrefetchHooks Function()
        > {
  $$SavingsGoalsTableTableManager(_$AppDatabase db, $SavingsGoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> targetAmount = const Value.absent(),
                Value<double> currentAmount = const Value.absent(),
                Value<DateTime?> deadline = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<String> iconName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavingsGoalsCompanion(
                id: id,
                name: name,
                targetAmount: targetAmount,
                currentAmount: currentAmount,
                deadline: deadline,
                colorValue: colorValue,
                iconName: iconName,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required double targetAmount,
                Value<double> currentAmount = const Value.absent(),
                Value<DateTime?> deadline = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<String> iconName = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SavingsGoalsCompanion.insert(
                id: id,
                name: name,
                targetAmount: targetAmount,
                currentAmount: currentAmount,
                deadline: deadline,
                colorValue: colorValue,
                iconName: iconName,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavingsGoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavingsGoalsTable,
      SavingsGoalRow,
      $$SavingsGoalsTableFilterComposer,
      $$SavingsGoalsTableOrderingComposer,
      $$SavingsGoalsTableAnnotationComposer,
      $$SavingsGoalsTableCreateCompanionBuilder,
      $$SavingsGoalsTableUpdateCompanionBuilder,
      (
        SavingsGoalRow,
        BaseReferences<_$AppDatabase, $SavingsGoalsTable, SavingsGoalRow>,
      ),
      SavingsGoalRow,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String title,
      required double amount,
      required String type,
      Value<String> category,
      Value<String?> note,
      required DateTime date,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<double> amount,
      Value<String> type,
      Value<String> category,
      Value<String?> note,
      Value<DateTime> date,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            TransactionRow,
            BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow>,
          ),
          TransactionRow,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                title: title,
                amount: amount,
                type: type,
                category: category,
                note: note,
                date: date,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required double amount,
                required String type,
                Value<String> category = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime date,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                title: title,
                amount: amount,
                type: type,
                category: category,
                note: note,
                date: date,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        TransactionRow,
        BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow>,
      ),
      TransactionRow,
      PrefetchHooks Function()
    >;
typedef $$ProgramsTableCreateCompanionBuilder =
    ProgramsCompanion Function({
      required String id,
      required String name,
      required String code,
      required String category,
      required String status,
      required double hue,
      required String startLabel,
      required String endLabel,
      required int weeks,
      required String location,
      required String trainer,
      required int capacity,
      required int enrolled,
      required double fee,
      required double budget,
      required double income,
      required double spent,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$ProgramsTableUpdateCompanionBuilder =
    ProgramsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> code,
      Value<String> category,
      Value<String> status,
      Value<double> hue,
      Value<String> startLabel,
      Value<String> endLabel,
      Value<int> weeks,
      Value<String> location,
      Value<String> trainer,
      Value<int> capacity,
      Value<int> enrolled,
      Value<double> fee,
      Value<double> budget,
      Value<double> income,
      Value<double> spent,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$ProgramsTableFilterComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hue => $composableBuilder(
    column: $table.hue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startLabel => $composableBuilder(
    column: $table.startLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endLabel => $composableBuilder(
    column: $table.endLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weeks => $composableBuilder(
    column: $table.weeks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trainer => $composableBuilder(
    column: $table.trainer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get capacity => $composableBuilder(
    column: $table.capacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get enrolled => $composableBuilder(
    column: $table.enrolled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fee => $composableBuilder(
    column: $table.fee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get budget => $composableBuilder(
    column: $table.budget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get income => $composableBuilder(
    column: $table.income,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get spent => $composableBuilder(
    column: $table.spent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProgramsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hue => $composableBuilder(
    column: $table.hue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startLabel => $composableBuilder(
    column: $table.startLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endLabel => $composableBuilder(
    column: $table.endLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weeks => $composableBuilder(
    column: $table.weeks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trainer => $composableBuilder(
    column: $table.trainer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get capacity => $composableBuilder(
    column: $table.capacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get enrolled => $composableBuilder(
    column: $table.enrolled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fee => $composableBuilder(
    column: $table.fee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get budget => $composableBuilder(
    column: $table.budget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get income => $composableBuilder(
    column: $table.income,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get spent => $composableBuilder(
    column: $table.spent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProgramsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get hue =>
      $composableBuilder(column: $table.hue, builder: (column) => column);

  GeneratedColumn<String> get startLabel => $composableBuilder(
    column: $table.startLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endLabel =>
      $composableBuilder(column: $table.endLabel, builder: (column) => column);

  GeneratedColumn<int> get weeks =>
      $composableBuilder(column: $table.weeks, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get trainer =>
      $composableBuilder(column: $table.trainer, builder: (column) => column);

  GeneratedColumn<int> get capacity =>
      $composableBuilder(column: $table.capacity, builder: (column) => column);

  GeneratedColumn<int> get enrolled =>
      $composableBuilder(column: $table.enrolled, builder: (column) => column);

  GeneratedColumn<double> get fee =>
      $composableBuilder(column: $table.fee, builder: (column) => column);

  GeneratedColumn<double> get budget =>
      $composableBuilder(column: $table.budget, builder: (column) => column);

  GeneratedColumn<double> get income =>
      $composableBuilder(column: $table.income, builder: (column) => column);

  GeneratedColumn<double> get spent =>
      $composableBuilder(column: $table.spent, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$ProgramsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgramsTable,
          ProgramRow,
          $$ProgramsTableFilterComposer,
          $$ProgramsTableOrderingComposer,
          $$ProgramsTableAnnotationComposer,
          $$ProgramsTableCreateCompanionBuilder,
          $$ProgramsTableUpdateCompanionBuilder,
          (
            ProgramRow,
            BaseReferences<_$AppDatabase, $ProgramsTable, ProgramRow>,
          ),
          ProgramRow,
          PrefetchHooks Function()
        > {
  $$ProgramsTableTableManager(_$AppDatabase db, $ProgramsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgramsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgramsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgramsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> hue = const Value.absent(),
                Value<String> startLabel = const Value.absent(),
                Value<String> endLabel = const Value.absent(),
                Value<int> weeks = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String> trainer = const Value.absent(),
                Value<int> capacity = const Value.absent(),
                Value<int> enrolled = const Value.absent(),
                Value<double> fee = const Value.absent(),
                Value<double> budget = const Value.absent(),
                Value<double> income = const Value.absent(),
                Value<double> spent = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgramsCompanion(
                id: id,
                name: name,
                code: code,
                category: category,
                status: status,
                hue: hue,
                startLabel: startLabel,
                endLabel: endLabel,
                weeks: weeks,
                location: location,
                trainer: trainer,
                capacity: capacity,
                enrolled: enrolled,
                fee: fee,
                budget: budget,
                income: income,
                spent: spent,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String code,
                required String category,
                required String status,
                required double hue,
                required String startLabel,
                required String endLabel,
                required int weeks,
                required String location,
                required String trainer,
                required int capacity,
                required int enrolled,
                required double fee,
                required double budget,
                required double income,
                required double spent,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgramsCompanion.insert(
                id: id,
                name: name,
                code: code,
                category: category,
                status: status,
                hue: hue,
                startLabel: startLabel,
                endLabel: endLabel,
                weeks: weeks,
                location: location,
                trainer: trainer,
                capacity: capacity,
                enrolled: enrolled,
                fee: fee,
                budget: budget,
                income: income,
                spent: spent,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProgramsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgramsTable,
      ProgramRow,
      $$ProgramsTableFilterComposer,
      $$ProgramsTableOrderingComposer,
      $$ProgramsTableAnnotationComposer,
      $$ProgramsTableCreateCompanionBuilder,
      $$ProgramsTableUpdateCompanionBuilder,
      (ProgramRow, BaseReferences<_$AppDatabase, $ProgramsTable, ProgramRow>),
      ProgramRow,
      PrefetchHooks Function()
    >;
typedef $$NotificationsTableCreateCompanionBuilder =
    NotificationsCompanion Function({
      required String id,
      required String kind,
      required String title,
      required String body,
      required DateTime receivedAt,
      Value<bool> isRead,
      Value<String?> target,
      Value<String> targetParams,
      Value<int> rowid,
    });
typedef $$NotificationsTableUpdateCompanionBuilder =
    NotificationsCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> title,
      Value<String> body,
      Value<DateTime> receivedAt,
      Value<bool> isRead,
      Value<String?> target,
      Value<String> targetParams,
      Value<int> rowid,
    });

class $$NotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetParams => $composableBuilder(
    column: $table.targetParams,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetParams => $composableBuilder(
    column: $table.targetParams,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<String> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<String> get targetParams => $composableBuilder(
    column: $table.targetParams,
    builder: (column) => column,
  );
}

class $$NotificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationsTable,
          NotificationRow,
          $$NotificationsTableFilterComposer,
          $$NotificationsTableOrderingComposer,
          $$NotificationsTableAnnotationComposer,
          $$NotificationsTableCreateCompanionBuilder,
          $$NotificationsTableUpdateCompanionBuilder,
          (
            NotificationRow,
            BaseReferences<_$AppDatabase, $NotificationsTable, NotificationRow>,
          ),
          NotificationRow,
          PrefetchHooks Function()
        > {
  $$NotificationsTableTableManager(_$AppDatabase db, $NotificationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<String?> target = const Value.absent(),
                Value<String> targetParams = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationsCompanion(
                id: id,
                kind: kind,
                title: title,
                body: body,
                receivedAt: receivedAt,
                isRead: isRead,
                target: target,
                targetParams: targetParams,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String title,
                required String body,
                required DateTime receivedAt,
                Value<bool> isRead = const Value.absent(),
                Value<String?> target = const Value.absent(),
                Value<String> targetParams = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationsCompanion.insert(
                id: id,
                kind: kind,
                title: title,
                body: body,
                receivedAt: receivedAt,
                isRead: isRead,
                target: target,
                targetParams: targetParams,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationsTable,
      NotificationRow,
      $$NotificationsTableFilterComposer,
      $$NotificationsTableOrderingComposer,
      $$NotificationsTableAnnotationComposer,
      $$NotificationsTableCreateCompanionBuilder,
      $$NotificationsTableUpdateCompanionBuilder,
      (
        NotificationRow,
        BaseReferences<_$AppDatabase, $NotificationsTable, NotificationRow>,
      ),
      NotificationRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SavingsGoalsTableTableManager get savingsGoals =>
      $$SavingsGoalsTableTableManager(_db, _db.savingsGoals);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$ProgramsTableTableManager get programs =>
      $$ProgramsTableTableManager(_db, _db.programs);
  $$NotificationsTableTableManager get notifications =>
      $$NotificationsTableTableManager(_db, _db.notifications);
}
