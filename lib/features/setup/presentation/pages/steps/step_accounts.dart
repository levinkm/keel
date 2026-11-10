import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/setup/presentation/bloc/setup_cubit.dart';
import 'package:keel/features/setup/presentation/widgets/setup_form_widgets.dart';
import 'package:keel/features/setup/presentation/widgets/setup_step_shell.dart';

class StepAccounts extends StatefulWidget {
  const StepAccounts({super.key});

  @override
  State<StepAccounts> createState() => _StepAccountsState();
}

class _StepAccountsState extends State<StepAccounts> {
  final List<_AccountRow> _rows = [
    _AccountRow(name: 'Co-op Bank', type: AccountType.asset, liquidity: Liquidity.instant),
    _AccountRow(name: 'M-Pesa', type: AccountType.asset, liquidity: Liquidity.instant),
  ];

  void _addRow() => setState(() => _rows.add(_AccountRow()));
  void _removeRow(int i) => setState(() => _rows.removeAt(i));

  List<AccountDraft> get _drafts => _rows
      .where((r) => r.nameController.text.trim().isNotEmpty)
      .map((r) => AccountDraft(
            name: r.nameController.text.trim(),
            type: r.type,
            openingBalanceMinor: _parseMinor(r.balanceController.text),
            currency: 'KES',
            liquidity: r.liquidity,
          ))
      .toList();

  int _parseMinor(String s) => ((double.tryParse(s.replaceAll(',', '')) ?? 0) * 100).round();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SetupStepShell(
      title: 'Your accounts',
      subtitle: 'Add every account where money sits — banks, wallets, savings. Enter the current balance as the opening figure.',
      onBack: () => context.read<SetupCubit>().previousStep(),
      onNext: () {
        context.read<SetupCubit>().setAccounts(_drafts);
        context.read<SetupCubit>().nextStep();
      },
      isNextEnabled: _rows.any((r) => r.nameController.text.trim().isNotEmpty),
      content: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: const [
                Expanded(flex: 3, child: SetupColHeader('Account name')),
                SizedBox(width: 8),
                Expanded(flex: 2, child: SetupColHeader('Type')),
                SizedBox(width: 8),
                Expanded(flex: 2, child: SetupColHeader('Liquidity')),
                SizedBox(width: 8),
                Expanded(flex: 2, child: SetupColHeader('Opening balance (KES)')),
                SizedBox(width: 36),
              ],
            ),
          ),

          ...List.generate(_rows.length, (i) => _AccountRowWidget(
                row: _rows[i],
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
              label: const Text('Add account'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _AccountRow {
  final TextEditingController nameController;
  final TextEditingController balanceController;
  AccountType type;
  Liquidity liquidity;

  _AccountRow({
    String name = '',
    this.type = AccountType.asset,
    this.liquidity = Liquidity.instant,
  })  : nameController = TextEditingController(text: name),
        balanceController = TextEditingController();
}

class _AccountRowWidget extends StatelessWidget {
  final _AccountRow row;
  final bool isDark;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _AccountRowWidget({
    required this.row,
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
          Expanded(
            flex: 3,
            child: SetupField(controller: row.nameController, hint: 'e.g. Co-op Bank', onChanged: (_) => onChanged()),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SetupDropdown<AccountType>(
              value: row.type,
              items: const [
                (AccountType.asset, 'Asset'),
                (AccountType.liability, 'Liability'),
                (AccountType.income, 'Income'),
                (AccountType.expense, 'Expense'),
              ],
              onChanged: onChanged,
              onSelect: (v) => row.type = v,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SetupDropdown<Liquidity>(
              value: row.liquidity,
              items: const [
                (Liquidity.instant, 'Instant'),
                (Liquidity.days, 'Days'),
                (Liquidity.locked, 'Locked'),
              ],
              onChanged: onChanged,
              onSelect: (v) => row.liquidity = v,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SetupField(
              controller: row.balanceController,
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: onRemove != null
                ? IconButton(
                    icon: Icon(Icons.close, size: 16, color: AppColors.lightTextTertiary),
                    onPressed: onRemove,
                    padding: EdgeInsets.zero,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}


