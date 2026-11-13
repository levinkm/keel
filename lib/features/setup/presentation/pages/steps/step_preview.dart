import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/setup/presentation/bloc/setup_cubit.dart';
import 'package:keel/features/setup/presentation/widgets/setup_step_shell.dart';

class StepPreview extends StatelessWidget {
  const StepPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SetupCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalAssets = state.accounts
        .where((a) => a.type.name == 'asset')
        .fold(0, (sum, a) => sum + a.openingBalanceMinor);

    final totalLiabilities = state.accounts
        .where((a) => a.type.name == 'liability')
        .fold(0, (sum, a) => sum + a.openingBalanceMinor);

    final netWorth = totalAssets - totalLiabilities;

    return SetupStepShell(
      title: 'Review & confirm',
      subtitle: 'Check everything looks right before we set up your ledger.',
      onBack: () => context.read<SetupCubit>().previousStep(),
      onNext: () => context.read<SetupCubit>().finish(),
      nextLabel: 'Set up my ledger',
      isLoading: state.isSubmitting,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.error != null)
            _ErrorBanner(message: state.error!, isDark: isDark),

          // Net worth summary
          _SummaryCard(
            title: 'Starting net worth',
            isDark: isDark,
            child: Row(
              children: [
                _NetWorthFigure(label: 'Assets', amountMinor: totalAssets, isDark: isDark),
                const SizedBox(width: 32),
                _NetWorthFigure(label: 'Liabilities', amountMinor: totalLiabilities, isDark: isDark),
                const SizedBox(width: 32),
                _NetWorthFigure(label: 'Net worth', amountMinor: netWorth, isDark: isDark, isHighlight: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Accounts
          _SummaryCard(
            title: 'Accounts (${state.accounts.length})',
            isDark: isDark,
            child: Column(
              children: state.accounts.map((a) => _SummaryRow(
                    label: a.name,
                    value: '${a.type.name} · ${a.liquidity.name} · KES ${_fmt(a.openingBalanceMinor)}',
                    isDark: isDark,
                  )).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Income
          _SummaryCard(
            title: 'Income streams (${state.incomeStreams.length})',
            isDark: isDark,
            child: state.incomeStreams.isEmpty
                ? _EmptyNote('No income streams added', isDark)
                : Column(
                    children: state.incomeStreams.map((s) => _SummaryRow(
                          label: s.name,
                          value: '${s.type.name} · ${s.frequency.label} · KES ${_fmt(s.amountMinor)}',
                          isDark: isDark,
                        )).toList(),
                  ),
          ),
          const SizedBox(height: 16),

          // Loans
          _SummaryCard(
            title: 'Loans (${state.loans.length})',
            isDark: isDark,
            child: state.loans.isEmpty
                ? _EmptyNote('No loans added', isDark)
                : Column(
                    children: state.loans.map((l) => _SummaryRow(
                          label: l.counterparty,
                          value: '${l.direction.name} · KES ${_fmt(l.principalMinor)} · ${l.termMonths}m',
                          isDark: isDark,
                        )).toList(),
                  ),
          ),
          const SizedBox(height: 16),

          // Strategy
          _SummaryCard(
            title: 'Strategy',
            isDark: isDark,
            child: _SummaryRow(label: state.strategyId.replaceAll('_', ' '), value: '', isDark: isDark),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _fmt(int minor) {
    final value = minor / 100;
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;

  const _SummaryCard({required this.title, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _SummaryRow({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText)),
          ),
          Text(value, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        ],
      ),
    );
  }
}

class _NetWorthFigure extends StatelessWidget {
  final String label;
  final int amountMinor;
  final bool isDark;
  final bool isHighlight;

  const _NetWorthFigure({
    required this.label,
    required this.amountMinor,
    required this.isDark,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final value = amountMinor / 100;
    final formatted = 'KES ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)),
        const SizedBox(height: 2),
        Text(
          formatted,
          style: TextStyle(
            fontSize: isHighlight ? 18 : 15,
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
            color: isHighlight
                ? AppColors.royalBlue
                : (isDark ? AppColors.darkText : AppColors.lightText),
          ),
        ),
      ],
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final String message;
  final bool isDark;
  const _EmptyNote(this.message, this.isDark);

  @override
  Widget build(BuildContext context) => Text(
        message,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          fontStyle: FontStyle.italic,
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final bool isDark;
  const _ErrorBanner({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.errorSurfaceDark : AppColors.errorSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(fontSize: 13, color: AppColors.error))),
        ],
      ),
    );
  }
}
