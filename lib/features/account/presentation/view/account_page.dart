import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/account/data/profile_store.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_buttons.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_rows.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// The account overview: profile hero, personal info, and security actions.
///
/// Front-end only — reads the shared [ProfileStore] and pushes the edit /
/// change-password forms via [TFNav].
class AccountPage extends StatelessWidget {
  const AccountPage({required this.nav, super.key});

  final TFNav nav;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;

    return ValueListenableBuilder<Profile>(
      valueListenable: ProfileStore.instance.profile,
      builder: (context, p, _) {
        return TFScreen(
          header: TFBackBar(
            title: 'Account',
            onBack: nav.back,
            trailing: TFIconButton(
              icon: Icons.edit_outlined,
              onTap: () => nav.push(TFScreens.editProfile),
            ),
          ),
          children: [
            // Profile hero.
            Center(
              child: Column(
                children: [
                  TFAvatar(
                    name: p.name,
                    hue: p.hue,
                    size: 88,
                    imageUrl: p.avatarUrl,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    p.name,
                    style: TFText.sans(
                      size: 21,
                      weight: FontWeight.w700,
                      color: c.text,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  TFPill(
                    label: p.role,
                    tone: PillTone.primary,
                    leading: const Icon(Icons.verified_outlined),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.email,
                    style: TFText.sans(size: 13, color: c.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Primary actions.
            Row(
              children: [
                Expanded(
                  child: TFButton.primary(
                    label: 'Edit Profile',
                    icon: Icons.edit_outlined,
                    onTap: () => nav.push(TFScreens.editProfile),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TFButton.ghost(
                    label: 'Password',
                    icon: Icons.lock_outline,
                    onTap: () => nav.push(TFScreens.changePassword),
                  ),
                ),
              ],
            ),

            // Personal information.
            const TFSectionLabel(title: 'Personal Info'),
            TFCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    value: p.email,
                  ),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: p.phone,
                  ),
                  _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Role',
                    value: p.role,
                  ),
                  _InfoRow(
                    icon: Icons.place_outlined,
                    label: 'Location',
                    value: p.location,
                  ),
                  _InfoRow(
                    icon: Icons.event_outlined,
                    label: 'Member since',
                    value: p.joined,
                    last: true,
                  ),
                ],
              ),
            ),

            // Security actions.
            const TFSectionLabel(title: 'Security'),
            TFCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _ActionRow(
                    icon: Icons.lock_outline,
                    label: 'Change Password',
                    first: true,
                    onTap: () => nav.push(TFScreens.changePassword),
                  ),
                  _ActionRow(
                    icon: Icons.shield_outlined,
                    label: 'Two-Factor Authentication',
                    trailing: const TFPill(label: 'Off', tone: PillTone.muted),
                    onTap: () => _soon(context),
                  ),
                  _ActionRow(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => nav.push(TFScreens.notifications),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Coming soon')),
      );
  }
}

/// A read-only label-over-value row with a leading icon.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Icon(icon, size: 18, color: c.textMuted),
          ),
          const SizedBox(width: 12),
          Text(label, style: TFText.sans(size: 13.5, color: c.textMuted)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TFText.sans(size: 13.5, color: c.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable settings row: icon + label + optional trailing + chevron.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.first = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return TFRow(
      first: first,
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Icon(icon, size: 18, color: c.textMuted),
          ),
          const SizedBox(width: 13),
          Expanded(child: TFRowMain(title: label)),
          if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
          Icon(Icons.chevron_right, size: 17, color: c.textMuted),
        ],
      ),
    );
  }
}
