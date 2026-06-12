import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/dashboard/data/budget_store.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_models.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_buttons.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_segmented.dart';

/// Selectable icon swatches for a new category (icon + its accent colour).
const _icons = <(IconData, Color)>[
  (Icons.restaurant, Color(0xFFF97316)),
  (Icons.local_cafe, Color(0xFF9CA3AF)),
  (Icons.directions_bus, Color(0xFF3B82F6)),
  (Icons.shopping_bag, Color(0xFFEC4899)),
  (Icons.description, Color(0xFF14B8A6)),
  (Icons.favorite, Color(0xFFEF4444)),
  (Icons.school, Color(0xFF22C55E)),
  (Icons.sports_esports, Color(0xFF8B5CF6)),
  (Icons.flight, Color(0xFF3B82F6)),
  (Icons.more_horiz, Color(0xFF9CA3AF)),
];

/// Selectable accent colours for a new category.
const _colors = <Color>[
  Color(0xFFF97316),
  Color(0xFF8B5CF6),
  Color(0xFF3B82F6),
  Color(0xFF14B8A6),
  Color(0xFFEF4444),
  Color(0xFFF59E0B),
  Color(0xFF9CA3AF),
];

const _alertOptions = <String>[
  '50% of budget',
  '80% of budget',
  '90% of budget',
  '100% of budget',
];

/// The Add-category form: kind toggle, name, icon, colour, budget & alerts.
///
/// Front-end only — Save just returns to the previous screen.
class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({required this.nav, this.presetKind, super.key});

  final TFNav nav;
  final TxKind? presetKind;

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  late TxKind _kind = widget.presetKind ?? TxKind.expense;
  final _nameCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  int _iconIdx = 0;
  int _colorIdx = 0;
  bool _limit = true;
  String _alert = '80% of budget';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  void _save() {
    BudgetStore.instance.add(
      BudgetCat(
        label: _nameCtrl.text.trim(),
        icon: _icons[_iconIdx].$1,
        color: _colors[_colorIdx],
        budget: double.tryParse(_budgetCtrl.text) ?? 0,
        spent: 0,
      ),
    );
    widget.nav.back();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final canSave = _nameCtrl.text.trim().isNotEmpty;

    return TFScreen(
      bottomPadding: 24,
      header: TFBackBar(title: 'Add Category', onBack: widget.nav.back),
      children: [
        TFSegmented<TxKind>(
          value: _kind,
          options: const [TxKind.expense, TxKind.income],
          labelOf: (k) => k == TxKind.expense ? 'Expense' : 'Income',
          onChanged: (k) => setState(() => _kind = k),
        ),
        const SizedBox(height: 20),

        // Category name.
        const _Label('Category Name'),
        const SizedBox(height: 9),
        _Field(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  onChanged: (_) => setState(() {}),
                  maxLength: 30,
                  cursorColor: c.primary,
                  style: TFText.sans(size: 14, color: c.text, letterSpacing: 0),
                  decoration: InputDecoration(
                    isDense: true,
                    counterText: '',
                    border: InputBorder.none,
                    hintText: 'e.g. Fitness, Subscriptions',
                    hintStyle: TFText.sans(size: 14, color: c.textDim),
                  ),
                ),
              ),
              Text(
                '${_nameCtrl.text.characters.length}/30',
                style: TFText.sans(size: 12, color: c.textDim),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Icon picker.
        const _Label('Choose Icon'),
        const SizedBox(height: 9),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 5,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            for (final (i, swatch) in _icons.indexed)
              GestureDetector(
                onTap: () => setState(() => _iconIdx = i),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _iconIdx == i
                        ? swatch.$2.withValues(alpha: 0.14)
                        : c.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _iconIdx == i ? swatch.$2 : c.line,
                      width: _iconIdx == i ? 2 : 1,
                    ),
                  ),
                  child: Icon(swatch.$1, size: 24, color: swatch.$2),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Colour picker.
        const _Label('Choose Color'),
        const SizedBox(height: 11),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            for (final (i, color) in _colors.indexed)
              GestureDetector(
                onTap: () => setState(() => _colorIdx = i),
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: _colorIdx == i
                        ? Border.all(color: c.text, width: 2)
                        : null,
                  ),
                  child: _colorIdx == i
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // Budget amount.
        const _Label('Budget Amount'),
        const SizedBox(height: 9),
        _Field(
          child: Row(
            children: [
              Text(r'$', style: TFText.num(size: 16, color: c.textMuted)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _budgetCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  cursorColor: c.primary,
                  style: TFText.num(size: 16, color: c.text),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: TFText.num(size: 16, color: c.textDim),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Spending limit toggle.
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Spending Limit',
                    style: TFText.sans(size: 14.5, color: c.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Get notified when you reach your limit',
                    style: TFText.sans(size: 12, color: c.textDim),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: _limit,
              activeTrackColor: c.primary,
              onChanged: (v) => setState(() => _limit = v),
            ),
          ],
        ),

        // Alert threshold (only when a limit is set).
        if (_limit) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Alert me when I reach',
                  style: TFText.sans(size: 14, color: c.textMuted),
                ),
              ),
              _Field(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _alert,
                    isDense: true,
                    dropdownColor: c.surface,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: c.textMuted,
                    ),
                    style: TFText.sans(
                      size: 13,
                      color: c.text,
                      letterSpacing: 0,
                    ),
                    items: [
                      for (final o in _alertOptions)
                        DropdownMenuItem(value: o, child: Text(o)),
                    ],
                    onChanged: (v) => setState(() => _alert = v ?? _alert),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 28),

        TFButton.primary(
          label: 'Save Category',
          icon: Icons.check,
          enabled: canSave,
          onTap: _save,
        ),
      ],
    );
  }
}

/// A small left-aligned section label.
class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TFText.sans(
          size: 12.5,
          weight: FontWeight.w700,
          color: context.tfc.textMuted,
        ),
      ),
    );
  }
}

/// A bordered input/field container matching the form style.
class _Field extends StatelessWidget {
  const _Field({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: child,
    );
  }
}
