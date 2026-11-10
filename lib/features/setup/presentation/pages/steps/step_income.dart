import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/features/income/domain/entities/income_stream.dart';
import 'package:keel/features/setup/presentation/bloc/setup_cubit.dart';
import 'package:keel/features/setup/presentation/widgets/setup_form_widgets.dart';
import 'package:keel/features/setup/presentation/widgets/setup_step_shell.dart';

class StepIncome extends StatefulWidget {
  const StepIncome({super.key});

  @override
  State<StepIncome> createState() => _StepIncomeState();
}

class _StepIncomeState extends State<StepIncome> {
  final List<_IncomeRow> _rows = [_IncomeRow(name: 'Salary')];

  void _addRow() => setState(() => _rows.add(_IncomeRow()));
  void _removeRow(int i) => setState(() => _rows.removeAt(i));

  List<IncomeStreamDraft> _drafts(List<AccountDraft> accounts) => _rows
      .where((r) => r.nameController.text.trim().isNotEmpty)
      .map((r) => IncomeStreamDraft(
            name: r.nameController.text.trim(),
            type: r.type,
            amountMinor: _parseMinor(r.amountController.text),
            currency: 'KES',
            frequency: r.frequency,
            depositAccountName: r.depositAccount,
          ))
      .toList();

  int _parseMinor(String s) => ((double.tryParse(s.replaceAll(',', '')) ?? 0) * 100).round();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SetupCubit>().state;
    final accountNames = state.accounts.map((a) => a.name).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SetupStepShell(
      title: 'Income streams',
      subtitle: 'Add every source of income — salary, rent, side work. Use the gross amount; deductions come later.',
      onBack: () => context.read<SetupCubit>().previousStep(),
      onNext: () {
        context.read<SetupCubit>().setIncomeStreams(_drafts(state.accounts));
        context.read<SetupCubit>().nextStep();
      },
      isNextEnabled: _rows.any((r) => r.nameController.text.trim().isNotEmpty),
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: const [
                Expanded(flex: 3, child: SetupColHeader('Name')),
                SizedBox(width: 8),
                Expanded(flex: 2, child: SetupColHeader('Type')),
                SizedBox(width: 8),
                Expanded(flex: 2, child: SetupColHeader('Frequency')),
                SizedBox(width: 8),
                Expanded(flex: 2, child: SetupColHeader('Expected amount (KES)')),
                SizedBox(width: 8),
                Expanded(flex: 2, child: SetupColHeader('Deposit account')),
                SizedBox(width: 36),
              ],
            ),
          ),
          ...List.generate(_rows.length, (i) => _IncomeRowWidget(
                row: _rows[i],
                accountNames: accountNames,
                isDark: isDark,
                onRemove: _rows.length > 1 ? () => _removeRow(i) : null,
                onChanged: () => setState(() {}),
              )),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add income stream'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _IncomeRow {
  final TextEditingController nameController;
  final TextEditingController amountController;
  IncomeType type = IncomeType.salary;
  IncomeFrequency frequency = IncomeFrequency.monthly;
  String depositAccount = '';

  _IncomeRow({String name = ''})
      : nameController = TextEditingController(text: name),
        amountController = TextEditingController();
}

class _IncomeRowWidget extends StatelessWidget {
  final _IncomeRow row;
  final List<String> accountNames;
  final bool isDark;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _IncomeRowWidget({
    required this.row,
    required this.accountNames,
    required this.isDark,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: SetupField(controller: row.nameController, hint: 'e.g. Salary', onChanged: (_) => onChanged())),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SetupDropdown<IncomeType>(
              value: row.type,
              items: const [
                (IncomeType.salary, 'Salary'),
                (IncomeType.business, 'Business'),
                (IncomeType.farming, 'Farming'),
                (IncomeType.rent, 'Rent'),
                (IncomeType.dividends, 'Dividends'),
                (IncomeType.sideWork, 'Side work'),
                (IncomeType.oneOff, 'One-off'),
              ],
              onChanged: onChanged,
              onSelect: (v) => row.type = v,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SetupDropdown<IncomeFrequency>(
              value: row.frequency,
              items: const [
                (IncomeFrequency.monthly, 'Monthly'),
                (IncomeFrequency.weekly, 'Weekly'),
                (IncomeFrequency.irregular, 'Irregular'),
              ],
              onChanged: onChanged,
              onSelect: (v) => row.frequency = v,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SetupField(
              controller: row.amountController,
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: accountNames.isEmpty
                ? SetupField(controller: TextEditingController(text: row.depositAccount), hint: 'Account name', onChanged: (v) => row.depositAccount = v)
                : SetupDropdown<String>(
                    value: accountNames.contains(row.depositAccount) ? row.depositAccount : accountNames.first,
                    items: accountNames.map((n) => (n, n)).toList(),
                    onChanged: onChanged,
                    onSelect: (v) => row.depositAccount = v,
                  ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: onRemove != null
                ? IconButton(icon: const Icon(Icons.close, size: 16), onPressed: onRemove, padding: EdgeInsets.zero)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
