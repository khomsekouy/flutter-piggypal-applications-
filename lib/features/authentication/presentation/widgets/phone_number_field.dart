import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';

/// PiggyPal signs up Cambodian numbers only, so the dial code is fixed at
/// `+855` and there is no country picker to get wrong.
const _flag = '🇰🇭';
const _dialCode = '+855';

/// Length of the *national* number — the part after `+855`, with the trunk
/// `0` dropped. Cambodian mobiles run 8 digits (e.g. 12 345 678) or 9
/// (e.g. 97 123 4567).
const _minDigits = 8;
const _maxDigits = 9;

const _lengthRule = 'Cambodian numbers are $_minDigits–$_maxDigits digits.';
const _tooLongRule = 'Cambodian numbers are at most $_maxDigits digits.';

/// Shown when the user tries to type anything that is not a digit.
const _digitsOnlyMessage = 'Numbers only — letters and symbols are ignored.';

/// Shown when the user starts with the trunk `0` they would dial locally.
/// The zero is dropped rather than rejected, so 012 345 678 still works.
const _leadingZeroMessage = 'Skip the leading 0 — $_dialCode replaces it.';

bool _isValidLength(String digits) =>
    digits.length >= _minDigits && digits.length <= _maxDigits;

class PhoneNumberField extends StatefulWidget {
  const PhoneNumberField({
    required this.controller,
    super.key,
    this.onValidChanged,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.errorText,
  });

  /// The only dial code the app accepts, exposed so callers can build the
  /// full number without hard-coding it a second time.
  static const String dialCode = _dialCode;

  final TextEditingController controller;

  /// Fired when the number starts or stops satisfying the length rule, so the
  /// parent can gate its submit button.
  final ValueChanged<bool>? onValidChanged;

  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  /// Validation message from the parent (e.g. a rejection from the server).
  /// Lowest priority — the field's own messages describe something the user
  /// just did, so they are shown first.
  final String? errorText;

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  /// Set when the last keystroke was rejected or rewritten; cleared by the
  /// next clean one, so the warning tracks what the user is doing right now.
  String? _rejectionMessage;

  bool? _lastReportedValid;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(PhoneNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    // The controller belongs to the parent — detach, never dispose.
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  String get _digits => widget.controller.text;

  void _onTextChanged() {
    setState(() {});
    _reportValidity();
  }

  void _reportValidity() {
    final isValid = _digits.isNotEmpty && _isValidLength(_digits);
    if (isValid == _lastReportedValid) return;
    _lastReportedValid = isValid;
    widget.onValidChanged?.call(isValid);
  }

  /// Length complaint. Empty input is not an error — an untouched field
  /// should not be shouting.
  String? get _lengthMessage {
    if (_digits.isEmpty) return null;
    return _isValidLength(_digits) ? null : _lengthRule;
  }

  String? get _message =>
      _rejectionMessage ?? _lengthMessage ?? widget.errorText;

  /// Strips non-digits and the trunk `0`, then caps the number at the maximum
  /// length, reporting whichever rule the keystroke ran into so the user is
  /// told *why* what they typed did not appear as typed.
  TextEditingValue _filterInput(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = FilteringTextInputFormatter.digitsOnly.formatEditUpdate(
      oldValue,
      newValue,
    );
    String? message;
    if (digits.text != newValue.text) message = _digitsOnlyMessage;

    final trimmed = _dropLeadingZeros(digits);
    if (trimmed.text != digits.text) message = _leadingZeroMessage;

    final capped = LengthLimitingTextInputFormatter(
      _maxDigits,
    ).formatEditUpdate(oldValue, trimmed);
    if (capped.text != trimmed.text) message = _tooLongRule;

    if (message != _rejectionMessage) {
      // Formatters run while handling input, never during build, so calling
      // setState from here is safe.
      setState(() => _rejectionMessage = message);
    }
    return capped;
  }

  /// Removes the trunk `0` a Cambodian number is dialled with locally. Pasted
  /// numbers can carry more than one stray zero, so this trims them all.
  TextEditingValue _dropLeadingZeros(TextEditingValue value) {
    final trimmed = value.text.replaceFirst(RegExp('^0+'), '');
    if (trimmed == value.text) return value;
    final removed = value.text.length - trimmed.length;
    final offset = (value.selection.baseOffset - removed).clamp(
      0,
      trimmed.length,
    );
    return TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  @override
  Widget build(BuildContext context) {
    final message = _message;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: message == null
                  ? AppColors.surfaceBorder
                  : AppColors.error,
              width: message == null ? 1 : 1.5,
            ),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Row(
                  children: [
                    Text(_flag, style: TextStyle(fontSize: 18)),
                    SizedBox(width: 6),
                    Text(
                      _dialCode,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 24, color: AppColors.surfaceBorder),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  textInputAction: widget.textInputAction,
                  onSubmitted: widget.onSubmitted,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    TextInputFormatter.withFunction(_filterInput),
                  ],
                  cursorColor: AppColors.primaryGreen,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(
                    filled: false,
                    hintText: '12 345 678',
                    hintStyle: TextStyle(color: AppColors.textHint),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
