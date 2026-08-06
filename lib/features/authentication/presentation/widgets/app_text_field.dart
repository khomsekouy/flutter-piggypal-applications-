import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.label,
    required this.controller,
    super.key,
    this.hintText,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.errorText,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;

  /// Validation message shown under the field. When non-null the border
  /// turns red, so the user is told *why* the form won't submit.
  final String? errorText;

  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _focused = false;

  Color get _borderColor {
    if (widget.errorText != null) return AppColors.error;
    return _focused ? AppColors.primaryGreen : AppColors.surfaceBorder;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (value) => setState(() => _focused = value),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _borderColor,
                width: _focused || widget.errorText != null ? 1.5 : 1,
              ),
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              textInputAction: widget.textInputAction,
              onSubmitted: widget.onSubmitted,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              cursorColor: AppColors.primaryGreen,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                filled: false,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                hintText: widget.hintText,
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: widget.prefixIcon == null
                    ? null
                    : Icon(
                        widget.prefixIcon,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                suffixIcon: widget.suffix,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        if (widget.errorText case final error?) ...[
          const SizedBox(height: 6),
          Text(
            error,
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
