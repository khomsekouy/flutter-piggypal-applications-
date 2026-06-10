import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Result returned from [AddGoalSheet] when the user saves.
class NewGoalResult {
  const NewGoalResult({required this.name, required this.targetAmount});

  final String name;
  final double targetAmount;
}

/// Bottom sheet for creating a new savings goal.
///
/// Returns a [NewGoalResult] via `Navigator.pop`, or `null` if cancelled. The
/// sheet is intentionally dumb — it collects input and hands it back; the page
/// decides what to do with it.
class AddGoalSheet extends StatefulWidget {
  const AddGoalSheet({super.key});

  static Future<NewGoalResult?> show(BuildContext context) {
    return showModalBottomSheet<NewGoalResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddGoalSheet(),
    );
  }

  @override
  State<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      NewGoalResult(
        name: _nameController.text.trim(),
        targetAmount: double.parse(_amountController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, viewInsets + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New savings goal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'What are you saving for?',
                hintText: 'e.g. New laptop',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Give your goal a name'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Target amount',
                prefixText: r'$ ',
              ),
              validator: (value) {
                final amount = double.tryParse(value ?? '');
                if (amount == null || amount <= 0) {
                  return 'Enter an amount greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: const Text('Create goal'),
            ),
          ],
        ),
      ),
    );
  }
}
