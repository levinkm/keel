import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';

class ReconcilePanel extends StatefulWidget {
  final List<Account> accounts;
  final Map<String, int> balances;

  const ReconcilePanel({
    super.key,
    required this.accounts,
    required this.balances,
  });

  @override
  State<ReconcilePanel> createState() => _ReconcilePanelState();
}

class _ReconcilePanelState extends State<ReconcilePanel> {
  String? _selectedId;
  final _statementController = TextEditingController();

  List<Account> get _reconcilable => widget.accounts
      .where((a) => a.type == AccountType.asset || a.type == AccountType.liability)
      .toList();

  int get _ledgerBalance => widget.balances[_selectedId] ?? 0;

  int get _statementMinor =>
      ((double.tryParse(_statementController.text.replaceAll(',', '')) ?? 0) *
              100)
          .round();

  int get _difference => _statementMinor - _ledgerBalance;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (_reconcilable.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
        child: Text(
          'No asset or liability accounts to reconcile.',
          style: TextStyle(fontSize: 13, color: textSecondary),
        ),
      );
    }

    final selected = _selectedId != null
        ? _reconcilable.firstWhere((a) => a.id == _selectedId,
            orElse: () => _reconcilable.first)
        : _reconcilable.first;

    _selectedId ??= selected.id;

    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      children: [
        // Account picker
        Text('Select account',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textSecondary)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedId,
          decoration: const InputDecoration(),
          items: _reconcilable
              .map((a) => DropdownMenuItem(
                    value: a.id,
                    child: Text(a.name,
                        style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
          onChanged: (v) => setState(() {
            _selectedId = v;
            _statementController.clear();
          }),
        ),
        const SizedBox(height: 24),

        // Ledger balance
        Row(
          children: [
            Expanded(
              child: _BalanceCard(
                label: 'Ledger balance',
                amountMinor: _ledgerBalance,
                color: AppColors.royalBlue,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Statement balance',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textSecondary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _statementController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      prefixText: 'KES ',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Difference
        if (_statementController.text.isNotEmpty) ...[
          _DifferenceRow(
            difference: _difference,
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 24),
        ],

        // Instructions
        Text(
          'Enter the closing balance from your bank statement. The difference shows any unrecorded transactions or errors to investigate.',
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final int amountMinor;
  final Color color;
  final bool isDark;

  const _BalanceCard({
    required this.label,
    required this.amountMinor,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final value = amountMinor / 100;
    final formatted =
        'KES ${value.abs().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          formatted,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _DifferenceRow extends StatelessWidget {
  final int difference;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  const _DifferenceRow({
    required this.difference,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final isZero = difference == 0;
    final isPositive = difference > 0;
    final color = isZero
        ? AppColors.success
        : isPositive
            ? AppColors.warning
            : AppColors.error;
    final label = isZero
        ? 'Balanced — ledger matches statement'
        : isPositive
            ? 'Statement is KES ${_fmt(difference.abs())} higher than ledger'
            : 'Statement is KES ${_fmt(difference.abs())} lower than ledger';
    final icon = isZero
        ? Icons.check_circle_outline
        : Icons.info_outline;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(int minor) => (minor / 100)
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
