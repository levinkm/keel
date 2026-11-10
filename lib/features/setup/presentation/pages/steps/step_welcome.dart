import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/setup/presentation/bloc/setup_cubit.dart';
import 'package:keel/features/setup/presentation/widgets/setup_step_shell.dart';

class StepWelcome extends StatelessWidget {
  const StepWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SetupStepShell(
      title: 'Welcome to Keel',
      subtitle: 'Your personal ledger — every shilling tracked, every plan grounded in real numbers.',
      onNext: () => context.read<SetupCubit>().nextStep(),
      nextLabel: 'Get started',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          ..._features(isDark).map((f) => _FeatureTile(
                icon: f.$1,
                title: f.$2,
                description: f.$3,
                isDark: isDark,
              )),
          const SizedBox(height: 32),
          Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: AppColors.slateBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Everything stays on your device. No account required. Sync is optional and added later.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<(IconData, String, String)> _features(bool isDark) => [
        (Icons.menu_book_outlined, 'Double-entry ledger', 'Every transaction balances. Net worth, loan balances and cash flow fall out of the data automatically.'),
        (Icons.pie_chart_outline, 'Strategy engine', 'Choose 50/30/20, Commitments first, Kakeibo or build your own. Strategies are data, not code.'),
        (Icons.trending_up_outlined, 'Projections', 'See where you will stand in 1, 5 or 10 years — with scenarios, stress tests and assumptions shown clearly.'),
        (Icons.credit_card_outlined, 'Loan tracking', 'Real amortization schedules, prepayment what-ifs and a settlement quote on demand.'),
      ];
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.royalBlue),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
