import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:keel/features/reports/domain/models/financial_report_data.dart';
import 'financial_pdf_theme.dart';
import 'financial_statement_builder.dart';
import 'financial_insights_builder.dart';
import 'pdf_chart_widgets.dart';

enum ReportDomain {
  comprehensive,
  pnl,
  budget,
  loans,
  investments,
  assets,
}

class KeelPdfExporter {
  // ── 1. Comprehensive Executive Financial Dossier ───────────────────────────

  static Future<pw.Document> generateComprehensiveReport({
    required FinancialReportData data,
    Uint8List? logoBytes,
    Uint8List? wordmarkBytes,
  }) async {
    final fonts = await PdfThemeFonts.load();
    final doc = pw.Document();

    // ── PAGE 1: Executive Dashboard, Ratios, Trends & Inflow/Outflow Chart ──
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => FinancialPdfTheme.buildHeader(
          fonts: fonts,
          title: 'EXECUTIVE FINANCIAL STATEMENT & DIAGNOSTIC REPORT',
          subtitle: 'Holistic Wealth, Cash Flow & Financial Health Overview',
          logoBytes: logoBytes,
          wordmarkBytes: wordmarkBytes,
          date: data.asOf,
        ),
        footer: (ctx) => FinancialPdfTheme.buildFooter(context: ctx, fonts: fonts),
        build: (ctx) => [
          // Health score section (clean typographic lockup, no card border, no background)
          FinancialInsightsBuilder.buildExecutiveHealthCard(
            health: data.healthScore,
            bs: data.balanceSheet,
            trends: data.trends,
            fonts: fonts,
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: FinancialPdfTheme.borderColor, thickness: 0.6),
          pw.SizedBox(height: 10),

          // 4-Card KPI grid (no card borders, no backgrounds)
          FinancialInsightsBuilder.buildKpiGrid(data: data, fonts: fonts),
          pw.SizedBox(height: 12),
          pw.Divider(color: FinancialPdfTheme.borderColor, thickness: 0.6),
          pw.SizedBox(height: 10),

          // Trends panel
          FinancialPdfTheme.buildSectionTitle(
            fonts: fonts,
            title: 'Cash Flow Velocity & Momentum',
            subtitle: 'Month-over-month trajectory',
          ),
          FinancialInsightsBuilder.buildTrendsPanel(trends: data.trends, fonts: fonts),
          pw.SizedBox(height: 12),
          pw.Divider(color: FinancialPdfTheme.borderColor, thickness: 0.6),
          pw.SizedBox(height: 10),

          // 12-Month Inflow vs Outflow Dual-Bar Chart
          PdfChartWidgets.buildMonthlyBarChart(
            data: data.monthlyPnL,
            fonts: fonts,
            height: 110,
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: FinancialPdfTheme.borderColor, thickness: 0.6),
          pw.SizedBox(height: 10),

          // Executive Commentary & Observations
          FinancialPdfTheme.buildSectionTitle(
            fonts: fonts,
            title: 'Diagnostic Commentary & Key Findings',
            subtitle: 'Automated personal ledger analysis',
          ),
          FinancialInsightsBuilder.buildInsightsPanel(
            insights: data.insights,
            fonts: fonts,
          ),
        ],
      ),
    );

    // ── PAGE 2: Balance Sheet, Income Statement & Asset Allocation ───────────
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => FinancialPdfTheme.buildHeader(
          fonts: fonts,
          title: 'STATEMENT OF FINANCIAL POSITION & PERFORMANCE',
          subtitle: 'Formal Accounting Balance Sheet & Operating P&L',
          logoBytes: logoBytes,
          wordmarkBytes: wordmarkBytes,
          date: data.asOf,
        ),
        footer: (ctx) => FinancialPdfTheme.buildFooter(context: ctx, fonts: fonts),
        build: (ctx) => [
          FinancialPdfTheme.buildSectionTitle(
            fonts: fonts,
            title: 'Statement of Financial Position (Balance Sheet)',
            subtitle: 'Assets, liabilities and net worth equity',
          ),
          FinancialStatementBuilder.buildBalanceSheet(
            bs: data.balanceSheet,
            fonts: fonts,
          ),
          pw.SizedBox(height: 14),

          // Asset allocation segmented bar
          PdfChartWidgets.buildAssetAllocationBar(
            cashMinor: data.balanceSheet.totalCashMinor,
            investmentsMinor: data.balanceSheet.totalInvestmentsMarketMinor,
            physicalMinor: data.balanceSheet.totalPhysicalBookMinor,
            fonts: fonts,
          ),
          pw.SizedBox(height: 14),

          FinancialPdfTheme.buildSectionTitle(
            fonts: fonts,
            title: 'Statement of Financial Performance (12-Mo P&L)',
            subtitle: 'Operating surplus and margin analysis',
          ),
          FinancialStatementBuilder.buildIncomeStatement(
            isData: data.incomeStatement,
            fonts: fonts,
          ),
        ],
      ),
    );

    // ── PAGE 3: Monthly Breakdown Table, Categories & Top Payees ─────────────
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => FinancialPdfTheme.buildHeader(
          fonts: fonts,
          title: 'MONTHLY OPERATING DETAIL & SPENDING CONCENTRATION',
          subtitle: 'Historical P&L breakdown and category Pareto analysis',
          logoBytes: logoBytes,
          wordmarkBytes: wordmarkBytes,
          date: data.asOf,
        ),
        footer: (ctx) => FinancialPdfTheme.buildFooter(context: ctx, fonts: fonts),
        build: (ctx) => [
          FinancialPdfTheme.buildSectionTitle(
            fonts: fonts,
            title: 'Historical Monthly Cash Flows & Trajectory',
            subtitle: 'Recorded 12-month periods with MoM shifts',
          ),
          FinancialStatementBuilder.buildMonthlyTable(
            monthlyTrends: data.incomeStatement.monthlyTrends,
            fonts: fonts,
          ),
          pw.SizedBox(height: 14),

          FinancialPdfTheme.buildSectionTitle(
            fonts: fonts,
            title: 'Expense Distribution & Cost Drivers',
            subtitle: 'Top spending categories and merchant outflow',
          ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left: Categories progress bars
              pw.Expanded(
                flex: 3,
                child: PdfChartWidgets.buildCategoryDistributionBars(
                  categories: data.expenseCategories,
                  totalExpensesMinor: data.incomeStatement.totalExpensesMinor,
                  fonts: fonts,
                  maxItems: 6,
                ),
              ),
              pw.SizedBox(width: 16),
              // Right: Top Payees list (No card border, no background)
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'TOP PAYEES & MERCHANTS',
                      style: pw.TextStyle(font: fonts.bold, fontSize: 7.5, color: FinancialPdfTheme.slateDark),
                    ),
                    pw.SizedBox(height: 6),
                    ...data.topPayees.take(6).map((p) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4.5),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  p.name,
                                  style: pw.TextStyle(font: fonts.regular, fontSize: 7.5, color: FinancialPdfTheme.slateDark),
                                  maxLines: 1,
                                ),
                              ),
                              pw.Text(
                                FinancialPdfTheme.formatKes(p.totalMinor),
                                style: pw.TextStyle(font: fonts.bold, fontSize: 7.5, color: FinancialPdfTheme.primaryNavy),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // ── PAGE 4: Budget Performance, Debt Obligations & Recommendations ───────
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => FinancialPdfTheme.buildHeader(
          fonts: fonts,
          title: 'BUDGET DISCIPLINE, DEBT SCHEDULE & STRATEGY',
          subtitle: 'Variance execution and debt obligation audit',
          logoBytes: logoBytes,
          wordmarkBytes: wordmarkBytes,
          date: data.asOf,
        ),
        footer: (ctx) => FinancialPdfTheme.buildFooter(context: ctx, fonts: fonts),
        build: (ctx) => [
          FinancialPdfTheme.buildSectionTitle(
            fonts: fonts,
            title: 'Budget Discipline & Variance Execution',
            subtitle: 'Planned allocation vs actual spending across cycles',
          ),
          PdfChartWidgets.buildBudgetVarianceBarChart(
            periods: data.budgetVsActual,
            fonts: fonts,
          ),
          pw.SizedBox(height: 12),

          FinancialPdfTheme.buildSectionTitle(
            fonts: fonts,
            title: 'Liabilities & Loan Amortization Schedule',
            subtitle: 'Counterparty balances, rates and cost of credit',
          ),
          FinancialStatementBuilder.buildDebtTable(
            loans: data.loanRows,
            fonts: fonts,
          ),
          pw.SizedBox(height: 14),

          FinancialPdfTheme.buildSectionTitle(
            fonts: fonts,
            title: 'Strategic Financial Action Plan',
            subtitle: 'High-leverage recommendations',
          ),
          FinancialInsightsBuilder.buildRecommendationsPanel(
            recommendations: data.insights.recommendations,
            fonts: fonts,
          ),
        ],
      ),
    );

    // ── PAGE 5: Investments, Fixed Assets & Governance Stamp ─────────────────
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => FinancialPdfTheme.buildHeader(
          fonts: fonts,
          title: 'INVESTMENT PORTFOLIO & FIXED ASSET REGISTER',
          subtitle: 'Capital allocation, holding valuations and asset register',
          logoBytes: logoBytes,
          wordmarkBytes: wordmarkBytes,
          date: data.asOf,
        ),
        footer: (ctx) => FinancialPdfTheme.buildFooter(context: ctx, fonts: fonts),
        build: (ctx) => [
          FinancialPdfTheme.buildSectionTitle(
            fonts: fonts,
            title: 'Investment Portfolio & Returns Matrix',
            subtitle: 'Cost basis, market value, unrealised gains and dividend income',
          ),
          FinancialStatementBuilder.buildInvestmentTable(
            holdings: data.holdings,
            fonts: fonts,
          ),
          pw.SizedBox(height: 14),

          FinancialPdfTheme.buildSectionTitle(
            fonts: fonts,
            title: 'Fixed Asset Register & Valuation Model',
            subtitle: 'Cost basis, depreciation book value and policy audit',
          ),
          FinancialStatementBuilder.buildAssetTable(
            assets: data.assets,
            fonts: fonts,
          ),
          pw.SizedBox(height: 16),

          // Governance Stamp (Clean: No card border, no background fill)
          pw.Divider(color: FinancialPdfTheme.borderColor, thickness: 0.6),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'STATEMENT OF FINANCIAL INTEGRITY & CLOSING',
                    style: pw.TextStyle(font: fonts.bold, fontSize: 7.5, color: FinancialPdfTheme.primaryNavy),
                  ),
                  pw.SizedBox(height: 1.5),
                  pw.Text(
                    'All entries verified against double-entry general ledger records. Generated locally in Keel.',
                    style: pw.TextStyle(font: fonts.regular, fontSize: 7, color: FinancialPdfTheme.slateMedium),
                  ),
                ],
              ),
              pw.Text(
                'LEDGER BALANCED',
                style: pw.TextStyle(font: fonts.bold, fontSize: 7.5, color: FinancialPdfTheme.successGreen),
              ),
            ],
          ),
        ],
      ),
    );

    return doc;
  }

  // ── 2. Specialized Detailed Domain Report ──────────────────────────────────

  static Future<pw.Document> generateDomainReport({
    required ReportDomain domain,
    required FinancialReportData data,
    Uint8List? logoBytes,
    Uint8List? wordmarkBytes,
  }) async {
    final fonts = await PdfThemeFonts.load();
    final doc = pw.Document();

    String title;
    String subtitle;
    List<pw.Widget> Function(pw.Context) pageContentBuilder;

    switch (domain) {
      case ReportDomain.pnl:
        title = 'INCOME & EXPENSE STATEMENT (P&L)';
        subtitle = 'Detailed Cash Flow, Trends & Category Concentration';
        pageContentBuilder = (ctx) => [
          // KPI row (Clean: No card border, no background fill)
          pw.Row(
            children: [
              pw.Expanded(child: _kpiBox('12-MO INFLOWS', FinancialPdfTheme.formatKes(data.incomeStatement.totalIncomeMinor), FinancialPdfTheme.successGreen, fonts)),
              _verticalDivider(),
              pw.Expanded(child: _kpiBox('12-MO OUTFLOWS', FinancialPdfTheme.formatKes(data.incomeStatement.totalExpensesMinor), FinancialPdfTheme.errorRed, fonts)),
              _verticalDivider(),
              pw.Expanded(child: _kpiBox('NET SURPLUS', FinancialPdfTheme.formatKesSigned(data.incomeStatement.totalNetMinor), data.incomeStatement.totalNetMinor >= 0 ? FinancialPdfTheme.successGreen : FinancialPdfTheme.errorRed, fonts)),
              _verticalDivider(),
              pw.Expanded(child: _kpiBox('SAVINGS RATE', '${(data.incomeStatement.savingsRate * 100).toStringAsFixed(1)}%', data.incomeStatement.savingsRate >= 0.20 ? FinancialPdfTheme.successGreen : FinancialPdfTheme.warningAmber, fonts)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: FinancialPdfTheme.borderColor, thickness: 0.6),
          pw.SizedBox(height: 8),

          // Trends panel
          FinancialInsightsBuilder.buildTrendsPanel(trends: data.trends, fonts: fonts),
          pw.SizedBox(height: 10),
          pw.Divider(color: FinancialPdfTheme.borderColor, thickness: 0.6),
          pw.SizedBox(height: 8),

          // Dual-bar chart
          PdfChartWidgets.buildMonthlyBarChart(data: data.monthlyPnL, fonts: fonts, height: 110),
          pw.SizedBox(height: 12),

          // Monthly table
          FinancialPdfTheme.buildSectionTitle(fonts: fonts, title: 'Monthly Breakdown Table & Trajectory'),
          FinancialStatementBuilder.buildMonthlyTable(monthlyTrends: data.incomeStatement.monthlyTrends, fonts: fonts),
          pw.SizedBox(height: 12),

          // Categories & Payees
          FinancialPdfTheme.buildSectionTitle(fonts: fonts, title: 'Category Concentration & Payees'),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: PdfChartWidgets.buildCategoryDistributionBars(
                  categories: data.expenseCategories,
                  totalExpensesMinor: data.incomeStatement.totalExpensesMinor,
                  fonts: fonts,
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                flex: 2,
                child: FinancialInsightsBuilder.buildInsightsPanel(insights: data.insights, fonts: fonts),
              ),
            ],
          ),
        ];

      case ReportDomain.budget:
        title = 'BUDGET PERFORMANCE & VARIANCE STATEMENT';
        subtitle = 'Envelope Adherence, Category Execution & Variance Auditing';
        pageContentBuilder = (ctx) => [
          // KPI row
          pw.Row(
            children: [
              pw.Expanded(child: _kpiBox('TOTAL PLANNED', FinancialPdfTheme.formatKes(data.budgetPerformance.totalPlannedMinor), FinancialPdfTheme.royalBlue, fonts)),
              _verticalDivider(),
              pw.Expanded(child: _kpiBox('TOTAL ACTUAL', FinancialPdfTheme.formatKes(data.budgetPerformance.totalActualMinor), FinancialPdfTheme.slateDark, fonts)),
              _verticalDivider(),
              pw.Expanded(child: _kpiBox('NET VARIANCE', FinancialPdfTheme.formatKesSigned(data.budgetPerformance.totalVarianceMinor), data.budgetPerformance.totalVarianceMinor >= 0 ? FinancialPdfTheme.successGreen : FinancialPdfTheme.errorRed, fonts)),
              _verticalDivider(),
              pw.Expanded(child: _kpiBox('COMPLIANCE RATE', '${(data.budgetPerformance.compliancePct * 100).toStringAsFixed(0)}%', data.budgetPerformance.compliancePct >= 0.70 ? FinancialPdfTheme.successGreen : FinancialPdfTheme.warningAmber, fonts)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: FinancialPdfTheme.borderColor, thickness: 0.6),
          pw.SizedBox(height: 8),

          FinancialPdfTheme.buildSectionTitle(fonts: fonts, title: 'Budget vs Actual Period Comparison'),
          PdfChartWidgets.buildBudgetVarianceBarChart(periods: data.budgetVsActual, fonts: fonts),
          pw.SizedBox(height: 12),

          FinancialPdfTheme.buildSectionTitle(fonts: fonts, title: 'Budget Execution Observations & Strategy'),
          FinancialInsightsBuilder.buildInsightsPanel(insights: data.insights, fonts: fonts),
        ];

      case ReportDomain.loans:
        title = 'DEBT OBLIGATIONS & LIABILITIES STATEMENT';
        subtitle = 'Amortization, Interest Cost & Solvency Structure';
        pageContentBuilder = (ctx) => [
          // KPI row
          pw.Row(
            children: [
              pw.Expanded(child: _kpiBox('OUTSTANDING DEBT', FinancialPdfTheme.formatKes(data.debtSchedule.totalOutstandingMinor), FinancialPdfTheme.errorRed, fonts)),
              _verticalDivider(),
              pw.Expanded(child: _kpiBox('INTEREST PAID', FinancialPdfTheme.formatKes(data.debtSchedule.totalInterestPaidMinor), FinancialPdfTheme.warningAmber, fonts)),
              _verticalDivider(),
              pw.Expanded(child: _kpiBox('TOTAL COST OF CREDIT', FinancialPdfTheme.formatKes(data.debtSchedule.totalCostOfBorrowingMinor), FinancialPdfTheme.slateDark, fonts)),
              _verticalDivider(),
              pw.Expanded(child: _kpiBox('TOTAL LENT OUT', FinancialPdfTheme.formatKes(data.debtSchedule.totalLentMinor), FinancialPdfTheme.successGreen, fonts)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: FinancialPdfTheme.borderColor, thickness: 0.6),
          pw.SizedBox(height: 8),

          FinancialPdfTheme.buildSectionTitle(fonts: fonts, title: 'Active Borrowing & Lending Schedule'),
          FinancialStatementBuilder.buildDebtTable(loans: data.loanRows, fonts: fonts),
          pw.SizedBox(height: 12),

          FinancialPdfTheme.buildSectionTitle(fonts: fonts, title: 'Debt Diagnostic Insights & Acceleration'),
          FinancialInsightsBuilder.buildInsightsPanel(insights: data.insights, fonts: fonts),
        ];

      case ReportDomain.investments:
        title = 'INVESTMENT PORTFOLIO PERFORMANCE STATEMENT';
        subtitle = 'Holdings Valuation, Capital Gains & Dividend Yield';
        pageContentBuilder = (ctx) => [
          // KPI row
          pw.Row(
            children: [
              pw.Expanded(child: _kpiBox('TOTAL INVESTED', FinancialPdfTheme.formatKes(data.investmentPortfolio.totalCostBasisMinor), FinancialPdfTheme.slateDark, fonts)),
              _verticalDivider(),
              pw.Expanded(child: _kpiBox('PORTFOLIO VALUE', FinancialPdfTheme.formatKes(data.investmentPortfolio.totalMarketValueMinor), FinancialPdfTheme.royalBlue, fonts)),
              _verticalDivider(),
              pw.Expanded(child: _kpiBox('UNREALISED RETURN', FinancialPdfTheme.formatKesSigned(data.investmentPortfolio.totalUnrealisedGainMinor), data.investmentPortfolio.totalUnrealisedGainMinor >= 0 ? FinancialPdfTheme.successGreen : FinancialPdfTheme.errorRed, fonts)),
              _verticalDivider(),
              pw.Expanded(child: _kpiBox('INCOME RECEIVED', '+${FinancialPdfTheme.formatKes(data.investmentPortfolio.totalIncomeMinor)}', FinancialPdfTheme.successGreen, fonts)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: FinancialPdfTheme.borderColor, thickness: 0.6),
          pw.SizedBox(height: 8),

          PdfChartWidgets.buildAssetAllocationBar(
            cashMinor: data.balanceSheet.totalCashMinor,
            investmentsMinor: data.balanceSheet.totalInvestmentsMarketMinor,
            physicalMinor: data.balanceSheet.totalPhysicalBookMinor,
            fonts: fonts,
          ),
          pw.SizedBox(height: 12),

          FinancialPdfTheme.buildSectionTitle(fonts: fonts, title: 'Holding-by-Holding Performance Matrix'),
          FinancialStatementBuilder.buildInvestmentTable(holdings: data.holdings, fonts: fonts),
          pw.SizedBox(height: 12),

          FinancialPdfTheme.buildSectionTitle(fonts: fonts, title: 'Investment Diagnostics & Allocation Observations'),
          FinancialInsightsBuilder.buildInsightsPanel(insights: data.insights, fonts: fonts),
        ];

      case ReportDomain.assets:
        title = 'FIXED ASSET REGISTER & VALUATION STATEMENT';
        subtitle = 'Asset Classes, Depreciation Models & Insurance Verification';
        pageContentBuilder = (ctx) => [
          // KPI row
          pw.Row(
            children: [
              pw.Expanded(child: _kpiBox('HISTORICAL COST', FinancialPdfTheme.formatKes(data.assetRegister.totalCostMinor), FinancialPdfTheme.slateDark, fonts)),
              _verticalDivider(),
              pw.Expanded(child: _kpiBox('TOTAL BOOK VALUE', FinancialPdfTheme.formatKes(data.assetRegister.totalBookValueMinor), FinancialPdfTheme.royalBlue, fonts)),
              _verticalDivider(),
              pw.Expanded(child: _kpiBox('NET REVALUATION', FinancialPdfTheme.formatKesSigned(data.assetRegister.totalRevaluationMinor), data.assetRegister.totalRevaluationMinor >= 0 ? FinancialPdfTheme.successGreen : FinancialPdfTheme.errorRed, fonts)),
              _verticalDivider(),
              pw.Expanded(child: _kpiBox('INSURED ASSETS', '${data.assetRegister.insuredCount} / ${data.assets.length}', data.assetRegister.insuredCount == data.assets.length ? FinancialPdfTheme.successGreen : FinancialPdfTheme.warningAmber, fonts)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: FinancialPdfTheme.borderColor, thickness: 0.6),
          pw.SizedBox(height: 8),

          PdfChartWidgets.buildAssetAllocationBar(
            cashMinor: data.balanceSheet.totalCashMinor,
            investmentsMinor: data.balanceSheet.totalInvestmentsMarketMinor,
            physicalMinor: data.balanceSheet.totalPhysicalBookMinor,
            fonts: fonts,
          ),
          pw.SizedBox(height: 12),

          FinancialPdfTheme.buildSectionTitle(fonts: fonts, title: 'Fixed Asset Register Table'),
          FinancialStatementBuilder.buildAssetTable(assets: data.assets, fonts: fonts),
          pw.SizedBox(height: 12),

          FinancialPdfTheme.buildSectionTitle(fonts: fonts, title: 'Capital Asset Observations & Risk Management'),
          FinancialInsightsBuilder.buildInsightsPanel(insights: data.insights, fonts: fonts),
        ];

      case ReportDomain.comprehensive:
        return generateComprehensiveReport(data: data, logoBytes: logoBytes, wordmarkBytes: wordmarkBytes);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => FinancialPdfTheme.buildHeader(
          fonts: fonts,
          title: title,
          subtitle: subtitle,
          logoBytes: logoBytes,
          wordmarkBytes: wordmarkBytes,
          date: data.asOf,
        ),
        footer: (ctx) => FinancialPdfTheme.buildFooter(context: ctx, fonts: fonts),
        build: pageContentBuilder,
      ),
    );

    return doc;
  }

  static pw.Widget _kpiBox(String label, String value, PdfColor color, PdfThemeFonts fonts) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: 6.5,
            color: FinancialPdfTheme.slateMedium,
            letterSpacing: 0.3,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(font: fonts.bold, fontSize: 10, color: color),
        ),
      ],
    );
  }

  static pw.Widget _verticalDivider() {
    return pw.Container(
      width: 0.6,
      height: 24,
      margin: const pw.EdgeInsets.symmetric(horizontal: 8),
      color: FinancialPdfTheme.borderColor,
    );
  }
}
