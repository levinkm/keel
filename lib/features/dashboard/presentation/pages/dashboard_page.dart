import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:keel/core/di/injector.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:keel/features/dashboard/presentation/widgets/budget_status_card.dart';
import 'package:keel/features/dashboard/presentation/widgets/recent_transactions_card.dart';
import 'package:keel/core/widgets/page_shell.dart';
import 'package:keel/core/widgets/shimmer.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DashboardCubit>()..load(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        return Container(
          color: bg,
          padding: const EdgeInsets.only(top: kTitleBarHeight),
          child: state.when(
            initial: () => const SizedBox.shrink(),
            loading: () => const DashboardShimmer(),
            error: (msg) => Center(
              child: Text(msg, style: const TextStyle(color: AppColors.error)),
            ),
            loaded: (data) => LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 56,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ────────────────────────────────────────────────
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currentPeriodLabel(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () =>
                                  context.read<DashboardCubit>().load(),
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    size: 14,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Refresh',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Hero: Net Worth + Sparkline ───────────────────────────
                      _HeroCard(data: data),
                      const SizedBox(height: 10),

                      // ── 5 Metric Cards ────────────────────────────────────────
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _MetricCard(
                              icon: Iconsax.money_send,
                              label: 'Total Debt',
                              value: _fmt(data.totalDebtMinor),
                              sub: data.totalDebtMinor == 0
                                  ? 'debt-free ✓'
                                  : 'outstanding',
                              subPositive: data.totalDebtMinor == 0,
                              color: data.totalDebtMinor > 0
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                            const SizedBox(width: 10),
                            _MetricCard(
                              icon: Iconsax.empty_wallet_tick,
                              label: 'Liquid Cash',
                              value: _fmt(data.liquidMinor),
                              sub: data.netWorthMinor > 0
                                  ? '${(data.liquidMinor / data.netWorthMinor * 100).toStringAsFixed(0)}% of net worth'
                                  : '—',
                              subPositive: null,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 10),
                            _MetricCard(
                              icon: Iconsax.money_recive,
                              label: 'Lent Out',
                              value: _fmt(data.totalLentMinor),
                              sub: data.totalLentMinor > 0
                                  ? 'receivable'
                                  : 'nothing lent',
                              subPositive: null,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 10),
                            _MetricCard(
                              icon: Iconsax.chart_fail,
                              label: 'Interest Burden',
                              value:
                                  '${(data.interestBurdenPct * 100).toStringAsFixed(1)}%',
                              sub: data.totalInterestMinor > 0
                                  ? '${_fmt(data.totalInterestMinor)}/mo'
                                  : 'no interest cost',
                              subPositive: data.interestBurdenPct < 0.15,
                              color: data.interestBurdenPct >= 0.3
                                  ? AppColors.error
                                  : data.interestBurdenPct >= 0.15
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                            const SizedBox(width: 10),
                            _MetricCard(
                              icon: Iconsax.trend_up,
                              label: 'Savings Rate',
                              value:
                                  '${(data.savingsRate * 100).toStringAsFixed(1)}%',
                              sub: data.strategyTargetSavingsPct > 0
                                  ? 'target ${data.strategyTargetSavingsPct}%'
                                  : 'this month',
                              subPositive: data.savingsOnTrack,
                              color: data.savingsOnTrack
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Budget + Recent Transactions ──────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: BudgetStatusCard(
                              lines: data.budgetLines,
                              actualByAccount: data.actualByAccount,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RecentTransactionsCard(
                              entries: data.recentEntries,
                              accounts: data.accounts,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _currentPeriodLabel() {
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
    final now = DateTime.now();
    return '${months[now.month]} ${now.year}';
  }

  static String _fmt(int minor) {
    final v = minor.abs() / 100;
    final p = minor < 0 ? '-' : '';
    if (v >= 1000000) return '${p}KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${p}KES ${(v / 1000).toStringAsFixed(1)}K';
    return '${p}KES ${v.toStringAsFixed(0)}';
  }
}

// ── Hero Card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final DashboardData data;
  const _HeroCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textTertiary = isDark
        ? AppColors.darkTextTertiary
        : AppColors.lightTextTertiary;

    final history = data.netWorthHistory;
    final change = history.length >= 2
        ? history.last.netWorthMinor - history.first.netWorthMinor
        : 0;
    final changePct = history.isNotEmpty && history.first.netWorthMinor != 0
        ? change / history.first.netWorthMinor.abs() * 100
        : 0.0;
    final isUp = change >= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: label + value + sub-stats
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Iconsax.wallet, size: 13, color: AppColors.royalBlue),
                    const SizedBox(width: 6),
                    Text(
                      'Net Worth',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _fmtHero(data.netWorthMinor),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isUp ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 11,
                      color: isUp ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${isUp ? '+' : ''}${changePct.toStringAsFixed(1)}% over 6 months',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isUp ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Mini breakdown row
                Row(
                  children: [
                    Expanded(child: _HeroStat(
                      'Assets',
                      _fmt(data.physicalAssetsMinor),
                      textTertiary,
                      textPrimary,
                    )),
                    _divider(textTertiary),
                    Expanded(child: _HeroStat(
                      'Debt',
                      _fmt(data.totalDebtMinor),
                      textTertiary,
                      data.totalDebtMinor > 0
                          ? AppColors.error
                          : AppColors.success,
                    )),
                    _divider(textTertiary),
                    Expanded(child: _HeroStat(
                      'Liquid',
                      _fmt(data.liquidMinor),
                      textTertiary,
                      AppColors.success,
                    )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right: sparkline
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '6-month trajectory',
                  style: TextStyle(
                    fontSize: 10,
                    color: textTertiary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: history.length >= 2
                      ? CustomPaint(
                          size: const Size(double.infinity, 90),
                          painter: _SparklinePainter(
                            history: history,
                            isDark: isDark,
                          ),
                        )
                      : Center(
                          child: Text(
                            'Not enough data',
                            style: TextStyle(fontSize: 11, color: textTertiary),
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: history
                      .map(
                        (h) => Text(
                          _shortMonth(h.period),
                          style: TextStyle(fontSize: 9, color: textTertiary),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(Color color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Container(width: 1, height: 24, color: color.withValues(alpha: 0.3)),
  );

  static String _fmt(int minor) {
    final v = minor.abs() / 100;
    final p = minor < 0 ? '-' : '';
    if (v >= 1000000) return '${p}KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${p}KES ${(v / 1000).toStringAsFixed(1)}K';
    return '${p}KES ${v.toStringAsFixed(0)}';
  }

  static String _fmtHero(int minor) {
    final v = minor.abs() / 100;
    final p = minor < 0 ? '-' : '';
    if (v >= 1000000) return '${p}KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${p}KES ${(v / 1000).toStringAsFixed(1)}K';
    return '${p}KES ${v.toStringAsFixed(0)}';
  }

  String _shortMonth(String period) {
    const m = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return m[int.parse(period.split('-')[1])];
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  const _HeroStat(this.label, this.value, this.labelColor, this.valueColor);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(fontSize: 10, color: labelColor, letterSpacing: 0.3),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: valueColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

// ── Metric Card ───────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final bool? subPositive;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.subPositive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textTertiary = isDark
        ? AppColors.darkTextTertiary
        : AppColors.lightTextTertiary;

    final subColor = subPositive == null
        ? textTertiary
        : subPositive!
        ? AppColors.success
        : AppColors.error;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                letterSpacing: -0.3,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub ?? '—',
              style: TextStyle(
                fontSize: 10,
                color: subColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sparkline Painter ─────────────────────────────────────────────────────────

class _SparklinePainter extends CustomPainter {
  final List<MonthlyNetWorth> history;
  final bool isDark;
  _SparklinePainter({required this.history, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;

    final values = history.map((h) => h.netWorthMinor.toDouble()).toList();
    final minVal = values.reduce(min);
    final maxVal = values.reduce(max);
    final range = (maxVal - minVal).abs();
    final pad = range == 0 ? 1000.0 : range * 0.2;
    final lo = minVal - pad;
    final hi = maxVal + pad;
    final span = hi - lo;

    double xOf(int i) => size.width * i / (history.length - 1);
    double yOf(double v) => size.height * (1 - (v - lo) / span);

    final pts = List.generate(
      history.length,
      (i) => Offset(xOf(i), yOf(values[i])),
    );

    // Gradient fill
    final fillPath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cp1 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i - 1].dy);
      final cp2 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i].dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.royalBlue.withValues(alpha: 0.15),
            AppColors.royalBlue.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cp1 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i - 1].dy);
      final cp2 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.royalBlue
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Dots — only first and last
    for (final p in [pts.first, pts.last]) {
      canvas.drawCircle(p, 3, Paint()..color = AppColors.royalBlue);
      canvas.drawCircle(
        p,
        3,
        Paint()
          ..color = (isDark ? AppColors.darkSurface : AppColors.lightSurface)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.history != history;
}
