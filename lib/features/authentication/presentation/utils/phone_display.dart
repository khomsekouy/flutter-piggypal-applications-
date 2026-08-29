/// Formatting for numbers that are only ever *shown*, never sent.
///
/// The API stores and returns E.164 (`+85512345678`), which is correct and
/// unreadable. Everything the user reads goes through here; everything the
/// API receives keeps the dial code and the national part apart, as it
/// demands.
library;

/// The only dial code the app signs up, kept here so the display side does
/// not have to reach into the input field's private constants.
const _dialCode = '+855';

/// Breaks a number into readable groups: `+855 12 345 678`.
///
/// Falls back to returning the input untouched for anything that is not a
/// Cambodian mobile — a wrong grouping is worse than none, and the number
/// still has to be recognisable to whoever is checking their messages.
String formatPhoneForDisplay(String phone) {
  final trimmed = phone.trim();
  if (trimmed.isEmpty) return trimmed;

  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  final dialDigits = _dialCode.replaceAll(RegExp(r'\D'), '');
  if (!digits.startsWith(dialDigits)) return trimmed;

  final national = digits.substring(dialDigits.length);
  // 2-3-rest covers both Cambodian mobile lengths: 12 345 678 and
  // 97 123 4567.
  if (national.length < 8 || national.length > 9) {
    return '$_dialCode $national';
  }

  return '$_dialCode ${national.substring(0, 2)} '
      '${national.substring(2, 5)} ${national.substring(5)}';
}
