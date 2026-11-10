import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/di/injector.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/budget/domain/entities/budget_plan.dart';
import 'package:keel/features/budget/presentation/bloc/budget_cubit.dart';
import 'package:keel/features/budget/presentation/widgets/budget_detail_panel.dart';
import 'package:keel/features/budget/presentation/widgets/budget_period_list.dart';
import 'package:keel/features/budget/presentation/widgets/new_period_dialog.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/strategy/domain/entities/strategy.dart';
import 'package:keel/features/strategy/presentation/bloc/strategy_cubit.dart';
import 'package:keel/features/strategy/presentation/widgets/bucket_editor.dart';
import 'package:keel/core/widgets/page_shell.dart';
import 'package:keel/core/widgets/shimmer.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<BudgetCubit>()..load()),
        BlocProvider(create: (_) => getIt<StrategyCubit>()..load()),
      ],
      child: const _BudgetView(),
    );
  }
}

class _BudgetView extends StatelessWidget {
  const _BudgetView();

  @override
  Widget build(BuildContext context) {
    return PageShell(
      child: BlocBuilder<BudgetCubit, BudgetState>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox.shrink(),
            loading: () => const BudgetShimmer(padTitleBar: false),
            error: (msg) => Center(
              child: Text(msg, style: const TextStyle(color: AppColors.error)),
            ),
            loaded:
                (
                  periods,
                  selectedPeriod,
                  plan,
                  actuals,
                  prevActuals,
                  expenseAccounts,
                  totalIncomeMinor,
                  templates,
                  selectedLineId,
                  sparklines,
                  activeStrategyId,
                  activeStrategyName,
                ) {
                  final cubit = context.read<BudgetCubit>();
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final divider = isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder;

                  return Row(
                    children: [
                      BudgetPeriodList(
                        periods: periods,
                        selectedPeriod: selectedPeriod,
                        planCache: {
                          for (final p in periods)
                            p: p == selectedPeriod ? plan : null,
                        },
                        onSelect: cubit.selectPeriod,
                        onNewPeriod: () =>
                            _showNewPeriodDialog(context, periods, cubit),
                      ),
                      VerticalDivider(width: 1, color: divider),
                      Expanded(
                        child: plan == null
                            ? _EmptyPlanPanel(
                                period: selectedPeriod,
                                templates: templates,
                                activeStrategyName: activeStrategyName,
                                hasIncome: totalIncomeMinor > 0,
                                onCreateBlank: () =>
                                    cubit.createBlankPlan(selectedPeriod),
                                onCopyPrevious: () =>
                                    cubit.copyFromPrevious(selectedPeriod),
                                onApplyTemplate: (t) =>
                                    cubit.applyTemplate(t, selectedPeriod),
                                onApplyStrategy: () =>
                                    cubit.applyActiveStrategy(selectedPeriod),
                                onEditStrategy: () =>
                                    _showStrategyDialog(context, isDark),
                              )
                            : BudgetDetailPanel(
                                period: selectedPeriod,
                                plan: plan,
                                actuals: actuals,
                                prevActuals: prevActuals,
                                expenseAccounts: expenseAccounts,
                                totalIncomeMinor: totalIncomeMinor,
                                templates: templates,
                                sparklines: sparklines,
                                selectedLineId: selectedLineId,
                                activeStrategyName: activeStrategyName,
                                onSelectLine: cubit.selectLine,
                                onUpsertLine: cubit.upsertLine,
                                onDeleteLine: cubit.deleteLine,
                                onQuickSpend: cubit.quickSpend,
                                onApplyRollover: () =>
                                    cubit.applyRollover(selectedPeriod),
                                onSaveAsTemplate: (name) =>
                                    cubit.saveAsTemplate(name),
                                onApplyStrategy: (ratios) =>
                                    cubit.applyStrategyAllocation(
                                      ratios,
                                      totalIncomeMinor,
                                    ),
                                onEditStrategy: () =>
                                    _showStrategyDialog(context, isDark),
                              ),
                      ),
                    ],
                  );
                },
          );
        },
      ),
    );
  }

  void _showNewPeriodDialog(
    BuildContext context,
    List<String> periods,
    BudgetCubit cubit,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => NewPeriodDialog(
        existingPeriods: periods,
        onCreate: (period, copyPrevious) {
          if (copyPrevious) {
            cubit.copyFromPrevious(period);
          } else {
            cubit.createBlankPlan(period);
          }
        },
      ),
    );
  }

  void _showStrategyDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<StrategyCubit>(),
        child: _StrategyDialog(isDark: isDark),
      ),
    );
  }
}

// ── Strategy dialog (2-step) ──────────────────────────────────────────────────

class _StrategyDialog extends StatefulWidget {
  final bool isDark;
  const _StrategyDialog({required this.isDark});

  @override
  State<_StrategyDialog> createState() => _StrategyDialogState();
}

class _StrategyDialogState extends State<_StrategyDialog> {
  int _step = 0;
  List<StrategyBucket> _previewBuckets = [];

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textTertiary = isDark
        ? AppColors.darkTextTertiary
        : AppColors.lightTextTertiary;
    final selectedBg = isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.lightSurfaceSecondary;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return BlocBuilder<StrategyCubit, StrategyState>(
      builder: (context, state) {
        return state.maybeWhen(
          loaded:
              (
                activeStrategy,
                buckets,
                allStrategies,
                expenseAccounts,
                assetAccounts,
                monthlyIncomeMinor,
                _,
              ) {
                final cubit = context.read<StrategyCubit>();
                final allAccounts = <Account>[
                  ...expenseAccounts,
                  ...assetAccounts,
                ];

                return Dialog(
                  backgroundColor: surface,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    width: 720,
                    height: 560,
                    child: Row(
                      children: [
                        // ── Left: strategy picker ──────────────────────────────
                        SizedBox(
                          width: 220,
                          child: Container(
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    20,
                                    16,
                                    4,
                                  ),
                                  child: Text(
                                    'Strategy',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                // Step indicator
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    12,
                                  ),
                                  child: Row(
                                    children: [
                                      _StepDot(active: _step == 0, label: '1'),
                                      Container(
                                        width: 16,
                                        height: 1,
                                        color: dividerColor,
                                      ),
                                      _StepDot(active: _step == 1, label: '2'),
                                      const SizedBox(width: 6),
                                      Text(
                                        _step == 0 ? 'Configure' : 'Preview',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    children: allStrategies.map((s) {
                                      final isActive =
                                          s.id == activeStrategy.id;
                                      return GestureDetector(
                                        onTap: _step == 0
                                            ? () {
                                                cubit.switchStrategy(s.id);
                                                setState(
                                                  () => _previewBuckets = [],
                                                );
                                              }
                                            : null,
                                        child: Opacity(
                                          opacity: _step == 1 ? 0.5 : 1.0,
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 2,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? selectedBg
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 3,
                                                  height: 28,
                                                  decoration: BoxDecoration(
                                                    color: isActive
                                                        ? AppColors.royalBlue
                                                        : Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          2,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        s.name,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: isActive
                                                              ? FontWeight.w600
                                                              : FontWeight.w400,
                                                          color: isActive
                                                              ? textPrimary
                                                              : textSecondary,
                                                        ),
                                                      ),
                                                      Text(
                                                        s.tagline,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: textTertiary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (isActive)
                                                  const Icon(
                                                    Icons.check,
                                                    size: 12,
                                                    color: AppColors.royalBlue,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        VerticalDivider(width: 1, color: dividerColor),

                        // ── Right: step content ────────────────────────────────
                        Expanded(
                          child: Column(
                            children: [
                              // Header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  20,
                                  20,
                                  0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _step == 0
                                                ? activeStrategy.name
                                                : 'Preview allocation',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: textPrimary,
                                            ),
                                          ),
                                          Text(
                                            _step == 0
                                                ? activeStrategy.tagline
                                                : '${_linkedLines(_previewBuckets)} lines will be created',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Icon(
                                        Icons.close,
                                        size: 18,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Body
                              Expanded(
                                child: _step == 0
                                    ? SingleChildScrollView(
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          0,
                                          20,
                                          20,
                                        ),
                                        child: BucketEditor(
                                          key: ValueKey(activeStrategy.id),
                                          buckets: buckets,
                                          strategyId: activeStrategy.id,
                                          expenseAccounts: expenseAccounts,
                                          assetAccounts: assetAccounts,
                                          monthlyIncomeMinor:
                                              monthlyIncomeMinor,
                                          onSave: cubit.saveBuckets,
                                          onPreview: (drafted) {
                                            cubit.saveBuckets(drafted);
                                            setState(() {
                                              _previewBuckets = drafted;
                                              _step = 1;
                                            });
                                          },
                                        ),
                                      )
                                    : _PreviewStep(
                                        buckets: _previewBuckets,
                                        allAccounts: allAccounts,
                                        monthlyIncomeMinor: monthlyIncomeMinor,
                                        isDark: isDark,
                                        onBack: () => setState(() => _step = 0),
                                        onApply: () {
                                          cubit.applyToBudget();
                                          Navigator.of(context).pop();
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
          orElse: () => const BudgetShimmer(padTitleBar: false),
        );
      },
    );
  }

  int _linkedLines(List<StrategyBucket> buckets) =>
      buckets.fold(0, (s, b) => s + b.accountIds.length);
}

// ── Step dot indicator ────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final bool active;
  final String label;
  const _StepDot({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: active ? AppColors.royalBlue : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: active
              ? AppColors.royalBlue
              : AppColors.royalBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: active
                ? Colors.white
                : AppColors.royalBlue.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

// ── Step 2: preview & confirm ─────────────────────────────────────────────────

class _PreviewStep extends StatelessWidget {
  final List<StrategyBucket> buckets;
  final List<Account> allAccounts;
  final int monthlyIncomeMinor;
  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback onApply;

  const _PreviewStep({
    required this.buckets,
    required this.allAccounts,
    required this.monthlyIncomeMinor,
    required this.isDark,
    required this.onBack,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.lightSurfaceSecondary;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textTertiary = isDark
        ? AppColors.darkTextTertiary
        : AppColors.lightTextTertiary;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    // Build rows using resolvedWeights — unlinked buckets shown as warning rows
    final rows =
        <({String bucket, String account, int amountMinor, bool unlinked})>[];
    for (final b in buckets) {
      final bucketAmount = (monthlyIncomeMinor * b.targetPct / 100).round();
      if (b.accountIds.isEmpty) {
        rows.add((
          bucket: b.name,
          account: '',
          amountMinor: bucketAmount,
          unlinked: true,
        ));
        continue;
      }
      final weights = b.resolvedWeights();
      int distributed = 0;
      for (int i = 0; i < b.accountIds.length; i++) {
        final id = b.accountIds[i];
        final acct = allAccounts.cast<Account?>().firstWhere(
          (a) => a?.id == id,
          orElse: () => null,
        );
        if (acct == null) continue;
        final isLast = i == b.accountIds.length - 1;
        final amount = isLast
            ? bucketAmount - distributed
            : (bucketAmount * (weights[id] ?? 0) / 100).round();
        distributed += amount;
        rows.add((
          bucket: b.name,
          account: acct.name,
          amountMinor: amount,
          unlinked: false,
        ));
      }
    }
    final hasUnlinked = rows.any((r) => r.unlinked);

    return Column(
      children: [
        // Unlinked warning banner
        if (hasUnlinked)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Some buckets have no linked accounts. Go back and link accounts to all buckets before applying.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Table header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Bucket',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textTertiary,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textTertiary,
                  ),
                ),
              ),
              SizedBox(
                width: 90,
                child: Text(
                  'Amount',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 12, color: dividerColor),

        // Rows
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            itemCount: rows.length,
            separatorBuilder: (_, sep) => const SizedBox(height: 4),
            itemBuilder: (_, i) {
              final row = rows[i];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: row.unlinked
                      ? AppColors.warning.withValues(alpha: 0.08)
                      : elevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: row.unlinked
                                  ? AppColors.warning
                                  : AppColors.royalBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              row.bucket,
                              style: TextStyle(
                                fontSize: 12,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        row.unlinked ? 'No account linked' : row.account,
                        style: TextStyle(
                          fontSize: 12,
                          color: row.unlinked
                              ? AppColors.warning
                              : textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text(
                        _fmt(row.amountMinor),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: row.unlinked
                              ? AppColors.warning
                              : AppColors.royalBlue,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Footer buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 14),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.royalBlue,
                  side: const BorderSide(color: AppColors.royalBlue),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: hasUnlinked ? null : onApply,
                icon: const Icon(Icons.check, size: 14),
                label: const Text('Apply to budget'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.disabledSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(int minor) {
    final v = minor / 100;
    if (v >= 1000) return 'KES ${(v / 1000).toStringAsFixed(1)}K';
    return 'KES ${v.toStringAsFixed(0)}';
  }
}

// ── Empty plan panel ──────────────────────────────────────────────────────────

class _EmptyPlanPanel extends StatelessWidget {
  final String period;
  final List<BudgetPlan> templates;
  final String activeStrategyName;
  final bool hasIncome;
  final VoidCallback onCreateBlank;
  final VoidCallback onCopyPrevious;
  final ValueChanged<BudgetPlan> onApplyTemplate;
  final VoidCallback onApplyStrategy;
  final VoidCallback onEditStrategy;

  const _EmptyPlanPanel({
    required this.period,
    required this.templates,
    required this.activeStrategyName,
    required this.hasIncome,
    required this.onCreateBlank,
    required this.onCopyPrevious,
    required this.onApplyTemplate,
    required this.onApplyStrategy,
    required this.onEditStrategy,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textTertiary = isDark
        ? AppColors.darkTextTertiary
        : AppColors.lightTextTertiary;

    return Container(
      color: bg,
      child: Center(
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No budget plan for ${_fmt(period)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create one to start tracking your spending.',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
              const SizedBox(height: 24),

              // Primary actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCopyPrevious,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.royalBlue,
                        side: const BorderSide(color: AppColors.royalBlue),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Copy previous'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onCreateBlank,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.royalBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Start blank'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Apply strategy — primary CTA
              GestureDetector(
                onTap: onApplyStrategy,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasIncome
                          ? AppColors.royalBlue.withValues(alpha: 0.3)
                          : (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        size: 18,
                        color: hasIncome ? AppColors.royalBlue : textTertiary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Apply strategy',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: hasIncome
                                        ? textPrimary
                                        : textTertiary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.royalBlue.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    activeStrategyName,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.royalBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hasIncome
                                  ? 'Auto-generate lines from your income using $activeStrategyName buckets'
                                  : 'Record income first to use strategy allocation',
                              style: TextStyle(
                                fontSize: 11,
                                color: textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onEditStrategy,
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.royalBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Templates
              if (templates.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Or apply a template',
                  style: TextStyle(fontSize: 12, color: textTertiary),
                ),
                const SizedBox(height: 8),
                ...templates.map(
                  (t) => GestureDetector(
                    onTap: () => onApplyTemplate(t),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.file_copy_outlined,
                            size: 14,
                            color: AppColors.royalBlue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.templateName ?? 'Template',
                              style: TextStyle(
                                fontSize: 13,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${t.lines.length} lines',
                            style: TextStyle(fontSize: 11, color: textTertiary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(String period) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final parts = period.split('-');
    return '${months[int.parse(parts[1])]} ${parts[0]}';
  }
}
