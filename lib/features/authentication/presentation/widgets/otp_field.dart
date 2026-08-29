import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';

/// A row of single-character boxes for entering a verification code.
///
/// Focus advances as the user types and steps back on backspace — including
/// backspace pressed in an already-empty box, which `onChanged` alone never
/// reports.
///
/// Hold a `GlobalKey<OtpFieldState>` to call [OtpFieldState.clear] after a
/// rejected code.
class OtpField extends StatefulWidget {
  const OtpField({
    required this.length,
    super.key,
    this.onChanged,
    this.onCompleted,
    this.hasError = false,
    this.enabled = true,
  });

  final int length;

  /// Fired on every edit with the code so far — lets the parent keep a submit
  /// button disabled until all [length] boxes are filled.
  final ValueChanged<String>? onChanged;

  /// Fired once the final box is filled.
  final ValueChanged<String>? onCompleted;

  final bool hasError;
  final bool enabled;

  @override
  State<OtpField> createState() => OtpFieldState();
}

class OtpFieldState extends State<OtpField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  /// Wipes every box and returns focus to the first one.
  void clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    setState(() {});
    _focusNodes.first.requestFocus();
    widget.onChanged?.call('');
  }

  /// Drops [code] into the boxes as though it had been typed, `onCompleted`
  /// included. Used by the debug-only fill on the verification screen, where
  /// there is no SMS to read the code from yet.
  void fill(String code) {
    for (var i = 0; i < widget.length; i++) {
      _controllers[i].text = i < code.length ? code[i] : '';
    }
    setState(() {});
    _focusNodes.last.unfocus();

    final filled = _code;
    widget.onChanged?.call(filled);
    if (filled.length == widget.length) {
      widget.onCompleted?.call(filled);
    }
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});

    final code = _code;
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      _focusNodes[index].unfocus();
      widget.onCompleted?.call(code);
    }
  }

  /// Backspace in an empty box clears the previous one and moves focus there.
  /// `TextField.onChanged` never fires for this, so it is handled at the key
  /// level or the user gets stuck.
  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    if (_controllers[index].text.isNotEmpty || index == 0) {
      return KeyEventResult.ignored;
    }
    _controllers[index - 1].clear();
    _focusNodes[index - 1].requestFocus();
    setState(() {});
    widget.onChanged?.call(_code);
    return KeyEventResult.handled;
  }

  Color _borderColor(int index) {
    if (widget.hasError) return AppColors.error;
    if (_focusNodes[index].hasFocus || _controllers[index].text.isNotEmpty) {
      return AppColors.primaryGreen;
    }
    return AppColors.surfaceBorder;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        final border = OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _borderColor(index)),
        );
        return SizedBox(
          width: 50,
          height: 56,
          child: Focus(
            onKeyEvent: (node, event) => _onKey(index, event),
            onFocusChange: (_) => setState(() {}),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              enabled: widget.enabled,
              autofocus: index == 0,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 1,
              cursorColor: AppColors.primaryGreen,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: _controllers[index].text.isEmpty ? '•' : '',
                hintStyle: const TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: EdgeInsets.zero,
                border: border,
                enabledBorder: border,
                disabledBorder: border,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _borderColor(index),
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) => _onChanged(index, value),
            ),
          ),
        );
      }),
    );
  }
}
