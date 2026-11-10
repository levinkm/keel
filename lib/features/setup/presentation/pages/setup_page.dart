import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:keel/core/di/injector.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/setup/presentation/bloc/setup_cubit.dart';
import 'package:keel/features/setup/presentation/pages/steps/step_welcome.dart';
import 'package:keel/features/setup/presentation/pages/steps/step_accounts.dart';
import 'package:keel/features/setup/presentation/pages/steps/step_income.dart';
import 'package:keel/features/setup/presentation/pages/steps/step_assets_loans.dart';
import 'package:keel/features/setup/presentation/pages/steps/step_strategy.dart';
import 'package:keel/features/setup/presentation/pages/steps/step_preview.dart';

class SetupPage extends StatelessWidget {
  const SetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SetupCubit>(),
      child: const _SetupView(),
    );
  }
}

class _SetupView extends StatelessWidget {
  const _SetupView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SetupCubit, SetupState>(
      listenWhen: (prev, curr) => curr.step == SetupStep.done,
      listener: (context, state) => context.go('/dashboard'),
      child: Scaffold(
        body: BlocBuilder<SetupCubit, SetupState>(
          builder: (context, state) {
            return Row(
              children: [
                // Left panel — progress
                _SetupSidebar(currentStep: state.step),
                // Right panel — step content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(state.step),
                      child: _stepWidget(state.step),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _stepWidget(SetupStep step) {
    return switch (step) {
      SetupStep.welcome     => const StepWelcome(),
      SetupStep.accounts    => const StepAccounts(),
      SetupStep.income      => const StepIncome(),
      SetupStep.assetsLoans => const StepAssetsLoans(),
      SetupStep.strategy    => const StepStrategy(),
      SetupStep.preview     => const StepPreview(),
      SetupStep.done        => const SizedBox.shrink(),
    };
  }
}

// ── Sidebar ──────────────────────────────────────────────────────────────────

class _SetupSidebar extends StatelessWidget {
  final SetupStep currentStep;
  const _SetupSidebar({required this.currentStep});

  static const _steps = [
    (SetupStep.welcome,     'Welcome'),
    (SetupStep.accounts,    'Accounts'),
    (SetupStep.income,      'Income'),
    (SetupStep.assetsLoans, 'Assets & Loans'),
    (SetupStep.strategy,    'Strategy'),
    (SetupStep.preview,     'Preview'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurfaceSecondary;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: bg,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/png/logos/keel_icon_1024.png',
            width: 56, height: 56,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: 12),
          Image.asset(
            'assets/png/logos/keel_wordmark_1024.png',
            width: 80,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: 8),
          Text(
            'Set up your ledger',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 40),
          ...List.generate(_steps.length, (i) {
            final (step, label) = _steps[i];
            final isDone = currentStep.index > step.index;
            final isActive = currentStep == step;
            final isUpcoming = currentStep.index < step.index;

            return _StepIndicator(
              index: i + 1,
              label: label,
              isDone: isDone,
              isActive: isActive,
              isUpcoming: isUpcoming,
              isLast: i == _steps.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int index;
  final String label;
  final bool isDone;
  final bool isActive;
  final bool isUpcoming;
  final bool isLast;

  const _StepIndicator({
    required this.index,
    required this.label,
    required this.isDone,
    required this.isActive,
    required this.isUpcoming,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isActive
        ? AppColors.royalBlue
        : isDone
            ? (isDark ? AppColors.darkText : AppColors.lightText)
            : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.royalBlue.withValues(alpha: 0.1)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isDone
                    ? Icon(Icons.check, size: 14, color: AppColors.success)
                    : Text(
                        '$index',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? AppColors.royalBlue : textColor,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 1.5,
                height: 32,
                color: isDone
                    ? AppColors.success.withValues(alpha: 0.4)
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: textColor,
            ),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}
