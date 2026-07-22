import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/account/data/profile_store.dart';
import 'package:flutter_piggypal_app/features/account/presentation/widgets/account_fields.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_buttons.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// Edit-profile form, seeded from [ProfileStore]. Saving writes back to the
/// store (which re-renders the account screen) and pops. Front-end only.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({required this.nav, super.key});

  final TFNav nav;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final Profile _initial = ProfileStore.instance.current;
  late final _nameCtrl = TextEditingController(text: _initial.name);
  late final _emailCtrl = TextEditingController(text: _initial.email);
  late final _phoneCtrl = TextEditingController(text: _initial.phone);
  late final _roleCtrl = TextEditingController(text: _initial.role);
  late final _locationCtrl = TextEditingController(text: _initial.location);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _roleCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  bool get _emailValid =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_emailCtrl.text.trim());

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty && _emailValid;

  void _save() {
    ProfileStore.instance.current = _initial.copyWith(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      role: _roleCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Profile updated')));
    widget.nav.back();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final name = _nameCtrl.text.trim();

    return TFScreen(
      // Clears the always-visible bottom tab bar so Save isn't hidden.
      bottomPadding: 120,
      header: TFBackBar(title: 'Edit Profile', onBack: widget.nav.back),
      children: [
        // Avatar preview (updates live as the name changes).
        Center(
          child: Column(
            children: [
              TFAvatar(
                name: name.isEmpty ? '?' : name,
                hue: _initial.hue,
                size: 80,
              ),
              const SizedBox(height: 10),
              Text(
                'Initials avatar',
                style: TFText.sans(size: 12, color: c.textDim),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        AccountTextField(
          label: 'Full Name',
          controller: _nameCtrl,
          hint: 'Your name',
          icon: Icons.person_outline,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        AccountTextField(
          label: 'Email',
          controller: _emailCtrl,
          hint: 'you@example.com',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          error: _emailCtrl.text.trim().isNotEmpty && !_emailValid,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        AccountTextField(
          label: 'Phone',
          controller: _phoneCtrl,
          hint: '+1 (000) 000-0000',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        AccountTextField(
          label: 'Role',
          controller: _roleCtrl,
          hint: 'e.g. Finance Manager',
          icon: Icons.badge_outlined,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        AccountTextField(
          label: 'Location',
          controller: _locationCtrl,
          hint: 'City, Country',
          icon: Icons.place_outlined,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 28),

        TFButton.primary(
          label: 'Save Changes',
          icon: Icons.check,
          enabled: _canSave,
          onTap: _save,
        ),
      ],
    );
  }
}
