import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:keel/core/di/injector.dart';
import 'package:keel/core/theme/app_colors.dart';
import 'package:keel/features/assets/domain/entities/asset.dart';
import 'package:keel/features/investments/domain/entities/holding.dart';
import 'package:keel/features/loans/domain/entities/loan.dart';
import 'package:keel/features/reports/presentation/bloc/reports_cubit.dart';
import 'package:keel/features/reports/presentation/pdf/keel_pdf_exporter.dart';
import 'package:keel/core/widgets/page_shell.dart';
import 'package:keel/core/widgets/shimmer.dart';

enum _Report { pnl, budget, loans, investments, assets }

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  _Report _active = _Report.pnl;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReportsCubit>()..load(),
      child: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) => _build(context, state),
      ),
    );
  }

  Widget _build(BuildContext context, ReportsState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textTertiary = isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
    final divider = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      color: bg,
      padding: const EdgeInsets.only(top: kTitleBarHeight),
      child: Column(children: [
        // ── Top bar ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(children: [
            Text('Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                color: textPrimary, letterSpacing: -0.3)),
            const Spacer(),
            if (state.maybeMap(loaded: (_) => true, orElse: () => false)) ...[
              _ExportButton(
                label: 'Export CSV',
                icon: Icons.table_chart_outlined,
                onTap: () => _exportCurrent(context, state),
              ),
              const SizedBox(width: 8),
              _ExportButton(
                label: 'Executive Dossier',
                icon: Icons.auto_awesome_outlined,
                onTap: () => context.read<ReportsCubit>().exportComprehensivePdf(),
              ),
              const SizedBox(width: 8),
              _ExportButton(
                label: 'Export PDF',
                icon: Icons.picture_as_pdf_outlined,
                onTap: () => _exportPdf(context, state),
              ),
              const SizedBox(width: 12),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.read<ReportsCubit>().load(),
                  behavior: HitTestBehavior.opaque,
                  child: Row(children: [
                    Icon(Icons.refresh, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text('Refresh', style: TextStyle(fontSize: 12, color: textSecondary)),
                  ]),
                ),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 16),

        // ── Tabs ─────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _Report.values.map((r) {
              final isActive = r == _active;
              return GestureDetector(
                onTap: () => setState(() => _active = r),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.royalBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(_icon(r), size: 13,
                        color: isActive ? Colors.white : textSecondary),
                    const SizedBox(width: 6),
                    Text(_label(r), style: TextStyle(fontSize: 12,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? Colors.white : textSecondary)),
                  ]),
                ),
              );
            }).toList()),
          ),
        ),
        Divider(height: 17, color: divider),

        // ── Content ──────────────────────────────────────────────────────────
        Expanded(
          child: state.when(
            initial: () => const SizedBox.shrink(),
            loading: () => const PanelShimmer(),
            error: (msg) => Center(child: Text(msg,
                style: const TextStyle(color: AppColors.error))),
            loaded: (pnl, categories, payees, budget, loans, holdings, assets, accounts, allEntries, accountBalances) =>
                switch (_active) {
                  _Report.pnl => _PnLReport(data: pnl, categories: categories,
                      payees: payees, isDark: isDark, surface: surface,
                      textPrimary: textPrimary, textSecondary: textSecondary,
                      textTertiary: textTertiary, divider: divider),
                  _Report.budget => _BudgetReport(data: budget, isDark: isDark,
                      surface: surface, textPrimary: textPrimary,
                      textSecondary: textSecondary, textTertiary: textTertiary,
                      divider: divider),
                  _Report.loans => _LoansReport(data: loans, isDark: isDark,
                      surface: surface, textPrimary: textPrimary,
                      textSecondary: textSecondary, textTertiary: textTertiary,
                      divider: divider),
                  _Report.investments => _InvestmentsReport(holdings: holdings,
                      isDark: isDark, surface: surface, textPrimary: textPrimary,
                      textSecondary: textSecondary, textTertiary: textTertiary,
                      divider: divider),
                  _Report.assets => _AssetsReport(assets: assets, isDark: isDark,
                      surface: surface, textPrimary: textPrimary,
                      textSecondary: textSecondary, textTertiary: textTertiary,
                      divider: divider),
                },
          ),
        ),
      ]),
    );
  }

  void _exportCurrent(BuildContext context, ReportsState state) {
    final cubit = context.read<ReportsCubit>();
    state.maybeMap(
      loaded: (s) async {
        List<List<String>> rows = [];
        String name = '';
        switch (_active) {
          case _Report.pnl:
            name = 'income_expense';
            rows = [
              ['Month', 'Income (KES)', 'Expenses (KES)', 'Net (KES)', 'Savings Rate'],
              ...s.monthlyPnL.map((d) => [
                _longMonth(d.period),
                _fmtRaw(d.incomeMinor),
                _fmtRaw(d.expensesMinor),
                _fmtRaw(d.netMinor),
                '${(d.savingsRate * 100).toStringAsFixed(1)}%',
              ]),
            ];
          case _Report.budget:
            name = 'budget_vs_actual';
            rows = [
              ['Period', 'Category', 'Bucket', 'Planned (KES)', 'Actual (KES)', 'Variance (KES)', 'Status'],
              for (final b in s.budgetVsActual)
                for (final l in b.lines)
                  [_longMonth(b.period), l.accountName, l.bucket,
                   _fmtRaw(l.plannedMinor), _fmtRaw(l.actualMinor),
                   _fmtRaw(l.varianceMinor), l.isUnder ? 'Under' : 'Over'],
            ];
          case _Report.loans:
            name = 'loans';
            rows = [
              ['Counterparty', 'Direction', 'Principal (KES)', 'Outstanding (KES)',
               'Interest Paid (KES)', 'Total Interest (KES)', 'Remaining Months', 'Status'],
              ...s.loanRows.map((r) => [
                r.loan.counterparty,
                r.loan.direction.name,
                _fmtRaw(r.loan.principalMinor),
                _fmtRaw(r.summary.outstandingMinor),
                _fmtRaw(r.summary.interestPaidMinor),
                _fmtRaw(r.summary.totalInterestMinor),
                '${r.summary.remainingMonths}',
                r.loan.status.name,
              ]),
            ];
          case _Report.investments:
            name = 'investments';
            rows = [
              ['Holding', 'Type', 'Institution', 'Cost Basis (KES)', 'Market Value (KES)',
               'Unrealised Gain (KES)', 'Unrealised %', 'Realised Gain (KES)', 'Income (KES)'],
              ...s.holdings.map((h) => [
                h.name, h.type.label, h.institution,
                _fmtRaw(h.totalCostBasisMinor),
                _fmtRaw(h.marketValueMinor),
                _fmtRaw(h.unrealisedGainMinor),
                '${h.unrealisedGainPct.toStringAsFixed(2)}%',
                _fmtRaw(h.realisedGainMinor),
                _fmtRaw(h.totalIncomeMinor),
              ]),
            ];
          case _Report.assets:
            name = 'assets';
            rows = [
              ['Name', 'Class', 'Acquisition Date', 'Cost (KES)', 'Book Value (KES)',
               'Gain/Loss (KES)', 'Status', 'Location'],
              ...s.assets.map((a) => [
                a.name, _classLabel(a.assetClass),
                _fmtDate(a.acquisitionDate),
                _fmtRaw(a.costMinor),
                _fmtRaw(a.bookValue),
                _fmtRaw(a.bookValue - a.costMinor),
                a.status.name,
                a.location ?? '',
              ]),
            ];
        }
        final path = await cubit.exportCsv(name, rows);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(path != null ? 'Exported to $path' : 'Export cancelled'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: path != null ? AppColors.success : AppColors.error,
          ));
        }
      },
      orElse: () {},
    );
  }

  void _exportPdf(BuildContext context, ReportsState state) {
    final cubit = context.read<ReportsCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf_outlined, color: AppColors.royalBlue, size: 22),
            const SizedBox(width: 10),
            Text('Export PDF Report',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select the scope of the generated financial statement:',
                  style: TextStyle(fontSize: 12, color: textSecondary)),
              const SizedBox(height: 16),

              // Option 1: Comprehensive Financial Dossier
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  cubit.exportComprehensivePdf();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.royalBlue, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Comprehensive Financial Dossier',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.royalBlue,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('RECOMMENDED',
                                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Complete 5-page executive dossier: Balance Sheet, Income Statement, Cash Flow trends & dual-bar chart, Budget variance, Debt schedule, Investment portfolio, and diagnostic health insights.',
                              style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Option 2: Active Tab Detailed Statement
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  cubit.exportDomainPdf(_toDomain(_active));
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_icon(_active), color: AppColors.royalBlue, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Detailed ${_label(_active)} Statement',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                            const SizedBox(height: 4),
                            Text(
                              'Focused report for ${_label(_active)} featuring domain vector graphs, month-over-month trends, structured accounting statements, and analytical commentary.',
                              style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  ReportDomain _toDomain(_Report r) => switch (r) {
        _Report.pnl => ReportDomain.pnl,
        _Report.budget => ReportDomain.budget,
        _Report.loans => ReportDomain.loans,
        _Report.investments => ReportDomain.investments,
        _Report.assets => ReportDomain.assets,
      };

  String _label(_Report r) => switch (r) {
        _Report.pnl => 'Income & Expense',
        _Report.budget => 'Budget vs Actual',
        _Report.loans => 'Loans',
        _Report.investments => 'Investments',
        _Report.assets => 'Assets',
      };

  IconData _icon(_Report r) => switch (r) {
        _Report.pnl => Icons.bar_chart_outlined,
        _Report.budget => Icons.pie_chart_outline,
        _Report.loans => Icons.credit_card_outlined,
        _Report.investments => Icons.show_chart_outlined,
        _Report.assets => Icons.home_outlined,
      };
}

// ── P&L Report ────────────────────────────────────────────────────────────────

class _PnLReport extends StatelessWidget {
  final List<MonthlyPnL> data;
  final List<ExpenseCategory> categories;
  final List<PayeeRow> payees;
  final bool isDark;
  final Color surface, textPrimary, textSecondary, textTertiary, divider;

  const _PnLReport({required this.data, required this.categories,
      required this.payees, required this.isDark, required this.surface,
      required this.textPrimary, required this.textSecondary,
      required this.textTertiary, required this.divider});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _empty('No income or expense data yet.', textTertiary);

    final totalIncome = data.fold<int>(0, (s, d) => s + d.incomeMinor);
    final totalExpenses = data.fold<int>(0, (s, d) => s + d.expensesMinor);
    final totalNet = totalIncome - totalExpenses;
    final avgSavingsRate = data.where((d) => d.incomeMinor > 0).isEmpty
        ? 0.0
        : data.where((d) => d.incomeMinor > 0)
              .map((d) => d.savingsRate)
              .reduce((a, b) => a + b) /
            data.where((d) => d.incomeMinor > 0).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // KPIs
        Row(children: [
          _kpi('12-MO INCOME', _fmt(totalIncome), AppColors.success, textSecondary, surface),
          const SizedBox(width: 10),
          _kpi('12-MO EXPENSES', _fmt(totalExpenses), AppColors.error, textSecondary, surface),
          const SizedBox(width: 10),
          _kpi('NET SAVINGS', '${totalNet >= 0 ? '+' : ''}${_fmt(totalNet)}',
              totalNet >= 0 ? AppColors.success : AppColors.error, textSecondary, surface),
          const SizedBox(width: 10),
          _kpi('AVG SAVINGS RATE', '${(avgSavingsRate * 100).toStringAsFixed(1)}%',
              avgSavingsRate >= 0.2 ? AppColors.success : AppColors.warning,
              textSecondary, surface),
        ]),
        const SizedBox(height: 16),

        // Chart
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('12-month income vs expenses',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary)),
              const Spacer(),
              _legend(AppColors.success, 'Income', textTertiary),
              const SizedBox(width: 12),
              _legend(AppColors.error, 'Expenses', textTertiary),
              const SizedBox(width: 12),
              _legend(AppColors.royalBlue, 'Net', textTertiary),
            ]),
            const SizedBox(height: 16),
            SizedBox(height: 160,
                child: CustomPaint(size: const Size(double.infinity, 160),
                    painter: _PnLChartPainter(data: data, isDark: isDark))),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: data.map((d) => Text(_shortMonth(d.period),
                    style: TextStyle(fontSize: 9, color: textTertiary))).toList()),
          ]),
        ),
        const SizedBox(height: 16),

        // Two columns: categories + payees
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Expense categories
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionLabel('TOP EXPENSE CATEGORIES', textTertiary),
            const SizedBox(height: 10),
            if (categories.isEmpty)
              _emptyCard('No expense data.', surface, textTertiary)
            else
              Container(
                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
                child: Column(children: categories.take(8).toList().asMap().entries.map((e) {
                  final cat = e.value;
                  final pct = totalExpenses > 0 ? cat.totalMinor / totalExpenses : 0.0;
                  final isLast = e.key == min(7, categories.length - 1);
                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Column(children: [
                        Row(children: [
                          Expanded(child: Text(cat.accountName,
                              style: TextStyle(fontSize: 12, color: textPrimary),
                              maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Text(_fmt(cat.totalMinor),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                  fontFeatures: const [FontFeature.tabularFigures()])),
                          const SizedBox(width: 8),
                          Text('${(pct * 100).toStringAsFixed(0)}%',
                              style: TextStyle(fontSize: 10, color: textTertiary)),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(value: pct, minHeight: 4,
                            backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            valueColor: const AlwaysStoppedAnimation(AppColors.error))),
                      ]),
                    ),
                    if (!isLast) Divider(height: 1,
                        color: divider.withValues(alpha: 0.5), indent: 14, endIndent: 14),
                  ]);
                }).toList()),
              ),
          ])),
          const SizedBox(width: 16),

          // Top payees
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionLabel('TOP PAYEES / MERCHANTS', textTertiary),
            const SizedBox(height: 10),
            if (payees.isEmpty)
              _emptyCard('No payee data.', surface, textTertiary)
            else
              Container(
                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
                child: Column(children: payees.asMap().entries.map((e) {
                  final p = e.value;
                  final isLast = e.key == payees.length - 1;
                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(children: [
                        Container(width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.royalBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(7)),
                          child: Center(child: Text(
                            p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                color: AppColors.royalBlue)))),
                        const SizedBox(width: 10),
                        Expanded(child: Text(p.name,
                            style: TextStyle(fontSize: 12, color: textPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Text(_fmt(p.totalMinor),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                color: textPrimary,
                                fontFeatures: const [FontFeature.tabularFigures()])),
                      ]),
                    ),
                    if (!isLast) Divider(height: 1,
                        color: divider.withValues(alpha: 0.5), indent: 14, endIndent: 14),
                  ]);
                }).toList()),
              ),
          ])),
        ]),
        const SizedBox(height: 16),

        // Monthly table
        _sectionLabel('MONTHLY DETAIL', textTertiary),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            _tableHeader(['Month', 'Income', 'Expenses', 'Net', 'Savings Rate'],
                textTertiary, divider),
            ...data.reversed.map((d) {
              final net = d.netMinor;
              final isLast = d == data.first;
              return _tableRow([
                _longMonth(d.period),
                _fmt(d.incomeMinor),
                _fmt(d.expensesMinor),
                '${net >= 0 ? '+' : ''}${_fmt(net)}',
                '${(d.savingsRate * 100).toStringAsFixed(1)}%',
              ], [
                textPrimary, AppColors.success, AppColors.error,
                net >= 0 ? AppColors.success : AppColors.error,
                d.savingsRate >= 0.2 ? AppColors.success : AppColors.warning,
              ], divider, isLast);
            }),
          ]),
        ),
      ]),
    );
  }
}

// ── Budget vs Actual Report ───────────────────────────────────────────────────

class _BudgetReport extends StatefulWidget {
  final List<BudgetVsActual> data;
  final bool isDark;
  final Color surface, textPrimary, textSecondary, textTertiary, divider;
  const _BudgetReport({required this.data, required this.isDark,
      required this.surface, required this.textPrimary,
      required this.textSecondary, required this.textTertiary, required this.divider});
  @override
  State<_BudgetReport> createState() => _BudgetReportState();
}

class _BudgetReportState extends State<_BudgetReport> {
  String? _expandedPeriod;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return _empty('No budget plans found.', widget.textTertiary);

    final totalPlanned = widget.data.fold<int>(0, (s, d) => s + d.plannedMinor);
    final totalActual = widget.data.fold<int>(0, (s, d) => s + d.actualMinor);
    final totalVariance = totalPlanned - totalActual;
    final periodsUnder = widget.data.where((d) => d.isUnder).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _kpi('TOTAL PLANNED', _fmt(totalPlanned), AppColors.royalBlue,
              widget.textSecondary, widget.surface),
          const SizedBox(width: 10),
          _kpi('TOTAL ACTUAL', _fmt(totalActual), AppColors.warning,
              widget.textSecondary, widget.surface),
          const SizedBox(width: 10),
          _kpi(totalVariance >= 0 ? 'TOTAL SAVED' : 'TOTAL OVERSPEND',
              '${totalVariance >= 0 ? '+' : ''}${_fmt(totalVariance)}',
              totalVariance >= 0 ? AppColors.success : AppColors.error,
              widget.textSecondary, widget.surface),
          const SizedBox(width: 10),
          _kpi('MONTHS UNDER BUDGET', '$periodsUnder / ${widget.data.length}',
              periodsUnder == widget.data.length ? AppColors.success : AppColors.warning,
              widget.textSecondary, widget.surface),
        ]),
        const SizedBox(height: 16),

        // Period cards with expandable line breakdown
        ...widget.data.reversed.map((d) {
          final isExpanded = _expandedPeriod == d.period;
          final usedPct = d.plannedMinor > 0
              ? (d.actualMinor / d.plannedMinor).clamp(0.0, 1.5)
              : 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: widget.surface,
                borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              // Period header
              InkWell(
                onTap: () => setState(() =>
                    _expandedPeriod = isExpanded ? null : d.period),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Row(children: [
                      Text(_longMonth(d.period),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                              color: widget.textPrimary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (d.isUnder ? AppColors.success : AppColors.error)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(d.isUnder ? 'Under budget' : 'Over budget',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                color: d.isUnder ? AppColors.success : AppColors.error)),
                      ),
                      const SizedBox(width: 8),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 16, color: widget.textSecondary),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('${(usedPct * 100).toStringAsFixed(0)}% of budget used',
                              style: TextStyle(fontSize: 11, color: widget.textSecondary)),
                          Text('${_fmt(d.actualMinor)} / ${_fmt(d.plannedMinor)}',
                              style: TextStyle(fontSize: 11, color: widget.textTertiary)),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: usedPct.clamp(0.0, 1.0), minHeight: 6,
                            backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            valueColor: AlwaysStoppedAnimation(
                                usedPct > 1.0 ? AppColors.error
                                    : usedPct > 0.85 ? AppColors.warning
                                    : AppColors.success),
                          )),
                      ])),
                    ]),
                  ]),
                ),
              ),

              // Line breakdown
              if (isExpanded && d.lines.isNotEmpty) ...[
                Divider(height: 1, color: widget.divider.withValues(alpha: 0.5)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Row(children: [
                    Expanded(flex: 3, child: Text('Category',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: widget.textTertiary, letterSpacing: 0.5))),
                    Expanded(child: Text('Planned', textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: widget.textTertiary, letterSpacing: 0.5))),
                    Expanded(child: Text('Actual', textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: widget.textTertiary, letterSpacing: 0.5))),
                    Expanded(child: Text('Variance', textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: widget.textTertiary, letterSpacing: 0.5))),
                  ]),
                ),
                ...d.lines.asMap().entries.map((e) {
                  final l = e.value;
                  final isLast = e.key == d.lines.length - 1;
                  return Column(children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(children: [
                        Expanded(flex: 3, child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.accountName,
                              style: TextStyle(fontSize: 12, color: widget.textPrimary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ClipRRect(borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: l.usedPct.clamp(0.0, 1.0), minHeight: 3,
                              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              valueColor: AlwaysStoppedAnimation(
                                  l.usedPct > 1.0 ? AppColors.error
                                      : l.usedPct > 0.85 ? AppColors.warning
                                      : AppColors.success))),
                        ])),
                        Expanded(child: Text(_fmt(l.plannedMinor), textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 11, color: widget.textSecondary,
                                fontFeatures: const [FontFeature.tabularFigures()]))),
                        Expanded(child: Text(_fmt(l.actualMinor), textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 11, color: widget.textPrimary,
                                fontFeatures: const [FontFeature.tabularFigures()]))),
                        Expanded(child: Text(
                            '${l.varianceMinor >= 0 ? '+' : ''}${_fmt(l.varianceMinor)}',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: l.isUnder ? AppColors.success : AppColors.error,
                                fontFeatures: const [FontFeature.tabularFigures()]))),
                      ]),
                    ),
                    if (!isLast) Divider(height: 1,
                        color: widget.divider.withValues(alpha: 0.3),
                        indent: 16, endIndent: 16),
                  ]);
                }),
                const SizedBox(height: 8),
              ],
            ]),
          );
        }),
      ]),
    );
  }

  bool get isDark => widget.isDark;
}

// ── Loans Report ──────────────────────────────────────────────────────────────

class _LoansReport extends StatelessWidget {
  final List<LoanReportRow> data;
  final bool isDark;
  final Color surface, textPrimary, textSecondary, textTertiary, divider;
  const _LoansReport({required this.data, required this.isDark,
      required this.surface, required this.textPrimary,
      required this.textSecondary, required this.textTertiary, required this.divider});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _empty('No loans recorded.', textTertiary);

    final borrowed = data.where((r) => r.loan.direction == LoanDirection.borrowed).toList();
    final lent = data.where((r) => r.loan.direction == LoanDirection.lent).toList();
    final totalOutstanding = borrowed.fold<int>(0, (s, r) => s + r.summary.outstandingMinor);
    final totalInterestPaid = borrowed.fold<int>(0, (s, r) => s + r.summary.interestPaidMinor);
    final totalCostOfBorrowing = borrowed.fold<int>(0, (s, r) => s + r.totalCostMinor);
    final totalLent = lent.fold<int>(0, (s, r) => s + r.summary.outstandingMinor);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _kpi('TOTAL OUTSTANDING', _fmt(totalOutstanding), AppColors.error, textSecondary, surface),
          const SizedBox(width: 10),
          _kpi('INTEREST PAID', _fmt(totalInterestPaid), AppColors.warning, textSecondary, surface),
          const SizedBox(width: 10),
          _kpi('TOTAL COST OF BORROWING', _fmt(totalCostOfBorrowing),
              AppColors.error, textSecondary, surface),
          const SizedBox(width: 10),
          _kpi('TOTAL LENT OUT', _fmt(totalLent), AppColors.success, textSecondary, surface),
        ]),
        const SizedBox(height: 16),

        // Loan cards
        ...data.map((r) {
          final isBorrowed = r.loan.direction == LoanDirection.borrowed;
          final paidPct = r.loan.principalMinor > 0
              ? (r.summary.principalPaidMinor / r.loan.principalMinor).clamp(0.0, 1.0)
              : 0.0;
          final color = isBorrowed ? AppColors.error : AppColors.success;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9)),
                  child: Icon(Icons.credit_card_outlined, size: 18, color: color)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.loan.counterparty,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: textPrimary)),
                  Text('${isBorrowed ? 'Borrowed' : 'Lent'} · '
                      '${(r.loan.annualRateBp / 100).toStringAsFixed(1)}% p.a. · '
                      '${r.loan.termMonths} months',
                      style: TextStyle(fontSize: 11, color: textSecondary)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(_fmt(r.summary.outstandingMinor),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                          color: color, fontFeatures: const [FontFeature.tabularFigures()])),
                  Text('outstanding', style: TextStyle(fontSize: 10, color: textTertiary)),
                ]),
              ]),
              const SizedBox(height: 14),

              // Progress bar
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${(paidPct * 100).toStringAsFixed(0)}% repaid',
                    style: TextStyle(fontSize: 11, color: textSecondary)),
                Text('${r.summary.remainingMonths} months remaining',
                    style: TextStyle(fontSize: 11, color: textSecondary)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: paidPct, minHeight: 6,
                  backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  valueColor: AlwaysStoppedAnimation(color))),
              const SizedBox(height: 14),

              // Stats grid
              Row(children: [
                _loanStat('Principal', _fmt(r.loan.principalMinor), textPrimary, textTertiary),
                _loanStat('Paid', _fmt(r.summary.totalPaidMinor), AppColors.success, textTertiary),
                _loanStat('Interest paid', _fmt(r.summary.interestPaidMinor), AppColors.warning, textTertiary),
                _loanStat('Total interest', _fmt(r.summary.totalInterestMinor), AppColors.warning, textTertiary),
                _loanStat('Total cost', _fmt(r.totalCostMinor), color, textTertiary),
              ]),

              if (r.summary.isOverdue) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.errorSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_outlined, size: 13, color: AppColors.error),
                    const SizedBox(width: 6),
                    Text('${r.summary.daysOverdue} days overdue · '
                        '${r.summary.missedPayments} missed payment${r.summary.missedPayments != 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 11, color: AppColors.error,
                            fontWeight: FontWeight.w500)),
                  ]),
                ),
              ],
            ]),
          );
        }),
      ]),
    );
  }

  Widget _loanStat(String label, String value, Color valueColor, Color labelColor) =>
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 9, color: labelColor, letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: valueColor, fontFeatures: const [FontFeature.tabularFigures()])),
      ]));
}

// ── Investments Report ────────────────────────────────────────────────────────

class _InvestmentsReport extends StatelessWidget {
  final List<Holding> holdings;
  final bool isDark;
  final Color surface, textPrimary, textSecondary, textTertiary, divider;
  const _InvestmentsReport({required this.holdings, required this.isDark,
      required this.surface, required this.textPrimary,
      required this.textSecondary, required this.textTertiary, required this.divider});

  @override
  Widget build(BuildContext context) {
    if (holdings.isEmpty) return _empty('No investments recorded.', textTertiary);

    int totalCost = 0, totalMarket = 0, totalRealised = 0, totalIncome = 0;
    for (final h in holdings) {
      totalCost += h.totalCostBasisMinor;
      totalMarket += h.marketValueMinor;
      totalRealised += h.realisedGainMinor;
      totalIncome += h.totalIncomeMinor;
    }
    final totalUnrealised = totalMarket - totalCost;
    final totalReturn = totalUnrealised + totalRealised + totalIncome;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _kpi('TOTAL INVESTED', _fmt(totalCost), textPrimary, textSecondary, surface),
          const SizedBox(width: 10),
          _kpi('MARKET VALUE', _fmt(totalMarket), AppColors.royalBlue, textSecondary, surface),
          const SizedBox(width: 10),
          _kpi('UNREALISED', '${totalUnrealised >= 0 ? '+' : ''}${_fmt(totalUnrealised)}',
              totalUnrealised >= 0 ? AppColors.success : AppColors.error, textSecondary, surface),
          const SizedBox(width: 10),
          _kpi('TOTAL RETURN', '${totalReturn >= 0 ? '+' : ''}${_fmt(totalReturn)}',
              totalReturn >= 0 ? AppColors.success : AppColors.error, textSecondary, surface),
        ]),
        const SizedBox(height: 16),

        // Holding cards
        ...holdings.map((h) {
          final gain = h.unrealisedGainMinor;
          final gainColor = gain >= 0 ? AppColors.success : AppColors.error;
          final pct = h.totalCostBasisMinor > 0
              ? (h.marketValueMinor / h.totalCostBasisMinor).clamp(0.0, 2.0) / 2.0
              : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.show_chart_outlined, size: 18,
                      color: AppColors.royalBlue)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(h.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: textPrimary)),
                  Text('${h.type.label} · ${h.institution}',
                      style: TextStyle(fontSize: 11, color: textSecondary)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(_fmt(h.marketValueMinor),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                          color: textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                  Text('${gain >= 0 ? '+' : ''}${h.unrealisedGainPct.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 11, color: gainColor)),
                ]),
              ]),
              const SizedBox(height: 12),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: pct, minHeight: 5,
                  backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  valueColor: AlwaysStoppedAnimation(gainColor))),
              const SizedBox(height: 12),
              Row(children: [
                _invStat('Cost basis', _fmt(h.totalCostBasisMinor), textPrimary, textTertiary),
                if (h.type.hasUnits)
                  _invStat('Units', h.totalUnits.toStringAsFixed(2), textPrimary, textTertiary),
                _invStat('Unrealised', '${gain >= 0 ? '+' : ''}${_fmt(gain)}',
                    gainColor, textTertiary),
                _invStat('Realised', '${h.realisedGainMinor >= 0 ? '+' : ''}${_fmt(h.realisedGainMinor)}',
                    h.realisedGainMinor >= 0 ? AppColors.success : AppColors.error, textTertiary),
                _invStat('Income', '+${_fmt(h.totalIncomeMinor)}', AppColors.success, textTertiary),
              ]),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _invStat(String label, String value, Color valueColor, Color labelColor) =>
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 9, color: labelColor, letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: valueColor, fontFeatures: const [FontFeature.tabularFigures()])),
      ]));
}

// ── Assets Report ─────────────────────────────────────────────────────────────

class _AssetsReport extends StatelessWidget {
  final List<Asset> assets;
  final bool isDark;
  final Color surface, textPrimary, textSecondary, textTertiary, divider;
  const _AssetsReport({required this.assets, required this.isDark,
      required this.surface, required this.textPrimary,
      required this.textSecondary, required this.textTertiary, required this.divider});

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) return _empty('No physical assets recorded.', textTertiary);

    final totalCost = assets.fold<int>(0, (s, a) => s + a.costMinor);
    final totalBook = assets.fold<int>(0, (s, a) => s + a.bookValue);
    final totalGain = totalBook - totalCost;
    final now = DateTime.now();
    final insured = assets.where((a) =>
        a.insuranceExpiry != null && a.insuranceExpiry!.isAfter(now)).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _kpi('TOTAL COST', _fmt(totalCost), textPrimary, textSecondary, surface),
          const SizedBox(width: 10),
          _kpi('BOOK VALUE', _fmt(totalBook), AppColors.royalBlue, textSecondary, surface),
          const SizedBox(width: 10),
          _kpi(totalGain >= 0 ? 'UNREALISED GAIN' : 'UNREALISED LOSS',
              '${totalGain >= 0 ? '+' : ''}${_fmt(totalGain)}',
              totalGain >= 0 ? AppColors.success : AppColors.error, textSecondary, surface),
          const SizedBox(width: 10),
          _kpi('INSURED', '$insured / ${assets.length}',
              insured == assets.length ? AppColors.success : AppColors.warning,
              textSecondary, surface),
        ]),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            _tableHeader(['Asset', 'Class', 'Cost', 'Book Value', 'Gain/Loss', 'Status'],
                textTertiary, divider),
            ...assets.asMap().entries.map((e) {
              final a = e.value;
              final gl = a.bookValue - a.costMinor;
              return _tableRow([
                a.name, _classLabel(a.assetClass),
                _fmt(a.costMinor), _fmt(a.bookValue),
                '${gl >= 0 ? '+' : ''}${_fmt(gl)}',
                a.status == AssetStatus.inUse ? 'In Use'
                    : a.status == AssetStatus.sold ? 'Sold' : 'Written Off',
              ], [
                textPrimary, textSecondary, textPrimary, AppColors.royalBlue,
                gl >= 0 ? AppColors.success : AppColors.error,
                a.status == AssetStatus.inUse ? AppColors.success : textSecondary,
              ], divider, e.key == assets.length - 1);
            }),
          ]),
        ),
      ]),
    );
  }
}

// ── Export button ─────────────────────────────────────────────────────────────

class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ExportButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.royalBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: AppColors.royalBlue),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.royalBlue,
                fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Widget _empty(String msg, Color color) =>
    Center(child: Text(msg, style: TextStyle(fontSize: 13, color: color)));

Widget _emptyCard(String msg, Color surface, Color color) =>
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
      child: Text(msg, style: TextStyle(fontSize: 12, color: color)),
    );

Widget _sectionLabel(String text, Color color) => Text(text,
    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
        color: color, letterSpacing: 0.8));

Widget _kpi(String label, String value, Color valueColor, Color labelColor, Color surface) =>
    Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
              color: labelColor, letterSpacing: 0.4)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: valueColor, fontFeatures: const [FontFeature.tabularFigures()])),
        ]),
      ),
    );

Widget _legend(Color color, String label, Color textColor) =>
    Row(children: [
      Container(width: 8, height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10, color: textColor)),
    ]);

Widget _tableHeader(List<String> cols, Color color, Color divider) =>
    Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: cols.map((c) => Expanded(
          child: Text(c, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: color, letterSpacing: 0.5)),
        )).toList()),
      ),
      Divider(height: 1, color: divider),
    ]);

Widget _tableRow(List<String> cells, List<Color> colors, Color divider, bool isLast) =>
    Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: List.generate(cells.length, (i) => Expanded(
          child: Text(cells[i],
              style: TextStyle(fontSize: 12, color: colors[i],
                  fontFeatures: const [FontFeature.tabularFigures()]),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ))),
      ),
      if (!isLast) Divider(height: 1,
          color: divider.withValues(alpha: 0.5), indent: 16, endIndent: 16),
    ]);

String _fmt(int minor) {
  final v = minor.abs() / 100;
  final p = minor < 0 ? '−' : '';
  if (v >= 1000000) return '${p}KES ${(v / 1000000).toStringAsFixed(2)}M';
  if (v >= 1000) return '${p}KES ${(v / 1000).toStringAsFixed(1)}K';
  return '${p}KES ${v.toStringAsFixed(0)}';
}

String _fmtRaw(int minor) => (minor / 100).toStringAsFixed(2);

String _shortMonth(String period) {
  const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return m[int.parse(period.split('-')[1])];
}

String _longMonth(String period) {
  const m = ['', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
  final parts = period.split('-');
  return '${m[int.parse(parts[1])]} ${parts[0]}';
}

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

String _fmtDate(DateTime d) {
  const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${m[d.month]} ${d.year}';
}

// ── P&L chart painter ─────────────────────────────────────────────────────────

class _PnLChartPainter extends CustomPainter {
  final List<MonthlyPnL> data;
  final bool isDark;
  _PnLChartPainter({required this.data, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.fold(0.0, (m, d) =>
        max(m, max(d.incomeMinor.toDouble(), d.expensesMinor.toDouble())));
    if (maxVal == 0) return;

    final gridPaint = Paint()
      ..color = (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (int i = 1; i <= 4; i++) {
      final y = size.height * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final gw = size.width / data.length;
    final bw = gw * 0.26;
    final gap = gw * 0.04;

    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      final cx = gw * i + gw / 2;
      final incH = (d.incomeMinor / maxVal) * size.height;
      final expH = (d.expensesMinor / maxVal) * size.height;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - bw - gap / 2, size.height - incH, bw, incH),
          topLeft: const Radius.circular(3), topRight: const Radius.circular(3)),
        Paint()..color = AppColors.success.withValues(alpha: 0.8)..style = PaintingStyle.fill);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx + gap / 2, size.height - expH, bw, expH),
          topLeft: const Radius.circular(3), topRight: const Radius.circular(3)),
        Paint()..color = AppColors.error.withValues(alpha: 0.7)..style = PaintingStyle.fill);
    }

    // Net savings line
    final netPts = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      final cx = gw * i + gw / 2;
      final netNorm = ((d.netMinor / maxVal) + 1) / 2; // normalise to 0-1 range
      final y = size.height * (1 - netNorm.clamp(0.0, 1.0));
      netPts.add(Offset(cx, y));
    }
    if (netPts.length >= 2) {
      final linePath = Path()..moveTo(netPts.first.dx, netPts.first.dy);
      for (int i = 1; i < netPts.length; i++) { linePath.lineTo(netPts[i].dx, netPts[i].dy); }
      canvas.drawPath(linePath, Paint()
        ..color = AppColors.royalBlue..strokeWidth = 2
        ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
      for (final p in netPts) {
        canvas.drawCircle(p, 3, Paint()..color = AppColors.royalBlue..style = PaintingStyle.fill);
      }
    }
  }

  @override
  bool shouldRepaint(_PnLChartPainter old) => old.data != data;
}
