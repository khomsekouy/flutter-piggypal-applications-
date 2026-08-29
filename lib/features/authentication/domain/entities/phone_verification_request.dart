import 'package:equatable/equatable.dart';

/// What asking for a verification code came back with.
///
/// The code itself is never in here in a real deployment — it goes out by SMS.
/// [devCode] is the API's own escape hatch for the fact that no SMS provider
/// is wired up yet: when the server runs with `OTP_MOCK_CODE` set, it echoes
/// the code it issued so a build can be tested at all.
class PhoneVerificationRequest extends Equatable {
  const PhoneVerificationRequest({
    required this.alreadyVerified,
    this.devCode,
  });

  /// True when the number was already verified, in which case **no code was
  /// sent** and there is nothing for the user to type.
  final bool alreadyVerified;

  /// The issued code, echoed back only by a server with mocked codes. Null
  /// against any server that means it.
  final String? devCode;

  @override
  List<Object?> get props => [alreadyVerified, devCode];
}
