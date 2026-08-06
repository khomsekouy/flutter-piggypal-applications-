/// The password rules the app enforces, in one place so sign-up and
/// password-reset cannot drift apart — a password accepted by one screen has
/// to be accepted by the other.
library;

/// Minimum characters accepted for an account password.
const minPasswordLength = 8;

/// Complaint about [password], or `null` when it passes.
///
/// An empty value is not an error: a field the user has not typed in yet
/// should not greet them in red.
String? passwordError(String password) {
  if (password.isEmpty) return null;
  if (password.length < minPasswordLength) {
    return 'Use at least $minPasswordLength characters.';
  }
  return null;
}

/// Complaint about a confirmation that does not match [password].
String? confirmPasswordError(String password, String confirmation) {
  if (confirmation.isEmpty) return null;
  if (confirmation != password) return 'Passwords do not match.';
  return null;
}

/// Whether the pair is complete and consistent enough to submit.
bool isPasswordPairValid(String password, String confirmation) =>
    password.length >= minPasswordLength && password == confirmation;
