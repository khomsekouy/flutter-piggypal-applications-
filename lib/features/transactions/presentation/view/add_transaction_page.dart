import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/theme/tf_text.dart';
import 'package:flutter_piggypal_app/core/theme/tf_theme.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_mock_data.dart';
import 'package:flutter_piggypal_app/features/training_finance/data/tf_models.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_app_bar.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_buttons.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_segmented.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/widgets/tf_widgets.dart';

/// The Add-transaction form: kind toggle, keypad amount, category & program.
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
  String _amount = '';
  String? _cat;
  String? _prog;

  void _press(String k) {
    setState(() {
      if (k == '⌫') {
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
        }
        return;
      }
      if (k == '.' && _amount.contains('.')) return;
      if (_amount.replaceAll('.', '').length >= 7) return;
      _amount = _amount == '0' ? k : _amount + k;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tfc;
    final db = TFData.instance;
    final cats = _kind == TxKind.income ? db.incomeCats : db.expenseCats;
    final canSave = _amount.isNotEmpty && _cat != null;

    return TFScreen(
      bottomPadding: 24,
      header: TFBackBar(title: 'New transaction', onBack: widget.nav.back),
      children: [
        TFSegmented<TxKind>(
          value: _kind,
          options: const [TxKind.expense, TxKind.income],
          labelOf: (k) => k == TxKind.expense ? 'Expense' : 'Income',
          onChanged: (k) => setState(() {
            _kind = k;
            _cat = null;
          }),
        ),
        const SizedBox(height: 18),

        // Amount.
        Column(
          children: [
            Text('Amount', style: TFText.sans(size: 12.5, color: c.textMuted)),
            const SizedBox(height: 4),
            Text(
              '\$${_amount.isEmpty ? '0' : _amount}',
              style: TFText.num(
                size: 46,
                letterSpacing: -2,
                color: _amount.isEmpty
                    ? c.textDim
                    : (_kind == TxKind.income ? c.pos : c.text),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Category.
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Category',
            style: TFText.sans(
              size: 12.5,
              weight: FontWeight.w700,
              color: c.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final cat in cats)
              GestureDetector(
                onTap: () => setState(() => _cat = cat.id),
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _cat == cat.id ? tfCatSoft(cat.hue) : c.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _cat == cat.id ? tfCatColor(cat.hue) : c.line,
                    ),
                  ),
                  child: Text(
                    cat.label,
                    style: TFText.sans(
                      size: 13,
                      color: _cat == cat.id ? tfCatColor(cat.hue) : c.textMuted,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),

        // Program.
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Program',
            style: TFText.sans(
              size: 12.5,
              weight: FontWeight.w700,
              color: c.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 9),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final p in db.programs.where(
                (p) => p.status != ProgramStatus.completed,
              ))
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _prog = p.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _prog == p.id ? c.primarySoft : c.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _prog == p.id ? c.primaryLine : c.line,
                        ),
                      ),
                      child: Text(
                        p.code,
                        style: TFText.sans(
                          size: 12.5,
                          color: _prog == p.id ? c.text : c.textMuted,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Meta card.
        TFCard(
          child: Column(
            children: [
              const TFDetailRow(label: 'Date', value: 'Jun 08, 2026'),
              const TFDetailRow(label: 'Payment method', value: 'Card'),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attach receipt',
                      style: TFText.sans(
                        size: 13.5,
                        weight: FontWeight.w500,
                        color: c.textMuted,
                      ),
                    ),
                    const TFPill(
                      label: 'Add',
                      tone: PillTone.primary,
                      leading: Icon(Icons.photo_camera_outlined),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Keypad.
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.3,
          children: [
            for (final k in const [
              '1',
              '2',
              '3',
              '4',
              '5',
              '6',
              '7',
              '8',
              '9',
              '.',
              '0',
              '⌫',
            ])
              GestureDetector(
                onTap: () => _press(k),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: c.line),
                  ),
                  child: Text(
                    k,
                    style: TFText.num(
                      size: 20,
                      weight: FontWeight.w600,
                      color: c.text,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        TFButton.primary(
          label: 'Save ${_kind == TxKind.income ? 'income' : 'expense'}',
          icon: Icons.check,
          enabled: canSave,
          onTap: widget.nav.back,
        ),
      ],
    );
  }
}
