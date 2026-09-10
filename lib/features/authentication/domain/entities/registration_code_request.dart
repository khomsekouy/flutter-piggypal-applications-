import 'package:equatable/equatable.dart';

/// What asking for a sign-up verification code came back with.
///
/// The answer to `POST /auth/register/request-otp`, the first of the three
/// calls that make an account. A number that already has one never gets here:
/// the server refuses it with a 409 rather than spending a message on it.
///
/// The code itself is never in here in a real deployment — it goes out by SMS.
/// [devCode] is the API's own escape hatch for the fact that no SMS provider
/// is wired up yet: when the server runs with `OTP_MOCK_CODE` set, it echoes
/// the code it issued so a build can be tested at all.
class RegistrationCodeRequest extends Equatable {
  const RegistrationCodeRequest({this.expiresIn, this.devCode});

  /// How long the code stays good for — ten minutes, as the API is
  /// configured. The resend cooldown is the screen's own business and
  /// deliberately shorter. Null if the server did not say.
  final Duration? expiresIn;

  /// The issued code, echoed back only by a server with mocked codes. Null
  /// against any server that means it.
  final String? devCode;

  @override
  List<Object?> get props => [expiresIn, devCode];
}
