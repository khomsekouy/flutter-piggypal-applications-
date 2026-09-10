import 'package:equatable/equatable.dart';

/// The short-lived proof that a number answered its code, minted by
/// `POST /auth/register/verify-otp` and spent by `POST /auth/register`.
///
/// It is **not** a session: it is signed with the API's own phone-verification
/// secret and carries `typ: phone_verified` plus the number it proved, so it
/// authenticates nothing except the one account it was issued for — and
/// registering a *different* number with it is refused, or proving any number
/// would verify every number.
///
/// Lives for ten minutes and is good for exactly one use: the verification row
/// behind it is consumed when the account is created. Nothing stores it — it
/// lives on the sign-up screen between the code pane and the password pane and
/// dies with them.
class PhoneVerificationToken extends Equatable {
  const PhoneVerificationToken({required this.token});

  /// The opaque JWT to hand back to `register`.
  final String token;

  @override
  List<Object?> get props => [token];
}
