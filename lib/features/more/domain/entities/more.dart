import 'package:equatable/equatable.dart';

/// Domain entity for the more feature.
///
/// Pure Dart — no Flutter, no Drift. Replace `name` with this feature's real
/// fields.
class More extends Equatable {
  const More({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
