import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:keel/features/reports/domain/models/financial_report_data.dart';
import 'financial_pdf_theme.dart';
import 'pdf_chart_widgets.dart';

class FinancialInsightsBuilder {
  // ── 1. Executive Health Scorecard & KPI Grid ────────────────────────────────

  static pw.Widget buildExecutiveHealthCard({
    required FinancialHealthScore health,
    required BalanceSheetStatement bs,
    required FinancialTrends trends,
    required PdfThemeFonts fonts,
  }) {
    PdfColor ratingColor;
    if (health.score >= 80) {
      ratingColor = FinancialPdfTheme.successGreen;
    } else if (health.score >= 65) {
      ratingColor = FinancialPdfTheme.royalBlue;
    } else if (health.score >= 50) {
      ratingColor = FinancialPdfTheme.warningAmber;
    } else {
      ratingColor = FinancialPdfTheme.errorRed;
    }

    // Clean layout: No card border, no translucent background
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Score typographic block - NO background, NO border
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'HEALTH SCORE',
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 7,
                color: FinancialPdfTheme.slateMedium,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  '${health.score}',
                  style: pw.TextStyle(
                    font: fonts.bold,
                    fontSize: 26,
                    color: ratingColor,
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Text(
                  '/ 100',
                  style: pw.TextStyle(
                    font: fonts.regular,
                    fontSize: 10,
                    color: FinancialPdfTheme.slateMedium,
                  ),
                ),
              ],
            ),
            pw.Text(
              health.rating,
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 8,
                color: ratingColor,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        pw.Container(
          width: 0.8,
          height: 48,
          margin: const pw.EdgeInsets.symmetric(horizontal: 14),
          color: FinancialPdfTheme.borderColor,
        ),

        // Diagnostic description and core indicators
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Financial Health Assessment',
                style: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: 9.5,
                  color: FinancialPdfTheme.primaryNavy,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                health.description,
                style: pw.TextStyle(
                  font: fonts.regular,
                  fontSize: 7.5,
                  color: FinancialPdfTheme.slateMedium,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _miniKpi(
                    label: 'TOTAL NET WORTH',
                    value: FinancialPdfTheme.formatCompact(bs.netWorthMinor),
                    color: bs.netWorthMinor >= 0
                        ? FinancialPdfTheme.primaryNavy
                        : FinancialPdfTheme.errorRed,
                    fonts: fonts,
                  ),
                  _miniKpi(
                    label: 'LIQUID RUNWAY',
                    value: trends.runwayMonths >= 12
                        ? '12+ Mo'
                        : '${trends.runwayMonths.toStringAsFixed(1)} Mo',
                    color: trends.runwayMonths >= 3
                        ? FinancialPdfTheme.successGreen
                        : FinancialPdfTheme.warningAmber,
                    fonts: fonts,
                  ),
                  _miniKpi(
                    label: 'ANNUAL SAVINGS %',
                    value: '${(trends.annualSavingsRate * 100).toStringAsFixed(1)}%',
                    color: trends.annualSavingsRate >= 0.20
                        ? FinancialPdfTheme.successGreen
                        : FinancialPdfTheme.warningAmber,
                    fonts: fonts,
                  ),
                  _miniKpi(
                    label: 'DEBT-TO-ASSET',
                    value: '${(health.debtToAssetRatio * 100).toStringAsFixed(1)}%',
                    color: health.debtToAssetRatio < 0.35
                        ? FinancialPdfTheme.successGreen
                        : FinancialPdfTheme.errorRed,
                    fonts: fonts,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 2. KPI Summary Grid (No Card Borders, No Background Fills) ─────────────

  static pw.Widget buildKpiGrid({
    required FinancialReportData data,
    required PdfThemeFonts fonts,
  }) {
    final bs = data.balanceSheet;
    final ins = data.incomeStatement;
    final tr = data.trends;

    return pw.Row(
      children: [
        pw.Expanded(
          child: _kpiItem(
            label: 'TOTAL NET WORTH',
            value: FinancialPdfTheme.formatKes(bs.netWorthMinor),
            subtext: 'Liquid Equity: ${FinancialPdfTheme.formatKes(bs.liquidNetWorthMinor)}',
            valueColor: bs.netWorthMinor >= 0
                ? FinancialPdfTheme.primaryNavy
                : FinancialPdfTheme.errorRed,
            fonts: fonts,
          ),
        ),
        _verticalDivider(),
        pw.Expanded(
          child: _kpiItem(
            label: '12-MONTH NET SAVINGS',
            value: FinancialPdfTheme.formatKesSigned(ins.totalNetMinor),
            subtext: 'Savings Rate: ${(ins.savingsRate * 100).toStringAsFixed(1)}%',
            valueColor: ins.totalNetMinor >= 0
                ? FinancialPdfTheme.successGreen
                : FinancialPdfTheme.errorRed,
            fonts: fonts,
          ),
        ),
        _verticalDivider(),
        pw.Expanded(
          child: _kpiItem(
            label: 'EMERGENCY RUNWAY',
            value: tr.runwayMonths >= 12
                ? '12+ Months'
                : '${tr.runwayMonths.toStringAsFixed(1)} Months',
            subtext: 'Liquid Cash: ${FinancialPdfTheme.formatKes(bs.liquidCashMinor)}',
            valueColor: tr.runwayMonths >= 3
                ? FinancialPdfTheme.successGreen
                : FinancialPdfTheme.warningAmber,
            fonts: fonts,
          ),
        ),
        _verticalDivider(),
        pw.Expanded(
          child: _kpiItem(
            label: 'TOTAL LIABILITIES',
            value: FinancialPdfTheme.formatKes(bs.totalLiabilitiesMinor),
            subtext: 'Asset Coverage: ${(data.healthScore.debtToAssetRatio * 100).toStringAsFixed(1)}%',
            valueColor: bs.totalLiabilitiesMinor == 0
                ? FinancialPdfTheme.successGreen
                : FinancialPdfTheme.errorRed,
            fonts: fonts,
          ),
        ),
      ],
    );
  }

  // ── 3. Trends & Momentum Panel (No Card Border, No Translucent Fill) ────────

  static pw.Widget buildTrendsPanel({
    required FinancialTrends trends,
    required PdfThemeFonts fonts,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _trendItem(
          title: 'Income Trajectory',
          value: FinancialPdfTheme.formatKes(trends.incomeMoM.currentValue),
          metric: trends.incomeMoM,
          fonts: fonts,
        ),
        _verticalDivider(),
        _trendItem(
          title: 'Expense Velocity',
          value: FinancialPdfTheme.formatKes(trends.expenseMoM.currentValue),
          metric: trends.expenseMoM,
          fonts: fonts,
        ),
        _verticalDivider(),
        _trendItem(
          title: 'Net Surplus Shift',
          value: FinancialPdfTheme.formatKesSigned(trends.netMoM.currentValue),
          metric: trends.netMoM,
          fonts: fonts,
        ),
        _verticalDivider(),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Savings Rate Delta',
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 7,
                color: FinancialPdfTheme.slateMedium,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              '${(trends.recentSavingsRate * 100).toStringAsFixed(1)}% (Recent 3-Mo)',
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 8.5,
                color: FinancialPdfTheme.slateDark,
              ),
            ),
            pw.SizedBox(height: 2),
            PdfChartWidgets.buildTrendBadge(
              changePct: trends.savingsRateDelta,
              isFavorable: trends.savingsRateDelta >= 0,
              suffix: 'vs 12-mo',
              fonts: fonts,
            ),
          ],
        ),
      ],
    );
  }

  // ── 4. Executive Diagnostic Commentary Panel (Clean White Layout) ───────────

  static pw.Widget buildInsightsPanel({
    required FinancialInsights insights,
    required PdfThemeFonts fonts,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Executive Narrative Summary
        pw.Text(
          insights.executiveSummary,
          style: pw.TextStyle(
            font: fonts.regular,
            fontSize: 8,
            color: FinancialPdfTheme.slateDark,
            lineSpacing: 1.3,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Divider(color: FinancialPdfTheme.borderColor, thickness: 0.5),
        pw.SizedBox(height: 4),

        // Detailed Bulleted Observations
        ...insights.observations.map(
          (obs) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3.5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 3.5,
                  height: 3.5,
                  margin: const pw.EdgeInsets.only(top: 3.5, right: 6),
                  decoration: const pw.BoxDecoration(
                    color: FinancialPdfTheme.royalBlue,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    obs,
                    style: pw.TextStyle(
                      font: fonts.regular,
                      fontSize: 7.5,
                      color: FinancialPdfTheme.slateDark,
                      lineSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 5. Strategic Recommendations Panel (Clean, No Box Border / Tint) ───────

  static pw.Widget buildRecommendationsPanel({
    required List<String> recommendations,
    required PdfThemeFonts fonts,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        ...recommendations.asMap().entries.map((e) {
          final idx = e.key + 1;
          final rec = e.value;
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Clean numbered label without circular badge container
                pw.SizedBox(
                  width: 14,
                  child: pw.Text(
                    '$idx.',
                    style: pw.TextStyle(
                      font: fonts.bold,
                      fontSize: 8,
                      color: FinancialPdfTheme.royalBlue,
                    ),
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Expanded(
                  child: pw.Text(
                    rec,
                    style: pw.TextStyle(
                      font: fonts.regular,
                      fontSize: 7.5,
                      color: FinancialPdfTheme.slateDark,
                      lineSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Private Helpers ────────────────────────────────────────────────────────

  static pw.Widget _verticalDivider() {
    return pw.Container(
      width: 0.6,
      height: 28,
      margin: const pw.EdgeInsets.symmetric(horizontal: 8),
      color: FinancialPdfTheme.borderColor,
    );
  }

  static pw.Widget _miniKpi({
    required String label,
    required String value,
    required PdfColor color,
    required PdfThemeFonts fonts,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: 6.5,
            color: FinancialPdfTheme.slateMedium,
          ),
        ),
        pw.SizedBox(height: 1),
        pw.Text(
          value,
          style: pw.TextStyle(font: fonts.bold, fontSize: 9, color: color),
        ),
      ],
    );
  }

  static pw.Widget _kpiItem({
    required String label,
    required String value,
    required String subtext,
    required PdfColor valueColor,
    required PdfThemeFonts fonts,
  }) {
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
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: 11,
            color: valueColor,
          ),
        ),
        pw.SizedBox(height: 1.5),
        pw.Text(
          subtext,
          style: pw.TextStyle(
            font: fonts.regular,
            fontSize: 7,
            color: FinancialPdfTheme.slateMedium,
          ),
        ),
      ],
    );
  }

  static pw.Widget _trendItem({
    required String title,
    required String value,
    required TrendMetric metric,
    required PdfThemeFonts fonts,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: 7,
            color: FinancialPdfTheme.slateMedium,
          ),
        ),
        pw.SizedBox(height: 1.5),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: 8.5,
            color: FinancialPdfTheme.slateDark,
          ),
        ),
        pw.SizedBox(height: 1.5),
        PdfChartWidgets.buildTrendBadge(
          changePct: metric.changePct,
          isFavorable: metric.isFavorable,
          suffix: 'MoM',
          fonts: fonts,
        ),
      ],
    );
  }
}
