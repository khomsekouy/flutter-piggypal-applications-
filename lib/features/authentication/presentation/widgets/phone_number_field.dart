import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/app_colors.dart';

class _Country {
  const _Country(this.flag, this.dialCode, this.name);
  final String flag;
  final String dialCode;
  final String name;
}

const _countries = [
  _Country('🇰🇭', '+855', 'Cambodia'),
  _Country('🇺🇸', '+1', 'United States'),
  _Country('🇨🇦', '+1', 'Canada'),
  _Country('🇬🇧', '+44', 'United Kingdom'),
  _Country('🇦🇺', '+61', 'Australia'),
  _Country('🇮🇳', '+91', 'India'),
  _Country('🇩🇪', '+49', 'Germany'),
  _Country('🇫🇷', '+33', 'France'),
  _Country('🇯🇵', '+81', 'Japan'),
  _Country('🇧🇷', '+55', 'Brazil'),
  _Country('🇿🇦', '+27', 'South Africa'),
];

class PhoneNumberField extends StatefulWidget {
  const PhoneNumberField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  _Country _selected = _countries.first;

  Future<void> _pickCountry() async {
    final country = await showModalBottomSheet<_Country>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in _countries)
              ListTile(
                leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                title: Text(
                  c.name,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                trailing: Text(
                  c.dialCode,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                onTap: () => Navigator.pop(context, c),
              ),
          ],
        ),
      ),
    );
    if (country != null) setState(() => _selected = country);
  }

  @override
  Widget build(BuildContext context) {
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
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: _pickCountry,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selected.flag,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selected.dialCode,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: AppColors.surfaceBorder),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  keyboardType: TextInputType.phone,
                  cursorColor: AppColors.primaryGreen,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(
                    filled: false,
                    hintText: '(555) 123-4567',
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
      ],
    );
  }
}
