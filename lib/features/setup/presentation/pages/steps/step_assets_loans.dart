import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/loans/domain/entities/loan.dart';
import 'package:keel/features/setup/presentation/bloc/setup_cubit.dart';
import 'package:keel/features/setup/presentation/widgets/setup_form_widgets.dart';
import 'package:keel/features/setup/presentation/widgets/setup_step_shell.dart';

class StepAssetsLoans extends StatefulWidget {
  const StepAssetsLoans({super.key});

  @override
  State<StepAssetsLoans> createState() => _StepAssetsLoansState();
}

class _StepAssetsLoansState extends State<StepAssetsLoans> {
  final List<_LoanRow> _loans = [];

  void _addLoan() => setState(() => _loans.add(_LoanRow()));
  void _removeLoan(int i) => setState(() => _loans.removeAt(i));

  List<LoanDraft> get _drafts => _loans
      .where((r) => r.counterpartyController.text.trim().isNotEmpty)
      .map((r) => LoanDraft(
            counterparty: r.counterpartyController.text.trim(),
            direction: r.direction,
            principalMinor: _parseMinor(r.principalController.text),
            annualRateBp: ((double.tryParse(r.rateController.text) ?? 0) * 100).round(),
            termMonths: int.tryParse(r.termController.text) ?? 12,
            interestMethod: r.method,
            disbursementDate: r.disbursementDate,
            isSalaryDeducted: r.isSalaryDeducted,
          ))
      .toList();

  int _parseMinor(String s) =>
      ((double.tryParse(s.replaceAll(',', '')) ?? 0) * 100).round();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SetupStepShell(
      title: 'Assets & loans',
      subtitle: 'Optional — add loans you are repaying or have given out. You can skip this and add them later.',
      onBack: () => context.read<SetupCubit>().previousStep(),
      onNext: () {
        context.read<SetupCubit>().setLoans(_drafts);
        context.read<SetupCubit>().nextStep();
      },
      nextLabel: 'Continue',
      trailing: TextButton(
        onPressed: () {
          context.read<SetupCubit>().setLoans([]);
          context.read<SetupCubit>().nextStep();
        },
        child: const Text('Skip for now'),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Loans',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 12),
          if (_loans.isEmpty)
            _EmptyHint(isDark: isDark)
          else ...[
            const Row(
              children: [
                Expanded(flex: 3, child: SetupColHeader('Counterparty')),
                SizedBox(width: 8),
                Expanded(flex: 2, child: SetupColHeader('Direction')),
                SizedBox(width: 8),
                Expanded(flex: 2, child: SetupColHeader('Principal (KES)')),
                SizedBox(width: 8),
                Expanded(flex: 2, child: SetupColHeader('Rate % p.a.')),
                SizedBox(width: 8),
                Expanded(flex: 2, child: SetupColHeader('Term (months)')),
                SizedBox(width: 8),
                Expanded(flex: 2, child: SetupColHeader('Method')),
                SizedBox(width: 36),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(
              _loans.length,
              (i) => _LoanRowWidget(
                row: _loans[i],
                onRemove: () => _removeLoan(i),
                onChanged: () => setState(() {}),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _addLoan,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add loan'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _LoanRow {
  final TextEditingController counterpartyController = TextEditingController();
  final TextEditingController principalController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController termController = TextEditingController(text: '12');
  LoanDirection direction = LoanDirection.borrowed;
  InterestMethod method = InterestMethod.reducingBalance;
  DateTime disbursementDate = DateTime.now();
  bool isSalaryDeducted = false;
}

class _LoanRowWidget extends StatelessWidget {
  final _LoanRow row;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _LoanRowWidget({
    required this.row,
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
            child: SetupField(
              controller: row.counterpartyController,
              hint: 'Lender or borrower',
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SetupDropdown<LoanDirection>(
              value: row.direction,
              items: const [
                (LoanDirection.borrowed, 'I borrowed'),
                (LoanDirection.lent, 'I lent'),
              ],
              onChanged: onChanged,
              onSelect: (v) => row.direction = v,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SetupField(
              controller: row.principalController,
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SetupField(
              controller: row.rateController,
              hint: '14.0',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SetupField(
              controller: row.termController,
              hint: '12',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SetupDropdown<InterestMethod>(
              value: row.method,
              items: const [
                (InterestMethod.reducingBalance, 'Reducing'),
                (InterestMethod.flatRate, 'Flat rate'),
                (InterestMethod.fixedFee, 'Fixed fee'),
              ],
              onChanged: onChanged,
              onSelect: (v) => row.method = v,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final bool isDark;
  const _EmptyHint({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.credit_card_outlined,
            size: 18,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
          const SizedBox(width: 12),
          Text(
            'No loans added yet. Tap below to add one.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
