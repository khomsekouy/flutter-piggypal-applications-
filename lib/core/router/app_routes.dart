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

  /// Create-account screen.
  static const createAccount = 'create-account';
  static const createAccountPath = '/create-account';

  /// Last step of sign-up: the optional profile photo, uploaded onto the
  /// account the first screen already created. Needs a session, nothing else.
  static const profilePhoto = 'profile-photo';
  static const profilePhotoPath = '/profile-photo';

  /// Step one of phone verification: shows the number on the account and
  /// asks the server to text a code to it. Reached once the account exists
  /// (the first screen of sign-up creates it), and reads the number from the
  /// session — nothing to pass.
  static const verifyPhone = 'verify-phone';
  static const verifyPhonePath = '/verify-phone';

  /// Phone-number verification. Expects a `phone` query parameter, plus an
  /// optional `purpose` (`sign-up`, the default, or `password-reset`) that
  /// decides where a successful verification lands.
  static const verifyNumber = 'verify-number';
  static const verifyNumberPath = '/verify-number';

  /// First step of the password reset: the number to send a code to.
  static const forgotPassword = 'forgot-password';
  static const forgotPasswordPath = '/forgot-password';

  /// Last step of the password reset: the new password. Expects the verified
  /// `phone` query parameter.
  static const resetPassword = 'reset-password';
  static const resetPasswordPath = '/reset-password';

  /// Main app shell (Training Finance module). Owns its own internal nav.
  static const home = 'home';
  static const homePath = '/home';
}
