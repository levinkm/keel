import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:keel/features/reports/presentation/bloc/reports_cubit.dart';
import 'financial_pdf_theme.dart';

class PdfChartWidgets {
  // ── 1. Monthly Inflow vs Outflow Dual-Bar Chart ─────────────────────────────

  static pw.Widget buildMonthlyBarChart({
    required List<MonthlyPnL> data,
    required PdfThemeFonts fonts,
    double height = 115,
    int maxBars = 12,
  }) {
    if (data.isEmpty) {
      return pw.Container(
        height: height,
        alignment: pw.Alignment.center,
        child: pw.Text(
          'No historical cash flow data available',
          style: pw.TextStyle(font: fonts.italic, fontSize: 9, color: FinancialPdfTheme.slateMedium),
        ),
      );
    }

    final pnlList = data.length > maxBars ? data.sublist(data.length - maxBars) : data;

    int maxVal = 1;
    for (final d in pnlList) {
      maxVal = max(maxVal, max(d.incomeMinor, d.expensesMinor));
    }

    final barAreaHeight = height - 28;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header with legend (No card background, no card borders)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '12-Month Inflow vs Outflow History',
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 8.5,
                color: FinancialPdfTheme.slateDark,
              ),
            ),
            pw.Row(
              children: [
                _legendDot(FinancialPdfTheme.successGreen, 'Inflows (Income)', fonts),
                pw.SizedBox(width: 10),
                _legendDot(FinancialPdfTheme.errorRed, 'Outflows (Expenses)', fonts),
                pw.SizedBox(width: 10),
                _legendDot(FinancialPdfTheme.royalBlue, 'Net Surplus', fonts),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),

        // Bars container
        pw.SizedBox(
          height: barAreaHeight,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: pnlList.map((d) {
              final incH = maxVal > 0 ? (d.incomeMinor / maxVal) * (barAreaHeight - 14) : 0.0;
              final expH = maxVal > 0 ? (d.expensesMinor / maxVal) * (barAreaHeight - 14) : 0.0;
              final isNetPositive = d.netMinor >= 0;

              return pw.Expanded(
                child: pw.Container(
                  margin: const pw.EdgeInsets.symmetric(horizontal: 2),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      // Net indicator dot
                      pw.Container(
                        width: 3.5,
                        height: 3.5,
                        margin: const pw.EdgeInsets.only(bottom: 2),
                        decoration: pw.BoxDecoration(
                          color: isNetPositive
                              ? FinancialPdfTheme.royalBlue
                              : FinancialPdfTheme.warningAmber,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      // Dual bars
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          // Income bar
                          pw.ClipRRect(
                            horizontalRadius: 1.5,
                            verticalRadius: 1.5,
                            child: pw.Container(
                              width: 6,
                              height: max(2.0, incH),
                              color: FinancialPdfTheme.successGreen,
                            ),
                          ),
                          pw.SizedBox(width: 1.5),
                          // Expense bar
                          pw.ClipRRect(
                            horizontalRadius: 1.5,
                            verticalRadius: 1.5,
                            child: pw.Container(
                              width: 6,
                              height: max(2.0, expH),
                              color: FinancialPdfTheme.errorRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Clean baseline hairline rule
        pw.Container(height: 0.6, color: FinancialPdfTheme.borderColor),
        pw.SizedBox(height: 3),

        // Month labels
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: pnlList.map((d) {
            return pw.Expanded(
              child: pw.Center(
                child: pw.Text(
                  _shortMonth(d.period),
                  style: pw.TextStyle(
                    font: fonts.regular,
                    fontSize: 7,
                    color: FinancialPdfTheme.slateMedium,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── 2. Top Expense Categories Distribution Progress Bars ────────────────────

  static pw.Widget buildCategoryDistributionBars({
    required List<ExpenseCategory> categories,
    required int totalExpensesMinor,
    required PdfThemeFonts fonts,
    int maxItems = 6,
  }) {
    if (categories.isEmpty) {
      return pw.Text('No categorized expense data available.',
          style: pw.TextStyle(font: fonts.italic, fontSize: 8.5, color: FinancialPdfTheme.slateMedium));
    }

    final topItems = categories.take(maxItems).toList();

    return pw.Column(
      children: topItems.map((cat) {
        final pct = totalExpensesMinor > 0 ? cat.totalMinor / totalExpensesMinor : 0.0;
        final pctStr = '${(pct * 100).toStringAsFixed(1)}%';

        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      cat.accountName,
                      style: pw.TextStyle(font: fonts.bold, fontSize: 8, color: FinancialPdfTheme.slateDark),
                      maxLines: 1,
                    ),
                  ),
                  pw.Row(
                    children: [
                      pw.Text(
                        FinancialPdfTheme.formatKes(cat.totalMinor),
                        style: pw.TextStyle(font: fonts.bold, fontSize: 8, color: FinancialPdfTheme.primaryNavy),
                      ),
                      pw.SizedBox(width: 6),
                      // Clean plain text without pill/box background
                      pw.Text(
                        pctStr,
                        style: pw.TextStyle(font: fonts.regular, fontSize: 7.5, color: FinancialPdfTheme.slateMedium),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 2.5),
              pw.ClipRRect(
                horizontalRadius: 1.5,
                verticalRadius: 1.5,
                child: pw.LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  minHeight: 3.5,
                  backgroundColor: FinancialPdfTheme.borderColor,
                  valueColor: FinancialPdfTheme.royalBlue,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── 3. Asset Allocation Segmented Bar ────────────────────────────────────────

  static pw.Widget buildAssetAllocationBar({
    required int cashMinor,
    required int investmentsMinor,
    required int physicalMinor,
    required PdfThemeFonts fonts,
  }) {
    final total = cashMinor + investmentsMinor + physicalMinor;
    if (total <= 0) {
      return pw.SizedBox.shrink();
    }

    final cashPct = cashMinor / total;
    final invPct = investmentsMinor / total;
    final phyPct = physicalMinor / total;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Asset Allocation Mix',
              style: pw.TextStyle(font: fonts.bold, fontSize: 8.5, color: FinancialPdfTheme.slateDark),
            ),
            pw.Text(
              'Total Assets: ${FinancialPdfTheme.formatKes(total)}',
              style: pw.TextStyle(font: fonts.bold, fontSize: 8.5, color: FinancialPdfTheme.primaryNavy),
            ),
          ],
        ),
        pw.SizedBox(height: 5),

        // Stacked Segment Bar
        pw.ClipRRect(
          horizontalRadius: 2,
          verticalRadius: 2,
          child: pw.SizedBox(
            height: 8,
            child: pw.Row(
              children: [
                if (cashPct > 0)
                  pw.Expanded(
                    flex: max(1, (cashPct * 100).round()),
                    child: pw.Container(color: FinancialPdfTheme.royalBlue),
                  ),
                if (invPct > 0)
                  pw.Expanded(
                    flex: max(1, (invPct * 100).round()),
                    child: pw.Container(color: FinancialPdfTheme.successGreen),
                  ),
                if (phyPct > 0)
                  pw.Expanded(
                    flex: max(1, (phyPct * 100).round()),
                    child: pw.Container(color: FinancialPdfTheme.warningAmber),
                  ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 6),

        // Legend and values
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _allocationSegment(
              label: 'Cash & Bank',
              amount: cashMinor,
              pct: cashPct,
              color: FinancialPdfTheme.royalBlue,
              fonts: fonts,
            ),
            _allocationSegment(
              label: 'Investments',
              amount: investmentsMinor,
              pct: invPct,
              color: FinancialPdfTheme.successGreen,
              fonts: fonts,
            ),
            _allocationSegment(
              label: 'Physical / Fixed',
              amount: physicalMinor,
              pct: phyPct,
              color: FinancialPdfTheme.warningAmber,
              fonts: fonts,
            ),
          ],
        ),
      ],
    );
  }

  // ── 4. Budget Variance Comparison Bars ──────────────────────────────────────

  static pw.Widget buildBudgetVarianceBarChart({
    required List<BudgetVsActual> periods,
    required PdfThemeFonts fonts,
  }) {
    if (periods.isEmpty) {
      return pw.Text('No budget plan records found.',
          style: pw.TextStyle(font: fonts.italic, fontSize: 8.5, color: FinancialPdfTheme.slateMedium));
    }

    return pw.Column(
      children: periods.reversed.map((p) {
        final planned = p.plannedMinor;
        final actual = p.actualMinor;
        final isUnder = p.isUnder;
        final variance = p.varianceMinor;
        final maxVal = max(planned, actual);
        final plannedRatio = maxVal > 0 ? planned / maxVal : 0.0;
        final actualRatio = maxVal > 0 ? actual / maxVal : 0.0;

        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    FinancialPdfTheme.formatPeriod(p.period),
                    style: pw.TextStyle(font: fonts.bold, fontSize: 8.5, color: FinancialPdfTheme.slateDark),
                  ),
                  // Clean status text without pill/background
                  pw.Text(
                    isUnder
                        ? 'Under Budget (${FinancialPdfTheme.formatKesSigned(variance)})'
                        : 'Over Budget (${FinancialPdfTheme.formatKesSigned(variance)})',
                    style: pw.TextStyle(
                      font: fonts.bold,
                      fontSize: 7.5,
                      color: isUnder
                          ? FinancialPdfTheme.successGreen
                          : FinancialPdfTheme.errorRed,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),

              // Planned bar
              pw.Row(
                children: [
                  pw.SizedBox(
                    width: 44,
                    child: pw.Text('Planned',
                        style: pw.TextStyle(font: fonts.regular, fontSize: 7, color: FinancialPdfTheme.slateMedium)),
                  ),
                  pw.Expanded(
                    child: pw.ClipRRect(
                      horizontalRadius: 1.5,
                      verticalRadius: 1.5,
                      child: pw.LinearProgressIndicator(
                        value: plannedRatio.clamp(0.0, 1.0),
                        minHeight: 3.5,
                        backgroundColor: FinancialPdfTheme.borderColor,
                        valueColor: FinancialPdfTheme.royalBlue,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.SizedBox(
                    width: 70,
                    child: pw.Text(
                      FinancialPdfTheme.formatKes(planned),
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(font: fonts.regular, fontSize: 7.5, color: FinancialPdfTheme.slateDark),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 2.5),

              // Actual bar
              pw.Row(
                children: [
                  pw.SizedBox(
                    width: 44,
                    child: pw.Text('Actual',
                        style: pw.TextStyle(font: fonts.regular, fontSize: 7, color: FinancialPdfTheme.slateMedium)),
                  ),
                  pw.Expanded(
                    child: pw.ClipRRect(
                      horizontalRadius: 1.5,
                      verticalRadius: 1.5,
                      child: pw.LinearProgressIndicator(
                        value: actualRatio.clamp(0.0, 1.0),
                        minHeight: 3.5,
                        backgroundColor: FinancialPdfTheme.borderColor,
                        valueColor: isUnder
                            ? FinancialPdfTheme.successGreen
                            : FinancialPdfTheme.errorRed,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.SizedBox(
                    width: 70,
                    child: pw.Text(
                      FinancialPdfTheme.formatKes(actual),
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        font: fonts.bold,
                        fontSize: 7.5,
                        color: isUnder
                            ? FinancialPdfTheme.successGreen
                            : FinancialPdfTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(color: FinancialPdfTheme.borderColor, thickness: 0.4),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── 5. Trend Indicator (Plain Text, No Pill Highlight) ───────────────────────

  static pw.Widget buildTrendBadge({
    required double changePct,
    required bool isFavorable,
    required PdfThemeFonts fonts,
    String? suffix,
  }) {
    final isZero = changePct.abs() < 0.001;
    final isPos = changePct > 0;
    final symbol = isZero ? '~' : (isPos ? '+' : '');
    final text = '$symbol${(changePct * 100).toStringAsFixed(1)}%${suffix != null ? ' $suffix' : ''}';

    final textColor = isZero
        ? FinancialPdfTheme.slateMedium
        : (isFavorable
            ? FinancialPdfTheme.successGreen
            : FinancialPdfTheme.errorRed);

    // Clean text only - NO pill-like highlight, NO background
    return pw.Text(
      text,
      style: pw.TextStyle(font: fonts.bold, fontSize: 7.5, color: textColor),
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static pw.Widget _legendDot(PdfColor color, String label, PdfThemeFonts fonts) {
    return pw.Row(
      children: [
        pw.Container(
          width: 5,
          height: 5,
          decoration: pw.BoxDecoration(
            color: color,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.SizedBox(width: 3.5),
        pw.Text(
          label,
          style: pw.TextStyle(font: fonts.regular, fontSize: 7, color: FinancialPdfTheme.slateMedium),
        ),
      ],
    );
  }

  static pw.Widget _allocationSegment({
    required String label,
    required int amount,
    required double pct,
    required PdfColor color,
    required PdfThemeFonts fonts,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(width: 5, height: 5, color: color),
            pw.SizedBox(width: 3.5),
            pw.Text(label,
                style: pw.TextStyle(font: fonts.regular, fontSize: 7.5, color: FinancialPdfTheme.slateMedium)),
          ],
        ),
        pw.SizedBox(height: 1.5),
        pw.Text(
          '${FinancialPdfTheme.formatKes(amount)} (${(pct * 100).toStringAsFixed(1)}%)',
          style: pw.TextStyle(font: fonts.bold, fontSize: 8, color: FinancialPdfTheme.slateDark),
        ),
      ],
    );
  }

  static String _shortMonth(String period) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final parts = period.split('-');
    if (parts.length == 2) {
      final mon = int.tryParse(parts[1]) ?? 1;
      return m[mon];
    }
    return period;
  }
}
