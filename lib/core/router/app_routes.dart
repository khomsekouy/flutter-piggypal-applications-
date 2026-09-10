/// Central list of every top-level route in the app.
///
/// Only the **app-level** flow lives here (splash → auth → home). Once the
/// user is inside `TFShell` (the `home` route), navigation between the
/// dashboard/programs/reports/etc. screens is handled by the shell's own
/// in-shell push stack (`TFNav`) — not go_router — so the bottom bar stays
/// visible with custom transitions.
///
/// Keep `path` and `name` in sync. Screens should navigate by **name**
/// (`context.goNamed(AppRoutes.signIn)`) so paths can change in one place.
abstract final class AppRoutes {
  AppRoutes._();

  /// Launch screen. Initial location.
  static const splash = 'splash';
  static const splashPath = '/';

  /// Sign-in screen.
  static const signIn = 'sign-in';
  static const signInPath = '/sign-in';

  /// Sign-up. One screen with three panes — details, the code texted to the
  /// number, then the password — which is also the order the account is built
  /// in: nothing is registered until the last of them is filled.
  static const signUp = 'sign-up';
  static const signUpPath = '/sign-up';

  /// Last step of sign-up: the optional profile photo, uploaded onto the
  /// account the previous screen created. Needs a session, nothing else.
  static const profilePhoto = 'profile-photo';
  static const profilePhotoPath = '/profile-photo';

  /// Step one of phone verification for an account that already exists and
  /// has an unverified number: shows the number on the account and asks the
  /// server to text a code to it. Reads the number from the session, so
  /// there is nothing to pass.
  ///
  /// No longer part of sign-up — that flow proves the number before the
  /// account is created (see [signUp]) — but still the way an account that
  /// skipped verification, or was made before the redesign, can catch up.
  static const verifyPhone = 'verify-phone';
  static const verifyPhonePath = '/verify-phone';

  /// Phone-number verification. Expects a `phone` query parameter, plus an
  /// optional `purpose` (`sign-up`, the default, or `password-reset`) that
  /// decides where a successful verification lands.
  ///
  /// The reset path adds `countryCode` and sends the **national** number in
  /// `phone`, because its `verify-otp` call wants the two apart; the sign-up
  /// path sends one display-ready string and no country code.
  static const verifyNumber = 'verify-number';
  static const verifyNumberPath = '/verify-number';

  /// First step of the password reset: the number to send a code to.
  static const forgotPassword = 'forgot-password';
  static const forgotPasswordPath = '/forgot-password';

  /// Last step of the password reset: the new password. Expects the verified
  /// `phone` query parameter, which is only shown, and the reset token from
  /// `verify-otp` as the route's `extra` — that is the part the call needs,
  /// and it stays out of the URL because a URL gets logged and restored.
  static const resetPassword = 'reset-password';
  static const resetPasswordPath = '/reset-password';

  /// Recovery for an account that was deleted but not yet purged. Reached
  /// from sign-in, because signing in is the one thing that will not work for
  /// an account in that state.
  static const restoreAccount = 'restore-account';
  static const restoreAccountPath = '/restore-account';

  /// Main app shell (Training Finance module). Owns its own internal nav.
  static const home = 'home';
  static const homePath = '/home';
}
