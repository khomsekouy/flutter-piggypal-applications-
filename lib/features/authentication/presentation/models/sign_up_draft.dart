import 'package:equatable/equatable.dart';

/// What step one of sign-up collected, on its way to step two.
///
/// Travels as go_router's `extra` rather than as query parameters, because one
/// of these fields is a password and query parameters end up in logs, in the
/// browser URL bar on web, and in every deep-link history.
class SignUpDraft extends Equatable {
  const SignUpDraft({
    required this.countryCode,
    required this.phone,
    required this.password,
    required this.name,
    this.email,
  });

  /// Dialling code, e.g. `+855`.
  final String countryCode;

  /// National number only, digits — `97573235`. The API joins the two itself
  /// and rejects a number that already carries its dialling code.
  final String phone;

  final String password;
  final String name;
  final String? email;

  /// For display only — the API never sees this form.
  String get formattedPhone => '$countryCode $phone';

  @override
  List<Object?> get props => [countryCode, phone, password, name, email];
}
