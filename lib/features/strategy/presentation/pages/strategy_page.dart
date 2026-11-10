import 'package:keel/core/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/di/injector.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/strategy/domain/entities/strategy.dart';
import 'package:keel/features/strategy/presentation/bloc/strategy_cubit.dart';
import 'package:keel/features/strategy/presentation/widgets/bucket_editor.dart';
import 'package:keel/core/widgets/page_shell.dart';
import 'package:keel/core/widgets/shimmer.dart';

class StrategyPage extends StatelessWidget {
  const StrategyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageShell(
      child: BlocProvider(
        create: (_) => getIt<StrategyCubit>()..load(),
        child: const _StrategyView(),
      ),
    );
  }
}

class _StrategyView extends StatelessWidget {
  const _StrategyView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StrategyCubit, StrategyState>(
      listenWhen: (_, current) =>
          current.maybeMap(loaded: (s) => s.validationError != null, orElse: () => false),
      listener: (context, state) {
        final error = state.maybeMap(loaded: (s) => s.validationError, orElse: () => null);
        if (error == null) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ));
        context.read<StrategyCubit>().clearValidationError();
      },
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const MasterDetailShimmer(statCardCount: 0, listItemCount: 5),
          error: (msg) => Center(
              child: Text(msg, style: const TextStyle(color: AppColors.error))),
          loaded: (activeStrategy, buckets, allStrategies, expenseAccounts,
              assetAccounts, monthlyIncomeMinor, _) {
            final cubit = context.read<StrategyCubit>();
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
            final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
            final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
            final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
            final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

            return Scaffold(
              backgroundColor: bg,
              body: SizedBox.expand(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // ── Left: strategy list ──────────────────────────────────
                  SizedBox(
                    width: sidebarWidth(context),
                    child: Container(
                      color: bg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                            child: Text('Strategies',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary)),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              itemCount: allStrategies.length,
                              itemBuilder: (context, i) {
                                final s = allStrategies[i];
                                final isActive = s.id == activeStrategy.id;
                                return _StrategyTile(
                                  strategy: s,
                                  isActive: isActive,
                                  isDark: isDark,
                                  onTap: () => cubit.switchStrategy(s.id),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  VerticalDivider(
                    width: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),

                  // ── Right: active strategy detail ────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(activeStrategy.name,
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: textPrimary,
                                                letterSpacing: -0.3)),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.royalBlue
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text('Active',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.royalBlue)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(activeStrategy.tagline,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: textSecondary)),
                                  ],
                                ),
                              ),
                              // Apply to budget button
                              FilledButton.icon(
                                onPressed: cubit.applyToBudget,
                                icon: const Icon(Icons.auto_fix_high, size: 16),
                                label: const Text('Apply to budget'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.royalBlue,
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Income context
                          if (monthlyIncomeMinor > 0)
                            Text(
                              'Based on ${_fmt(monthlyIncomeMinor)} income this month',
                              style: TextStyle(
                                  fontSize: 12, color: textTertiary),
                            )
                          else
                            Text(
                              'No income recorded this period — record income to see allocation amounts.',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.warning),
                            ),
                          const SizedBox(height: 20),

                          // Allocation preview bar
                          if (buckets.isNotEmpty) ...[
                            _AllocationBar(
                                buckets: buckets,
                                incomeMinor: monthlyIncomeMinor,
                                isDark: isDark),
                            const SizedBox(height: 20),
                          ],

                          // Bucket editor
                          BucketEditor(
                            buckets: buckets,
                            strategyId: activeStrategy.id,
                            expenseAccounts: expenseAccounts,
                            assetAccounts: assetAccounts,
                            monthlyIncomeMinor: monthlyIncomeMinor,
                            onSave: cubit.saveBuckets,
                          ),
                          const SizedBox(height: 20),

                          // Apply to budget info card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 16, color: AppColors.info),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '"Apply to budget" creates or updates budget lines for the current period '
                                    'based on your bucket percentages and linked accounts. '
                                    'Only buckets with linked accounts are applied.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                        height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            );
          },
        );
      },
    );
  }

  static String _fmt(int minor) {
    final v = minor / 100;
    if (v >= 1000000) return 'KES ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'KES ${(v / 1000).toStringAsFixed(1)}K';
    return 'KES ${v.toStringAsFixed(0)}';
  }
}

// ── Strategy list tile ────────────────────────────────────────────────────────

class _StrategyTile extends StatelessWidget {
  final Strategy strategy;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _StrategyTile({
    required this.strategy,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final selectedBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: isActive ? AppColors.royalBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strategy.name,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? textPrimary : textSecondary)),
                  const SizedBox(height: 2),
                  Text(strategy.tagline,
                      style: TextStyle(fontSize: 11, color: textTertiary)),
                ],
              ),
            ),
            if (isActive)
              const Icon(Icons.check, size: 14, color: AppColors.royalBlue),
          ],
        ),
      ),
    );
  }
}

// ── Allocation bar ────────────────────────────────────────────────────────────

class _AllocationBar extends StatelessWidget {
  final List<StrategyBucket> buckets;
  final int incomeMinor;
  final bool isDark;

  const _AllocationBar({
    required this.buckets,
    required this.incomeMinor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    const colors = [
      AppColors.royalBlue,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.slateBlue,
      AppColors.info,
      Color(0xFF7B68EE),
      Color(0xFF20B2AA),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: surface, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Allocation',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary)),
          const SizedBox(height: 10),
          // Segmented bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: buckets.asMap().entries.map((e) {
                final pct = e.value.targetPct.clamp(0, 100);
                return Expanded(
                  flex: pct,
                  child: Container(
                    height: 10,
                    color: colors[e.key % colors.length],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: buckets.asMap().entries.map((e) {
              final bucket = e.value;
              final color = colors[e.key % colors.length];
              final amount = incomeMinor > 0
                  ? (incomeMinor * bucket.targetPct / 100).round()
                  : 0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(
                    '${bucket.name} ${bucket.targetPct}%'
                    '${amount > 0 ? ' · ${_fmt(amount)}' : ''}',
                    style: TextStyle(fontSize: 11, color: textTertiary),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _fmt(int minor) {
    final v = minor / 100;
    if (v >= 1000) return 'KES ${(v / 1000).toStringAsFixed(1)}K';
    return 'KES ${v.toStringAsFixed(0)}';
  }
}
