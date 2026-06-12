import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/dashboard/data/budget_store.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_buttons.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_segmented.dart';

/// Records a transaction: feeds the home history and (for an expense) bumps
/// the chosen category's spend. Front-end only.
class AddTxPage extends StatefulWidget {
  const AddTxPage({required this.nav, this.presetCat, super.key});

  final TFNav nav;
  final String? presetCat;

  @override
  State<AddTxPage> createState() => _AddTxPageState();
}

class _AddTxPageState extends State<AddTxPage> {
  bool _isExpense = true;
  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  late String? _cat = widget.presetCat;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) return;
    final title = _titleCtrl.text.trim().isNotEmpty
        ? _titleCtrl.text.trim()
        : (_isExpense ? (_cat ?? 'Expense') : 'Income');
    final subtitle = _isExpense
        ? '${_cat ?? 'Other'} · Today'
        : 'Income · Today';
    BudgetStore.instance.addTx(
      RecentTx(
        title: title,
        subtitle: subtitle,
        amount: amount,
        isIncome: !_isExpense,
        category: _isExpense ? _cat : null,
      ),
    );
    widget.nav.back();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final cats = BudgetStore.instance.cats.value;
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final canSave = amount > 0 && (!_isExpense || _cat != null);

    return TFScreen(
      bottomPadding: 24,
      header: TFBackBar(title: 'Add Transaction', onBack: widget.nav.back),
      children: [
        TFSegmented<bool>(
          value: _isExpense,
          options: const [true, false],
          labelOf: (e) => e ? 'Expense' : 'Income',
          onChanged: (e) => setState(() => _isExpense = e),
        ),
        const SizedBox(height: 20),

        const _Label('Amount'),
        const SizedBox(height: 9),
        _Field(
          child: Row(
            children: [
              Text(r'$', style: TFText.num(size: 16, color: c.textMuted)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  onChanged: (_) => setState(() {}),
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

        const _Label('Title'),
        const SizedBox(height: 9),
        _Field(
          child: TextField(
            controller: _titleCtrl,
            cursorColor: c.primary,
            style: TFText.sans(size: 14, color: c.text, letterSpacing: 0),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'e.g. Grocery Store',
              hintStyle: TFText.sans(size: 14, color: c.textDim),
            ),
          ),
        ),

        // Category — only relevant for an expense.
        if (_isExpense) ...[
          const SizedBox(height: 20),
          const _Label('Category'),
          const SizedBox(height: 9),
          _Field(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _cat,
                isExpanded: true,
                isDense: true,
                dropdownColor: c.surface,
                hint: Text(
                  'Choose category',
                  style: TFText.sans(size: 14, color: c.textDim),
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: c.textMuted,
                ),
                style: TFText.sans(size: 14, color: c.text, letterSpacing: 0),
                items: [
                  for (final cat in cats)
                    DropdownMenuItem(value: cat.label, child: Text(cat.label)),
                ],
                onChanged: (v) => setState(() => _cat = v),
              ),
            ),
          ),
        ],
        const SizedBox(height: 28),

        TFButton.primary(
          label: _isExpense ? 'Save expense' : 'Save income',
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

/// A bordered field container matching the form style.
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
