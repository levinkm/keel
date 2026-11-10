import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/setup/presentation/bloc/setup_cubit.dart';
import 'package:keel/features/setup/presentation/widgets/setup_step_shell.dart';

class _Strategy {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final String suits;

  const _Strategy({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.suits,
  });
}

const _strategies = [
  _Strategy(
    id: 'commitments_first',
    name: 'Commitments first',
    tagline: 'Fixed amounts first, then weights',
    description: 'Rent and loan deducted first, then the flexible base is split by weight with 50/30/20 as a benchmark.',
    suits: 'Your current spreadsheet workflow',
  ),
  _Strategy(
    id: '50_30_20',
    name: '50/30/20',
    tagline: 'Needs · Wants · Savings',
    description: 'Take-home pay split: 50% Needs (including minimum loan payments), 30% Wants, 20% Savings.',
    suits: 'A first budget or a sanity check',
  ),
  _Strategy(
    id: '70_20_10',
    name: '70/20/10',
    tagline: 'Living · Savings · Debt',
    description: 'Living costs 70%, Savings 20%, Debt repayment or giving 10%.',
    suits: 'Higher living costs, lower savings capacity',
  ),
  _Strategy(
    id: 'pay_yourself_first',
    name: 'Pay yourself first',
    tagline: 'Save first, spend the rest',
    description: 'A fixed savings amount is taken first. The remainder is free to spend however you like.',
    suits: 'People who overspend when the plan is detailed',
  ),
  _Strategy(
    id: 'zero_based',
    name: 'Zero-based',
    tagline: 'Every shilling gets a job',
    description: 'Every shilling is assigned a category. The plan is complete only when unallocated = 0.',
    suits: 'Tight, detail-oriented control',
  ),
  _Strategy(
    id: 'envelope',
    name: 'Envelope',
    tagline: 'Monthly amounts with rollover',
    description: 'Each category has a monthly amount and a rollover balance. Overspending must be covered by moving money.',
    suits: 'Variable spending like fuel and dates',
  ),
  _Strategy(
    id: 'kakeibo',
    name: 'Kakeibo',
    tagline: 'Mindful spending',
    description: 'Save first, then spend across Survival, Optional, Culture and Extra. Month-end reflection built in.',
    suits: 'Mindful spending habits',
  ),
  _Strategy(
    id: 'custom',
    name: 'Custom',
    tagline: 'Build your own',
    description: 'Start from a blank strategy and define your own buckets, rules and benchmarks in the strategy editor.',
    suits: 'Anything else',
  ),
];

class StepStrategy extends StatelessWidget {
  const StepStrategy({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SetupCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SetupStepShell(
      title: 'Pick a strategy',
      subtitle: 'Choose how your income is allocated each month. You can change or customise this at any time.',
      onBack: () => context.read<SetupCubit>().previousStep(),
      onNext: () => context.read<SetupCubit>().nextStep(),
      content: Column(
        children: [
          ...List.generate(_strategies.length, (i) {
            final s = _strategies[i];
            final isSelected = state.strategyId == s.id;
            return _StrategyCard(
              strategy: s,
              isSelected: isSelected,
              isDark: isDark,
              onTap: () => context.read<SetupCubit>().setStrategy(s.id),
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StrategyCard extends StatelessWidget {
  final _Strategy strategy;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _StrategyCard({
    required this.strategy,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSelected
        ? AppColors.royalBlue.withValues(alpha: 0.05)
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.royalBlue : Colors.transparent,
              ),
              child: isSelected
                  ? null
                  : Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        strategy.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.royalBlue : (isDark ? AppColors.darkText : AppColors.lightText),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        strategy.tagline,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strategy.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Suits: ${strategy.suits}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
