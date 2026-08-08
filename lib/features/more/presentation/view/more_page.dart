import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/router/app_routes.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/account/data/profile_store.dart';
import 'package:flutter_piggypal_app/features/languages/presentation/language_scope.dart';
import 'package:flutter_piggypal_app/features/languages/presentation/widgets/language_menu_button.dart';
import 'package:flutter_piggypal_app/features/notification/presentation/widgets/notification_bell.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_mock_data.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_models.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_buttons.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_rows.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_segmented.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';
import 'package:flutter_piggypal_app/l10n/l10n.dart';
import 'package:go_router/go_router.dart';

/// The "More" tab: module shortcuts, appearance tweaks, settings.
class MorePage extends StatelessWidget {
  const MorePage({required this.nav, super.key});

  final TFNav nav;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final db = TFData.instance;
    final scope = TFThemeScope.of(context);
    final theme = context.tf;

    final items = <_ModuleItem>[
      _ModuleItem(
        Icons.people_outline,
        'Participants',
        '${db.participants.length} enrolled',
        262,
        () => nav.push(TFScreens.participants),
      ),
      _ModuleItem(
        Icons.south_rounded,
        'Income',
        '${TFData.fmtK(db.totalIncome)} collected',
        152,
        () => nav.push(TFScreens.txList, {'kind': TxKind.income}),
      ),
      _ModuleItem(
        Icons.north_rounded,
        'Expenses',
        '${TFData.fmtK(db.totalExpense)} spent',
        8,
        () => nav.push(TFScreens.txList, {'kind': TxKind.expense}),
      ),
      _ModuleItem(
        Icons.track_changes,
        'Budgets',
        '${db.budgetUsedPct}% used',
        38,
        () => nav.push(TFScreens.budgets),
      ),
      _ModuleItem(
        Icons.receipt_long_outlined,
        'Receipts',
        '${db.receipts.length} this period',
        192,
        () => nav.push(TFScreens.receipts),
      ),
      _ModuleItem(
        Icons.balance,
        'Profit & Loss',
        '${TFData.fmtK(db.netProfit)} net',
        218,
        () => nav.push(TFScreens.pnl),
      ),
    ];

    return TFScreen(
      // Clears the always-visible bottom tab bar so Sign Out isn't hidden.
      bottomPadding: 120,
      header: TFAppBar(eyebrow: db.org.name, title: 'ME-INFO'),
      children: [
        // Account summary — taps through to the profile screen.
        ValueListenableBuilder<Profile>(
          valueListenable: ProfileStore.instance.profile,
          builder: (context, p, _) => TFCard(
            padding: const EdgeInsets.all(13),
            onTap: () => nav.push(TFScreens.account),
            child: Row(
              children: [
                TFAvatar(name: p.name, hue: p.hue, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p.name,
                        style: TFText.sans(
                          size: 16,
                          weight: FontWeight.w700,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TFText.sans(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: c.textMuted,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: c.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Management shortcuts, grouped into one settings-style section.
        const TFSectionLabel(title: 'Manage'),
        TFCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Column(
            children: [
              for (final (i, it) in items.indexed)
                TFRow(
                  first: i == 0,
                  onTap: it.onTap,
                  child: Row(
                    children: [
                      TFGlyphBadge(
                        size: 38,
                        radius: 12,
                        hue: it.hue,
                        child: Icon(it.icon, size: 18),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: TFRowMain(title: it.label, subtitle: it.sub),
                      ),
                      Icon(Icons.chevron_right, size: 17, color: c.textMuted),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Appearance tweaks (live re-tint of the whole module).
        const TFSectionLabel(title: 'Appearance'),
        TFCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Accent', style: TFText.sans(size: 13, color: c.textMuted)),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final accent in TFTheme.accents)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => scope.setAccent(accent),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.accent == accent
                                  ? c.text
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: theme.accent == accent
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Theme', style: TFText.sans(size: 13, color: c.textMuted)),
              const SizedBox(height: 10),
              TFSegmented<TFMode>(
                value: theme.mode,
                options: const [TFMode.dark, TFMode.light],
                labelOf: (m) => m == TFMode.dark ? 'Dark' : 'Light',
                onChanged: scope.setMode,
              ),
              const SizedBox(height: 16),
              Text('Density', style: TFText.sans(size: 13, color: c.textMuted)),
              const SizedBox(height: 10),
              TFSegmented<TFDensity>(
                value: theme.density,
                options: const [
                  TFDensity.compact,
                  TFDensity.regular,
                  TFDensity.comfortable,
                ],
                labelOf: (d) => switch (d) {
                  TFDensity.compact => 'Compact',
                  TFDensity.regular => 'Regular',
                  TFDensity.comfortable => 'Comfortable',
                },
                onChanged: scope.setDensity,
              ),
            ],
          ),
        ),

        // Language chooser (re-localizes the whole app on pick).
        TFSectionLabel(title: context.l10n.languageTitle),
        Builder(
          builder: (context) {
            final lang = LanguageScope.of(context).language;
            return TFCard(
              padding: const EdgeInsets.all(11),
              radius: 18,
              onTap: () => showLanguageSheet(context),
              child: Row(
                children: [
                  TFGlyphBadge(
                    size: 42,
                    radius: 13,
                    hue: lang.hue,
                    child: Text(
                      lang.flag,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          lang.native,
                          style: TFText.sans(
                            size: 14.5,
                            weight: FontWeight.w700,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          localizedLanguageName(context, lang),
                          style: TFText.sans(
                            size: 12.5,
                            weight: FontWeight.w500,
                            color: c.textMuted,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: c.textMuted),
                ],
              ),
            );
          },
        ),

        // Settings list.
        const TFSectionLabel(title: 'Settings'),
        TFCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (final (i, s) in <
                ({
                  String label,
                  IconData icon,
                  VoidCallback? onTap,
                  bool unreadBadge,
                })
              >[
                (
                  label: 'Organization profile',
                  icon: Icons.grid_view_rounded,
                  onTap: null,
                  unreadBadge: false,
                ),
                (
                  label: 'Team & permissions',
                  icon: Icons.people_outline,
                  onTap: null,
                  unreadBadge: false,
                ),
                (
                  label: 'Tax & currency',
                  icon: Icons.sell_outlined,
                  onTap: null,
                  unreadBadge: false,
                ),
                (
                  label: 'Notifications',
                  icon: Icons.notifications_outlined,
                  onTap: () => nav.push(TFScreens.notifications),
                  unreadBadge: true,
                ),
              ].indexed)
                TFRow(
                  first: i == 0,
                  onTap: s.onTap,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Icon(s.icon, size: 18, color: c.textMuted),
                      ),
                      const SizedBox(width: 13),
                      Expanded(child: TFRowMain(title: s.label)),
                      if (s.unreadBadge) ...[
                        const NotificationUnreadPill(),
                        const SizedBox(width: 8),
                      ],
                      Icon(Icons.chevron_right, size: 17, color: c.textMuted),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        TFButton.ghost(
          label: 'Sign Out',
          icon: Icons.logout,
          onTap: () => _confirmSignOut(context),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'Training Finance · v1.0 · ${db.org.name}',
            style: TFText.sans(
              size: 11.5,
              weight: FontWeight.w500,
              color: c.textDim,
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _confirmSignOut(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (dialogContext) => TFThemeScope(
      // The dialog mounts on the app-level overlay, above the module's own
      // scope, so re-provide the active theme.
      seed: context.tf,
      child: Builder(
        builder: (context) {
          final c = context.tfc;
          return Dialog(
            backgroundColor: c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: c.line),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sign out?',
                    style: TFText.sans(
                      size: 18,
                      weight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You'll need to sign in again to access your account.",
                    style: TFText.sans(size: 13.5, color: c.textMuted),
                  ),
                  const SizedBox(height: 22),
                  TFButton.primary(
                    label: 'Sign Out',
                    icon: Icons.logout,
                    onTap: () => Navigator.of(dialogContext).pop(true),
                  ),
                  const SizedBox(height: 10),
                  TFButton.ghost(
                    label: 'Cancel',
                    onTap: () => Navigator.of(dialogContext).pop(false),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
  if (!(ok ?? false)) return;
  if (!context.mounted) return;
  // TODO(auth): clear the persisted session before leaving.
  //
  // `goNamed`, not `nav.back()` — signing out has to leave the module
  // entirely. TFNav only pops within the shell, which would drop the user back
  // on the previous tab still signed in. `go` also replaces the route stack, so
  // hardware-back cannot re-enter the module.
  context.goNamed(AppRoutes.signIn);
}

class _ModuleItem {
  const _ModuleItem(this.icon, this.label, this.sub, this.hue, this.onTap);

  final IconData icon;
  final String label;
  final String sub;
  final double hue;
  final VoidCallback onTap;
}
