import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/di/injector.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/assets/domain/entities/asset.dart';
import 'package:keel/features/loans/domain/entities/loan.dart';
import 'package:keel/features/net_worth/presentation/bloc/net_worth_cubit.dart';
import 'package:keel/core/widgets/page_shell.dart';
import 'package:keel/core/widgets/shimmer.dart';

class NetWorthPage extends StatelessWidget {
  const NetWorthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NetWorthCubit>()..load(),
      child: const _NetWorthView(),
    );
  }
}

class _NetWorthView extends StatelessWidget {
  const _NetWorthView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetWorthCubit, NetWorthState>(
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const NetWorthShimmer(),
          error: (msg) => Center(
            child: Text(msg, style: const TextStyle(color: AppColors.error)),
          ),
          loaded:
              (
                netWorth,
                totalAssets,
                totalLiabilities,
                liquid,
                totalCash,
                totalPhysical,
                totalInvestments,
                cashAccounts,
                physicalAssets,
                activeHoldings,
                loanBalances,
              ) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final bg = isDark
                    ? AppColors.darkBackground
                    : AppColors.lightBackground;
                final surface = isDark
                    ? AppColors.darkSurface
                    : AppColors.lightSurface;
                final textPrimary = isDark
                    ? AppColors.darkText
                    : AppColors.lightText;
                final textSecondary = isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary;
                final textTertiary = isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary;

                final isPositive = netWorth >= 0;

                return Container(
                  color: bg,
                  padding: const EdgeInsets.only(top: kTitleBarHeight),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ──────────────────────────────────────────────
                        Text(
                          'Net Worth',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Headline card ────────────────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total net worth',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textTertiary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _fmtFull(netWorth),
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: isPositive
                                      ? textPrimary
                                      : AppColors.error,
                                  letterSpacing: -1,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Assets vs Liabilities bar
                              if (totalAssets > 0) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Assets ${_fmtShort(totalAssets)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.success,
                                      ),
                                    ),
                                    Text(
                                      'Liabilities ${_fmtShort(totalLiabilities)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: totalAssets > 0
                                        ? (totalAssets /
                                                  (totalAssets +
                                                      totalLiabilities))
                                              .clamp(0.0, 1.0)
                                        : 0,
                                    minHeight: 8,
                                    backgroundColor: AppColors.error.withValues(
                                      alpha: 0.3,
                                    ),
                                    valueColor: const AlwaysStoppedAnimation(
                                      AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              // Liquid vs Illiquid
                              Row(
                                children: [
                                  _miniStat(
                                    'LIQUID',
                                    _fmtShort(liquid),
                                    AppColors.success,
                                    textSecondary,
                                  ),
                                  const SizedBox(width: 24),
                                  _miniStat(
                                    'ILLIQUID',
                                    _fmtShort(totalAssets - liquid),
                                    textSecondary,
                                    textSecondary,
                                  ),
                                  const SizedBox(width: 24),
                                  _miniStat(
                                    'LIABILITIES',
                                    _fmtShort(totalLiabilities),
                                    AppColors.error,
                                    textSecondary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Allocation bar ───────────────────────────────────────
                        if (totalAssets > 0) ...[
                          _AllocationBar(
                            cash: totalCash,
                            physical: totalPhysical,
                            investments: totalInvestments,
                            total: totalAssets,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Three columns ────────────────────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cash & Bank
                            Expanded(
                              child: _SectionCard(
                                title: 'Cash & Bank',
                                total: totalCash,
                                color: AppColors.royalBlue,
                                icon: Icons.account_balance_wallet_outlined,
                                surface: surface,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                textTertiary: textTertiary,
                                isDark: isDark,
                                emptyText: 'No accounts',
                                children: cashAccounts
                                    .take(8)
                                    .map(
                                      (a) => _RowItem(
                                        label: a.account.name,
                                        value: _fmtShort(a.balanceMinor),
                                        valueColor: a.balanceMinor < 0
                                            ? AppColors.error
                                            : textPrimary,
                                        dot: _liquidityColor(
                                          a.account.liquidity,
                                        ),
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                        isDark: isDark,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Physical Assets
                            Expanded(
                              child: _SectionCard(
                                title: 'Physical Assets',
                                total: totalPhysical,
                                color: AppColors.success,
                                icon: Icons.home_outlined,
                                surface: surface,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                textTertiary: textTertiary,
                                isDark: isDark,
                                emptyText: 'No physical assets',
                                children: physicalAssets
                                    .take(8)
                                    .map(
                                      (a) => _RowItem(
                                        label: a.name,
                                        value: _fmtShort(a.bookValue),
                                        valueColor: textPrimary,
                                        dot: AppColors.success,
                                        sub: _classLabel(a.assetClass),
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                        isDark: isDark,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Investments
                            Expanded(
                              child: _SectionCard(
                                title: 'Investments',
                                total: totalInvestments,
                                color: AppColors.warning,
                                icon: Icons.show_chart_outlined,
                                surface: surface,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                textTertiary: textTertiary,
                                isDark: isDark,
                                emptyText: 'No investments',
                                children: activeHoldings.take(8).map((h) {
                                  final gain = h.unrealisedGainMinor;
                                  return _RowItem(
                                    label: h.name,
                                    value: _fmtShort(h.marketValueMinor),
                                    valueColor: textPrimary,
                                    dot: AppColors.warning,
                                    sub:
                                        '${gain >= 0 ? '+' : ''}${_fmtShort(gain)}',
                                    subColor: gain >= 0
                                        ? AppColors.success
                                        : AppColors.error,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    isDark: isDark,
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Liabilities ──────────────────────────────────────────
                        if (loanBalances.isNotEmpty)
                          _SectionCard(
                            title: 'Loans & Liabilities',
                            total: loanBalances.fold(
                              0,
                              (s, l) => s + l.outstandingMinor,
                            ),
                            color: AppColors.error,
                            icon: Icons.credit_card_outlined,
                            surface: surface,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            textTertiary: textTertiary,
                            isDark: isDark,
                            totalIsNegative: true,
                            emptyText: '',
                            children: loanBalances
                                .map(
                                  (l) => _RowItem(
                                    label: l.loan.counterparty,
                                    value: '−${_fmtShort(l.outstandingMinor)}',
                                    valueColor: AppColors.error,
                                    dot: AppColors.error,
                                    sub: _loanLabel(l.loan),
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    isDark: isDark,
                                  ),
                                )
                                .toList(),
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

  Widget _miniStat(
    String label,
    String value,
    Color valueColor,
    Color labelColor,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: labelColor,
          letterSpacing: 0.6,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: valueColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ],
  );

  Color _liquidityColor(Liquidity l) => switch (l) {
    Liquidity.instant => AppColors.success,
    Liquidity.days => AppColors.warning,
    Liquidity.locked => AppColors.slateBlue,
  };

  String _classLabel(AssetClass c) => switch (c) {
    AssetClass.cashAndBank => 'Cash & Bank',
    AssetClass.investments => 'Investment',
    AssetClass.vehicle => 'Vehicle',
    AssetClass.machinery => 'Machinery',
    AssetClass.land => 'Land',
    AssetClass.building => 'Building',
    AssetClass.receivable => 'Receivable',
    AssetClass.other => 'Other',
  };

  String _loanLabel(Loan l) =>
      '${(l.annualRateBp / 100).toStringAsFixed(1)}% · ${l.termMonths}mo';

  static String _fmtFull(int minor) {
    final v = minor / 100;
    final abs = v
        .abs()
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '${v < 0 ? '−' : ''}KES $abs';
  }

  static String _fmtShort(int minor) {
    final v = minor.abs() / 100;
    final p = minor < 0 ? '−' : '';
    if (v >= 1000000) return '${p}KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${p}KES ${(v / 1000).toStringAsFixed(1)}K';
    return '${p}KES ${v.toStringAsFixed(0)}';
  }
}

// ── Allocation bar ────────────────────────────────────────────────────────────

class _AllocationBar extends StatelessWidget {
  final int cash, physical, investments, total;
  final bool isDark;
  const _AllocationBar({
    required this.cash,
    required this.physical,
    required this.investments,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final cashPct = total > 0 ? cash / total : 0.0;
    final physPct = total > 0 ? physical / total : 0.0;
    final invPct = total > 0 ? investments / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asset allocation',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                if (cashPct > 0)
                  Expanded(
                    flex: (cashPct * 1000).round(),
                    child: Container(height: 12, color: AppColors.royalBlue),
                  ),
                if (physPct > 0)
                  Expanded(
                    flex: (physPct * 1000).round(),
                    child: Container(height: 12, color: AppColors.success),
                  ),
                if (invPct > 0)
                  Expanded(
                    flex: (invPct * 1000).round(),
                    child: Container(height: 12, color: AppColors.warning),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legend(
                AppColors.royalBlue,
                'Cash & Bank',
                '${(cashPct * 100).toStringAsFixed(1)}%',
                textSecondary,
              ),
              const SizedBox(width: 20),
              _legend(
                AppColors.success,
                'Physical',
                '${(physPct * 100).toStringAsFixed(1)}%',
                textSecondary,
              ),
              const SizedBox(width: 20),
              _legend(
                AppColors.warning,
                'Investments',
                '${(invPct * 100).toStringAsFixed(1)}%',
                textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label, String pct, Color textColor) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Text('$label $pct', style: TextStyle(fontSize: 11, color: textColor)),
    ],
  );
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final int total;
  final Color color;
  final IconData icon;
  final Color surface, textPrimary, textSecondary, textTertiary;
  final bool isDark;
  final bool totalIsNegative;
  final List<Widget> children;
  final String emptyText;

  const _SectionCard({
    required this.title,
    required this.total,
    required this.color,
    required this.icon,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.isDark,
    required this.emptyText,
    this.totalIsNegative = false,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
              Text(
                totalIsNegative ? '−${_fmt(total)}' : _fmt(total),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: totalIsNegative ? AppColors.error : color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            ...children,
          ] else if (emptyText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              emptyText,
              style: TextStyle(fontSize: 12, color: textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(int minor) {
    final v = minor.abs() / 100;
    if (v >= 1000000) return 'KES ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return 'KES ${(v / 1000).toStringAsFixed(1)}K';
    return 'KES ${v.toStringAsFixed(0)}';
  }
}

// ── Row item ──────────────────────────────────────────────────────────────────

class _RowItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color dot;
  final String? sub;
  final Color? subColor;
  final Color textPrimary, textSecondary;
  final bool isDark;

  const _RowItem({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.dot,
    this.sub,
    this.subColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: TextStyle(
                      fontSize: 10,
                      color: subColor ?? textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
