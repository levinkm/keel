import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:keel/core/di/injector.dart';
import 'package:keel/core/sync/sync_service.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:keel/features/dashboard/presentation/widgets/account_balances_card.dart';
import 'package:keel/features/dashboard/presentation/widgets/budget_status_card.dart';
import 'package:keel/features/dashboard/presentation/widgets/recent_transactions_card.dart';
import 'package:keel/core/widgets/page_shell.dart';
import 'package:keel/core/widgets/shimmer.dart';
import 'package:keel/core/widgets/blurred_amount.dart';

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
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

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
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 56),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ───────────────────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ValueListenableBuilder(
                            valueListenable: SyncService.instance.currentUser,
                            builder: (_, user, _) {
                              if (user == null) return const SizedBox.shrink();
                              final avatarUrl = SyncService.instance.googleAvatarUrl;
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: ClipOval(
                                  child: avatarUrl != null
                                      ? Image.network(
                                          avatarUrl,
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => _InitialsBubble(
                                            name: SyncService.instance.googleDisplayName ?? 'U',
                                          ),
                                        )
                                      : _InitialsBubble(
                                          name: SyncService.instance.googleDisplayName ?? 'U',
                                        ),
                                ),
                              );
                            },
                          ),
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
                                style: TextStyle(fontSize: 13, color: textSecondary),
                              ),
                            ],
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_horiz, size: 18, color: textSecondary),
                            onSelected: (value) {
                              if (value == 'refresh') context.read<DashboardCubit>().load();
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'refresh',
                                child: Row(
                                  children: [
                                    Icon(Icons.refresh, size: 14, color: textSecondary),
                                    const SizedBox(width: 8),
                                    const Text('Refresh', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Row 1: Hero + Month Summary ──────────────────────────
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 2, child: _HeroCard(data: data)),
                            const SizedBox(width: 10),
                            Expanded(flex: 1, child: _MonthSummaryCard(data: data)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Row 2: Cash Flow Chart ───────────────────────────────
                      _CashFlowCard(data: data),
                      const SizedBox(height: 10),

                      // ── Row 3: Accounts + Budget ─────────────────────────────
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: AccountBalancesCard(
                                accounts: data.accounts,
                                balances: data.balances,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: BudgetStatusCard(
                                lines: data.budgetLines,
                                actualByAccount: data.actualByAccount,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Row 4: Recent Transactions ───────────────────────────
                      RecentTransactionsCard(
                        entries: data.recentEntries,
                        accounts: data.accounts,
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
    final name = SyncService.instance.googleDisplayName?.split(' ').first;
    final suffix = name != null && name.isNotEmpty ? ', $name' : '';
    if (h < 12) return 'Good morning$suffix';
    if (h < 17) return 'Good afternoon$suffix';
    return 'Good evening$suffix';
  }

  String _currentPeriodLabel() {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    final now = DateTime.now();
    return '${months[now.month]} ${now.year}';
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
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

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
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.wallet, size: 13, color: AppColors.royalBlue),
              const SizedBox(width: 6),
              Text('Net Worth',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                      letterSpacing: 0.3)),
              const Spacer(),
              Icon(
                isUp ? Icons.arrow_upward : Icons.arrow_downward,
                size: 11,
                color: isUp ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 3),
              Text(
                '${isUp ? '+' : ''}${changePct.toStringAsFixed(1)}% (6 mo)',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isUp ? AppColors.success : AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 10),
          BlurredAmount(
            text: _fmtHero(data.netWorthMinor),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          // Sub-stats row
          Row(
            children: [
              Expanded(child: _HeroStat('Assets', _fmt(data.physicalAssetsMinor),
                  textTertiary, textPrimary)),
              _vDivider(textTertiary),
              Expanded(child: _HeroStat('Liquid', _fmt(data.liquidMinor),
                  textTertiary, AppColors.success)),
              _vDivider(textTertiary),
              Expanded(child: _HeroStat('Debt', _fmt(data.totalDebtMinor),
                  textTertiary,
                  data.totalDebtMinor > 0 ? AppColors.error : AppColors.success)),
              _vDivider(textTertiary),
              Expanded(child: _HeroStat('Lent', _fmt(data.totalLentMinor),
                  textTertiary, AppColors.warning)),
            ],
          ),
          const SizedBox(height: 16),
          // Sparkline
          Text('6-month trajectory',
              style: TextStyle(fontSize: 10, color: textTertiary, letterSpacing: 0.3)),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: history.length >= 2
                ? CustomPaint(
                    size: const Size(double.infinity, 80),
                    painter: _SparklinePainter(history: history, isDark: isDark),
                  )
                : Center(
                    child: Text('Not enough data',
                        style: TextStyle(fontSize: 11, color: textTertiary))),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: history
                .map((h) => Text(_shortMonth(h.period),
                    style: TextStyle(fontSize: 9, color: textTertiary)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _vDivider(Color color) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(width: 1, height: 24, color: color.withValues(alpha: 0.3)),
      );

  static String _fmt(int minor) {
    final v = minor.abs() / 100;
    final p = minor < 0 ? '-' : '';
    if (v >= 1000000) return '${p}KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${p}KES ${(v / 1000).toStringAsFixed(1)}K';
    return '${p}KES ${v.toStringAsFixed(0)}';
  }

  static String _fmtHero(int minor) => _fmt(minor);

  String _shortMonth(String period) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
          Text(label,
              style: TextStyle(fontSize: 10, color: labelColor, letterSpacing: 0.3)),
          const SizedBox(height: 2),
          BlurredAmount(
            text: value,
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

// ── Month Summary Card ────────────────────────────────────────────────────────

class _MonthSummaryCard extends StatelessWidget {
  final DashboardData data;
  const _MonthSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final trackColor = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceSecondary;

    final saved = data.incomeMinor - data.expensesMinor;
    final savingsPct = (data.savingsRate * 100);
    final savingsColor = data.savingsOnTrack ? AppColors.success : AppColors.warning;
    final interestColor = data.interestBurdenPct >= 0.3
        ? AppColors.error
        : data.interestBurdenPct >= 0.15
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This month',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary)),
          const SizedBox(height: 16),
          _SummaryRow(
            icon: Iconsax.money_recive,
            label: 'Income',
            value: _fmt(data.incomeMinor),
            color: AppColors.success,
            textPrimary: textPrimary,
            textTertiary: textTertiary,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Iconsax.money_send,
            label: 'Expenses',
            value: _fmt(data.expensesMinor),
            color: AppColors.error,
            textPrimary: textPrimary,
            textTertiary: textTertiary,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Iconsax.trend_up,
            label: 'Saved',
            value: _fmt(saved.abs()),
            color: saved >= 0 ? AppColors.success : AppColors.error,
            textPrimary: textPrimary,
            textTertiary: textTertiary,
            prefix: saved < 0 ? '-' : null,
          ),
          const SizedBox(height: 16),
          // Savings rate bar
          Row(
            children: [
              Text('Savings rate',
                  style: TextStyle(fontSize: 10, color: textTertiary)),
              const Spacer(),
              Text(
                '${savingsPct.toStringAsFixed(1)}%${data.strategyTargetSavingsPct > 0 ? ' / ${data.strategyTargetSavingsPct}% target' : ''}',
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600, color: savingsColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: data.savingsRate,
              minHeight: 5,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation(savingsColor),
            ),
          ),
          const SizedBox(height: 14),
          // Interest burden
          Row(
            children: [
              Icon(Iconsax.chart_fail, size: 12, color: interestColor),
              const SizedBox(width: 6),
              Text('Interest burden',
                  style: TextStyle(fontSize: 11, color: textTertiary)),
              const Spacer(),
              Text(
                '${(data.interestBurdenPct * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: interestColor),
              ),
            ],
          ),
          if (data.totalInterestMinor > 0) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Text('${_fmt(data.totalInterestMinor)}/mo',
                  style: TextStyle(fontSize: 10, color: textTertiary)),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmt(int minor) {
    final v = minor.abs() / 100;
    final p = minor < 0 ? '-' : '';
    if (v >= 1000000) return '${p}KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${p}KES ${(v / 1000).toStringAsFixed(1)}K';
    return '${p}KES ${v.toStringAsFixed(0)}';
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color textPrimary;
  final Color textTertiary;
  final String? prefix;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.textPrimary,
    required this.textTertiary,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: textTertiary)),
          const Spacer(),
          BlurredAmount(
            text: '${prefix ?? ''}$value',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );
}

// ── Cash Flow Card ────────────────────────────────────────────────────────────

class _CashFlowCard extends StatelessWidget {
  final DashboardData data;
  const _CashFlowCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    final cf = data.cashFlow;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Cash Flow',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary)),
              const Spacer(),
              _Legend(color: AppColors.success, label: 'Income'),
              const SizedBox(width: 14),
              _Legend(color: AppColors.error, label: 'Expenses'),
            ],
          ),
          const SizedBox(height: 14),
          if (cf.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No cash flow data',
                    style: TextStyle(fontSize: 12, color: textTertiary)),
              ),
            )
          else
            SizedBox(
              height: 100,
              child: CustomPaint(
                size: const Size(double.infinity, 100),
                painter: _CashFlowPainter(cashFlow: cf, isDark: isDark),
              ),
            ),
          const SizedBox(height: 8),
          if (cf.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: cf
                  .map((c) => Text(_shortMonth(c.period),
                      style: TextStyle(fontSize: 9, color: textTertiary)))
                  .toList(),
            ),
        ],
      ),
    );
  }

  String _shortMonth(String period) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m[int.parse(period.split('-')[1])];
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: textTertiary)),
      ],
    );
  }
}

class _CashFlowPainter extends CustomPainter {
  final List<MonthlyCashFlow> cashFlow;
  final bool isDark;
  _CashFlowPainter({required this.cashFlow, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (cashFlow.isEmpty) return;

    final allValues = cashFlow.expand((c) => [c.incomeMinor, c.expensesMinor]);
    final maxVal = allValues.reduce(max).toDouble();
    if (maxVal == 0) return;

    final n = cashFlow.length;
    final groupWidth = size.width / n;
    final barWidth = groupWidth * 0.28;
    final gap = groupWidth * 0.04;

    for (int i = 0; i < n; i++) {
      final cf = cashFlow[i];
      final cx = groupWidth * i + groupWidth / 2;

      final incomeH = (cf.incomeMinor / maxVal) * size.height;
      final expH = (cf.expensesMinor / maxVal) * size.height;

      // Income bar (left of center)
      final incomeRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - gap - barWidth, size.height - incomeH, barWidth, incomeH),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(incomeRect,
          Paint()..color = AppColors.success.withValues(alpha: 0.75));

      // Expense bar (right of center)
      final expRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx + gap, size.height - expH, barWidth, expH),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(expRect,
          Paint()..color = AppColors.error.withValues(alpha: 0.75));
    }
  }

  @override
  bool shouldRepaint(_CashFlowPainter old) => old.cashFlow != cashFlow;
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

    final pts = List.generate(history.length, (i) => Offset(xOf(i), yOf(values[i])));

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

// ── Initials Bubble ───────────────────────────────────────────────────────────

class _InitialsBubble extends StatelessWidget {
  final String name;
  const _InitialsBubble({required this.name});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        color: AppColors.royalBlue,
        child: Center(
          child: Text(
            _initials,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      );
}
