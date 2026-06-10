import 'package:equatable/equatable.dart';

/// Domain entity for the reports feature.
///
/// Pure Dart — no Flutter, no Drift. Replace `name` with this feature's real
/// fields.
class Reports extends Equatable {
  const Reports({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
