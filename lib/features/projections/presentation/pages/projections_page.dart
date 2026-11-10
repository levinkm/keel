import 'package:keel/core/widgets/responsive.dart';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/di/injector.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/projections/presentation/bloc/projections_cubit.dart';
import 'package:keel/core/widgets/page_shell.dart';
import 'package:keel/core/widgets/shimmer.dart';

class ProjectionsPage extends StatelessWidget {
  const ProjectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProjectionsCubit>()..load(),
      child: const _ProjectionsView(),
    );
  }
}

class _ProjectionsView extends StatelessWidget {
  const _ProjectionsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectionsCubit, ProjectionsState>(
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const MasterDetailShimmer(statCardCount: 3),
          error: (msg) => Center(
              child: Text(msg, style: const TextStyle(color: AppColors.error))),
          loaded: (currentNW, monthlyIncome, monthlyExpenses,
              incomeStreamCount, expensesFromBudget, loanSchedules,
              points, months, incomeGrowth, expenseGrowth, savingsTarget) {
            final cubit = context.read<ProjectionsCubit>();
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
            final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
            final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
            final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
            final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
            final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

            final loanPayments = loanSchedules.fold<int>(0, (s, l) => s + l.monthlyPaymentMinor);
            final monthlySavings = monthlyIncome - monthlyExpenses - loanPayments;
            final endNW = points.isNotEmpty ? points.last.netWorthMinor : currentNW;
            final nwChange = endNW - currentNW;

            int? monthsToTarget;
            if (savingsTarget > 0 && monthlySavings > 0) {
              final needed = savingsTarget - currentNW;
              if (needed > 0) monthsToTarget = (needed / monthlySavings).ceil();
            }

            return Container(
              color: bg,
              padding: const EdgeInsets.only(top: kTitleBarHeight),
              child: Column(
                children: [
                  // ── Top bar ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text('Projections',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  letterSpacing: -0.3)),
                          const Spacer(),
                          Text('$months month forecast',
                              style: TextStyle(fontSize: 12, color: textSecondary)),
                        ]),
                        const SizedBox(height: 16),
                        // Stat cards
                        Row(children: [
                          _StatCard(
                            label: 'CURRENT NET WORTH',
                            value: _fmt(currentNW),
                            color: AppColors.royalBlue,
                            surface: surface,
                            icon: Icons.account_balance_outlined,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'PROJECTED (${months}MO)',
                            value: _fmt(endNW),
                            color: nwChange >= 0 ? AppColors.success : AppColors.error,
                            surface: surface,
                            icon: nwChange >= 0 ? Icons.trending_up_outlined : Icons.trending_down_outlined,
                            sub: '${nwChange >= 0 ? '+' : ''}${_fmt(nwChange)}',
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'MONTHLY SAVINGS',
                            value: _fmt(monthlySavings),
                            color: monthlySavings >= 0 ? AppColors.success : AppColors.error,
                            surface: surface,
                            icon: Icons.savings_outlined,
                            sub: '${_fmt(monthlyIncome)} − ${_fmt(monthlyExpenses + loanPayments)}',
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'LOAN PAYMENTS',
                            value: _fmt(loanPayments),
                            color: loanPayments > 0 ? AppColors.warning : textSecondary,
                            surface: surface,
                            icon: Icons.credit_card_outlined,
                            sub: loanSchedules.isEmpty ? 'No active loans' : '${loanSchedules.length} loan${loanSchedules.length > 1 ? 's' : ''}',
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Split panel ──────────────────────────────────────────
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: assumptions
                        SizedBox(
                          width: sidebarWidth(context),
                          child: Container(
                            color: bg,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              child: _AssumptionsPanel(
                                months: months,
                                incomeGrowthPct: incomeGrowth,
                                expenseGrowthPct: expenseGrowth,
                                savingsTargetMinor: savingsTarget,
                                monthlyIncomeMinor: monthlyIncome,
                                monthlyExpensesMinor: monthlyExpenses,
                                loanPaymentsMinor: loanPayments,
                                incomeStreamCount: incomeStreamCount,
                                expensesFromBudget: expensesFromBudget,
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                textTertiary: textTertiary,
                                surface: surface,
                                onChanged: ({int? months, double? incomeGrowth,
                                    double? expenseGrowth, int? savingsTarget}) =>
                                    cubit.updateAssumptions(
                                      months: months,
                                      incomeGrowthPct: incomeGrowth,
                                      expenseGrowthPct: expenseGrowth,
                                      savingsTargetMinor: savingsTarget,
                                    ),
                              ),
                            ),
                          ),
                        ),

                        VerticalDivider(width: 1, color: divider),

                        // Right: charts
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Net worth trajectory
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                      color: surface,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Text('Net worth trajectory',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: textSecondary)),
                                        const Spacer(),
                                        Text('$months months',
                                            style: TextStyle(
                                                fontSize: 11, color: textTertiary)),
                                      ]),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Based on ${_fmt(monthlySavings)}/mo net savings',
                                        style: TextStyle(fontSize: 11, color: textTertiary),
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        height: 180,
                                        child: CustomPaint(
                                          size: const Size(double.infinity, 180),
                                          painter: _NetWorthChartPainter(
                                              points: points, isDark: isDark),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: _xLabels(points)
                                            .map((l) => Text(l,
                                                style: TextStyle(
                                                    fontSize: 9, color: textTertiary)))
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Cash flow chart
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                      color: surface,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Text('Monthly cash flow',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: textSecondary)),
                                        const Spacer(),
                                        _legend(AppColors.success, 'Income', textTertiary),
                                        const SizedBox(width: 12),
                                        _legend(AppColors.error, 'Outgoings', textTertiary),
                                      ]),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        height: 100,
                                        child: CustomPaint(
                                          size: const Size(double.infinity, 100),
                                          painter: _CashFlowChartPainter(
                                              points: points, isDark: isDark),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Savings target
                                if (savingsTarget > 0) ...[
                                  _SavingsTargetCard(
                                    currentMinor: currentNW,
                                    targetMinor: savingsTarget,
                                    monthlySavingsMinor: monthlySavings,
                                    monthsToTarget: monthsToTarget,
                                    surface: surface,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    textTertiary: textTertiary,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Loan payoff
                                if (loanSchedules.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text('Loan payoff timeline',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textSecondary)),
                                  ),
                                  ...loanSchedules.map((lp) => _LoanPayoffRow(
                                        lp: lp,
                                        surface: surface,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                        textTertiary: textTertiary,
                                      )),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<String> _xLabels(List<ProjectionPoint> points) {
    if (points.isEmpty) return [];
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final step = max(1, points.length ~/ 6);
    final labels = <String>[];
    for (int i = 0; i < points.length; i += step) {
      labels.add('${m[points[i].date.month]} \'${points[i].date.year % 100}');
    }
    return labels;
  }

  Widget _legend(Color color, String label, Color textColor) =>
      Row(children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: textColor)),
      ]);

  static String _fmt(int minor) {
    final v = minor.abs() / 100;
    final p = minor < 0 ? '−' : '';
    if (v >= 1000000) return '${p}KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${p}KES ${(v / 1000).toStringAsFixed(1)}K';
    return '${p}KES ${v.toStringAsFixed(0)}';
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color surface;
  final IconData icon;
  final String? sub;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.surface,
    required this.icon,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                      letterSpacing: 0.4, color: textSecondary)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: color,
                      fontFeatures: const [FontFeature.tabularFigures()])),
              if (sub != null)
                Text(sub!,
                    style: TextStyle(fontSize: 10, color: textTertiary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Assumptions panel ─────────────────────────────────────────────────────────

class _AssumptionsPanel extends StatefulWidget {
  final int months;
  final double incomeGrowthPct;
  final double expenseGrowthPct;
  final int savingsTargetMinor;
  final int monthlyIncomeMinor;
  final int monthlyExpensesMinor;
  final int loanPaymentsMinor;
  final int incomeStreamCount;
  final bool expensesFromBudget;
  final bool isDark;
  final Color textPrimary, textSecondary, textTertiary, surface;
  final void Function({int? months, double? incomeGrowth,
      double? expenseGrowth, int? savingsTarget}) onChanged;

  const _AssumptionsPanel({
    required this.months,
    required this.incomeGrowthPct,
    required this.expenseGrowthPct,
    required this.savingsTargetMinor,
    required this.monthlyIncomeMinor,
    required this.monthlyExpensesMinor,
    required this.loanPaymentsMinor,
    required this.incomeStreamCount,
    required this.expensesFromBudget,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.surface,
    required this.onChanged,
  });

  @override
  State<_AssumptionsPanel> createState() => _AssumptionsPanelState();
}

class _AssumptionsPanelState extends State<_AssumptionsPanel> {
  late final TextEditingController _incomeCtrl;
  late final TextEditingController _expenseCtrl;
  late final TextEditingController _targetCtrl;

  @override
  void initState() {
    super.initState();
    _incomeCtrl = TextEditingController(text: widget.incomeGrowthPct.toStringAsFixed(1));
    _expenseCtrl = TextEditingController(text: widget.expenseGrowthPct.toStringAsFixed(1));
    _targetCtrl = TextEditingController(
        text: widget.savingsTargetMinor > 0
            ? (widget.savingsTargetMinor / 100).toStringAsFixed(0)
            : '');
  }

  @override
  void dispose() {
    _incomeCtrl.dispose();
    _expenseCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fieldBg = widget.isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.lightSurfaceSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Data sources ─────────────────────────────────────────────────
        _sectionLabel('DATA SOURCES', widget.textTertiary),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
              color: widget.surface, borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            _sourceRow(
              Icons.trending_up_outlined,
              'Monthly income',
              _fmt(widget.monthlyIncomeMinor),
              '${widget.incomeStreamCount} income stream${widget.incomeStreamCount != 1 ? 's' : ''}',
              AppColors.success,
              widget.textPrimary,
              widget.textTertiary,
            ),
            Divider(height: 16,
                color: (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder)
                    .withValues(alpha: 0.5)),
            _sourceRow(
              Icons.receipt_long_outlined,
              'Monthly expenses',
              _fmt(widget.monthlyExpensesMinor),
              widget.expensesFromBudget
                  ? 'From current budget plan'
                  : 'Avg of last 3 budget plans',
              AppColors.error,
              widget.textPrimary,
              widget.textTertiary,
            ),
            Divider(height: 16,
                color: (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder)
                    .withValues(alpha: 0.5)),
            _sourceRow(
              Icons.credit_card_outlined,
              'Loan payments',
              _fmt(widget.loanPaymentsMinor),
              'From active loan schedules',
              AppColors.warning,
              widget.textPrimary,
              widget.textTertiary,
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // ── Forecast horizon ─────────────────────────────────────────────
        _sectionLabel('FORECAST HORIZON', widget.textTertiary),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [6, 12, 24, 36, 60].map((m) {
            final isSelected = m == widget.months;
            return GestureDetector(
              onTap: () => widget.onChanged(months: m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.royalBlue : fieldBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${m}mo',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white : widget.textSecondary)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // ── Growth assumptions ───────────────────────────────────────────
        _sectionLabel('GROWTH ASSUMPTIONS', widget.textTertiary),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
              color: widget.surface, borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            _growthField('Income growth', _incomeCtrl, fieldBg,
                widget.textPrimary, widget.textSecondary, widget.textTertiary,
                (v) => widget.onChanged(incomeGrowth: double.tryParse(v) ?? 0)),
            const SizedBox(height: 12),
            _growthField('Expense growth', _expenseCtrl, fieldBg,
                widget.textPrimary, widget.textSecondary, widget.textTertiary,
                (v) => widget.onChanged(expenseGrowth: double.tryParse(v) ?? 0)),
          ]),
        ),
        const SizedBox(height: 20),

        // ── Net worth target ─────────────────────────────────────────────
        _sectionLabel('NET WORTH TARGET', widget.textTertiary),
        const SizedBox(height: 10),
        CupertinoTextField(
          controller: _targetCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          placeholder: 'e.g. 1,000,000',
          onChanged: (v) {
            final val = ((double.tryParse(v.replaceAll(',', '')) ?? 0) * 100).round();
            widget.onChanged(savingsTarget: val);
          },
          style: TextStyle(fontSize: 13, color: widget.textPrimary),
          placeholderStyle: TextStyle(fontSize: 13, color: widget.textTertiary),
          decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        const SizedBox(height: 4),
        Text('Set a target to see how long it will take to reach it.',
            style: TextStyle(fontSize: 10, color: widget.textTertiary)),
      ],
    );
  }

  Widget _sourceRow(IconData icon, String label, String value, String source,
      Color valueColor, Color textPrimary, Color textTertiary) =>
      Row(children: [
        Icon(icon, size: 14, color: valueColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 12, color: textPrimary)),
            Text(source, style: TextStyle(fontSize: 10, color: textTertiary)),
          ]),
        ),
        Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: valueColor,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ]);

  Widget _growthField(String label, TextEditingController ctrl, Color fieldBg,
      Color textPrimary, Color textSecondary, Color textTertiary,
      ValueChanged<String> onChanged) =>
      Row(children: [
        Expanded(child: Text(label,
            style: TextStyle(fontSize: 12, color: textSecondary))),
        SizedBox(
          width: 90,
          child: CupertinoTextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            suffix: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('% p.a.',
                  style: TextStyle(fontSize: 11, color: textTertiary)),
            ),
            onChanged: onChanged,
            style: TextStyle(fontSize: 13, color: textPrimary),
            decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(6)),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          ),
        ),
      ]);

  Widget _sectionLabel(String text, Color color) => Text(text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
          color: color, letterSpacing: 0.8));

  static String _fmt(int minor) {
    final v = minor.abs() / 100;
    final p = minor < 0 ? '−' : '';
    if (v >= 1000000) return '${p}KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${p}KES ${(v / 1000).toStringAsFixed(1)}K';
    return '${p}KES ${v.toStringAsFixed(0)}';
  }
}

// ── Savings target card ───────────────────────────────────────────────────────

class _SavingsTargetCard extends StatelessWidget {
  final int currentMinor, targetMinor, monthlySavingsMinor;
  final int? monthsToTarget;
  final Color surface, textPrimary, textSecondary, textTertiary;
  final bool isDark;

  const _SavingsTargetCard({
    required this.currentMinor, required this.targetMinor,
    required this.monthlySavingsMinor, required this.monthsToTarget,
    required this.surface, required this.textPrimary,
    required this.textSecondary, required this.textTertiary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final pct = targetMinor > 0
        ? (currentMinor / targetMinor).clamp(0.0, 1.0) : 0.0;
    final reached = currentMinor >= targetMinor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(reached ? Icons.check_circle_outline : Icons.flag_outlined,
              size: 16, color: reached ? AppColors.success : AppColors.royalBlue),
          const SizedBox(width: 8),
          Text('Net worth target',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: textSecondary)),
          const Spacer(),
          Text(_fmt(targetMinor),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.royalBlue,
                  fontFeatures: [FontFeature.tabularFigures()])),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct, minHeight: 6,
            backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            valueColor: AlwaysStoppedAnimation(
                reached ? AppColors.success : AppColors.royalBlue),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Text('${(pct * 100).toStringAsFixed(1)}% achieved',
              style: TextStyle(fontSize: 11, color: textSecondary)),
          const Spacer(),
          if (reached)
            const Text('Target reached!',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.success))
          else if (monthsToTarget != null)
            Text('~${_fmtMonths(monthsToTarget!)} to reach target',
                style: TextStyle(fontSize: 11, color: textSecondary))
          else if (monthlySavingsMinor <= 0)
            Text('Increase savings to reach target',
                style: TextStyle(fontSize: 11, color: AppColors.error)),
        ]),
      ]),
    );
  }

  String _fmtMonths(int m) {
    if (m >= 12) { final y = m ~/ 12; final r = m % 12; return r > 0 ? '${y}y ${r}mo' : '${y}y'; }
    return '${m}mo';
  }

  static String _fmt(int minor) {
    final v = minor.abs() / 100;
    final p = minor < 0 ? '−' : '';
    if (v >= 1000000) return '${p}KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${p}KES ${(v / 1000).toStringAsFixed(1)}K';
    return '${p}KES ${v.toStringAsFixed(0)}';
  }
}

// ── Loan payoff row ───────────────────────────────────────────────────────────

class _LoanPayoffRow extends StatelessWidget {
  final LoanProjection lp;
  final Color surface, textPrimary, textSecondary, textTertiary;

  const _LoanPayoffRow({
    required this.lp, required this.surface,
    required this.textPrimary, required this.textSecondary,
    required this.textTertiary,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final payoff = DateTime(now.year, now.month + lp.remainingMonths);
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.credit_card_outlined, size: 16, color: AppColors.error),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lp.loan.counterparty,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: textPrimary)),
            Text(
              '${_fmt(lp.monthlyPaymentMinor)}/mo · ${lp.remainingMonths} months left · '
              'Paid off ${m[payoff.month]} ${payoff.year}',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_fmt(lp.outstandingMinor),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.error,
                  fontFeatures: [FontFeature.tabularFigures()])),
          Text('outstanding', style: TextStyle(fontSize: 10, color: textTertiary)),
        ]),
      ]),
    );
  }

  static String _fmt(int minor) {
    final v = minor.abs() / 100;
    final p = minor < 0 ? '−' : '';
    if (v >= 1000000) return '${p}KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${p}KES ${(v / 1000).toStringAsFixed(1)}K';
    return '${p}KES ${v.toStringAsFixed(0)}';
  }
}

// ── Chart painters ────────────────────────────────────────────────────────────

class _NetWorthChartPainter extends CustomPainter {
  final List<ProjectionPoint> points;
  final bool isDark;
  _NetWorthChartPainter({required this.points, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final values = points.map((p) => p.netWorthMinor.toDouble()).toList();
    final maxVal = values.reduce(max);
    final minVal = values.reduce(min);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final gridPaint = Paint()
      ..color = (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (int i = 1; i <= 4; i++) {
      final y = size.height * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (minVal < 0 && maxVal > 0) {
      final zeroY = size.height * (1 - (0 - minVal) / range);
      canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY),
          Paint()..color = AppColors.error.withValues(alpha: 0.5)..strokeWidth = 1);
    }

    final pts = List.generate(values.length, (i) => Offset(
        size.width * i / (values.length - 1),
        size.height * (1 - (values[i] - minVal) / range)));

    final fillPath = Path()..moveTo(pts.first.dx, size.height);
    for (final p in pts) { fillPath.lineTo(p.dx, p.dy); }
    fillPath.lineTo(pts.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [AppColors.royalBlue.withValues(alpha: 0.18),
                 AppColors.royalBlue.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) { linePath.lineTo(pts[i].dx, pts[i].dy); }
    canvas.drawPath(linePath, Paint()
      ..color = AppColors.royalBlue..strokeWidth = 2
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_NetWorthChartPainter old) =>
      old.points != points || old.isDark != isDark;
}

class _CashFlowChartPainter extends CustomPainter {
  final List<ProjectionPoint> points;
  final bool isDark;
  _CashFlowChartPainter({required this.points, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final maxVal = points.fold(0.0, (m, p) => max(m,
        max(p.incomeMinor.toDouble(),
            (p.expensesMinor + p.loanPaymentsMinor).toDouble())));
    if (maxVal == 0) return;

    final gw = size.width / points.length;
    final bw = gw * 0.3;
    final gap = gw * 0.05;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final cx = gw * i + gw / 2;
      final incH = (p.incomeMinor / maxVal) * size.height;
      final expH = ((p.expensesMinor + p.loanPaymentsMinor) / maxVal) * size.height;

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - bw - gap / 2, size.height - incH, bw, incH),
          topLeft: const Radius.circular(2), topRight: const Radius.circular(2)),
        Paint()..color = AppColors.success.withValues(alpha: 0.75)..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx + gap / 2, size.height - expH, bw, expH),
          topLeft: const Radius.circular(2), topRight: const Radius.circular(2)),
        Paint()..color = AppColors.error.withValues(alpha: 0.65)..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_CashFlowChartPainter old) =>
      old.points != points || old.isDark != isDark;
}
