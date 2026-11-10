import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:keel/features/assets/domain/entities/asset.dart';
import 'package:keel/features/investments/domain/entities/holding.dart';
import 'package:keel/features/loans/domain/entities/loan.dart';
import 'package:keel/features/reports/domain/models/financial_report_data.dart';
import 'package:keel/features/reports/presentation/bloc/reports_cubit.dart';
import 'financial_pdf_theme.dart';

class FinancialStatementBuilder {
  // ── 1. Balance Sheet (Statement of Financial Position) ──────────────────────

  static pw.Widget buildBalanceSheet({
    required BalanceSheetStatement bs,
    required PdfThemeFonts fonts,
  }) {
    // No card border, no card background
    return pw.Column(
      children: [
        // Section: ASSETS
        _statementHeader('I. ASSETS & CAPITAL HOLDINGS', fonts),

        // Subsection: Liquid / Current
        _subHeaderRow('Current Liquid Assets (Cash & Bank)', fonts),
        ...bs.cashAccounts.map(
          (a) => _statementDataRow(
            indent: true,
            label: a.name,
            annotation: a.liquidity.name.toUpperCase(),
            value: FinancialPdfTheme.formatKes(a.balanceMinor),
            fonts: fonts,
          ),
        ),
        _subtotalRow(
          'Total Liquid Assets',
          FinancialPdfTheme.formatKes(bs.totalCashMinor),
          fonts,
        ),

        // Subsection: Investments
        if (bs.holdings.isNotEmpty) ...[
          _subHeaderRow('Investment Portfolio (Market Value)', fonts),
          ...bs.holdings.map(
            (h) => _statementDataRow(
              indent: true,
              label: h.name,
              annotation: h.institution,
              value: FinancialPdfTheme.formatKes(h.marketValueMinor),
              fonts: fonts,
            ),
          ),
          _subtotalRow(
            'Total Investment Portfolio',
            FinancialPdfTheme.formatKes(bs.totalInvestmentsMarketMinor),
            fonts,
          ),
        ],

        // Subsection: Physical / Capital Assets
        if (bs.physicalAssets.isNotEmpty) ...[
          _subHeaderRow('Physical & Fixed Assets (Book Value)', fonts),
          ...bs.physicalAssets.map(
            (a) => _statementDataRow(
              indent: true,
              label: a.name,
              annotation: a.assetClass.name.toUpperCase(),
              value: FinancialPdfTheme.formatKes(a.bookValue),
              fonts: fonts,
            ),
          ),
          _subtotalRow(
            'Total Fixed Assets',
            FinancialPdfTheme.formatKes(bs.totalPhysicalBookMinor),
            fonts,
          ),
        ],

        // TOTAL ASSETS
        _totalRow(
          'TOTAL ASSETS',
          FinancialPdfTheme.formatKes(bs.totalAssetsMinor),
          FinancialPdfTheme.primaryNavy,
          fonts,
        ),
        pw.SizedBox(height: 6),

        // Section: LIABILITIES
        _statementHeader('II. LIABILITIES & DEBT OBLIGATIONS', fonts),
        if (bs.borrowedLoans.isEmpty)
          _statementDataRow(
            indent: true,
            label: 'Active Borrowings',
            annotation: 'DEBT FREE',
            value: FinancialPdfTheme.formatKes(0),
            fonts: fonts,
          )
        else ...[
          ...bs.borrowedLoans.map(
            (r) => _statementDataRow(
              indent: true,
              label: r.loan.counterparty,
              annotation: '${(r.loan.annualRateBp / 100).toStringAsFixed(1)}% p.a.',
              value: FinancialPdfTheme.formatKes(r.summary.outstandingMinor),
              fonts: fonts,
              valueColor: FinancialPdfTheme.errorRed,
            ),
          ),
        ],
        _totalRow(
          'TOTAL LIABILITIES',
          FinancialPdfTheme.formatKes(bs.totalLiabilitiesMinor),
          FinancialPdfTheme.errorRed,
          fonts,
        ),
        pw.SizedBox(height: 6),

        // Section: NET WORTH / EQUITY
        _statementHeader('III. NET WORTH & EQUITY POSITION', fonts),
        _statementDataRow(
          indent: true,
          label: 'Liquid Net Worth (Liquid Cash - Liabilities)',
          annotation: bs.liquidNetWorthMinor >= 0 ? 'Surplus' : 'Deficit',
          value: FinancialPdfTheme.formatKes(bs.liquidNetWorthMinor),
          fonts: fonts,
          valueColor: bs.liquidNetWorthMinor >= 0
              ? FinancialPdfTheme.successGreen
              : FinancialPdfTheme.errorRed,
        ),
        _statementDataRow(
          indent: true,
          label: 'Illiquid Capital (Investments + Fixed Assets)',
          annotation: 'Capital Equity',
          value: FinancialPdfTheme.formatKes(bs.illiquidNetWorthMinor),
          fonts: fonts,
        ),
        _totalRow(
          'TOTAL NET WORTH (ASSETS - LIABILITIES)',
          FinancialPdfTheme.formatKes(bs.netWorthMinor),
          bs.netWorthMinor >= 0
              ? FinancialPdfTheme.successGreen
              : FinancialPdfTheme.errorRed,
          fonts,
        ),
      ],
    );
  }

  // ── 2. Income Statement (Statement of Financial Performance) ────────────────

  static pw.Widget buildIncomeStatement({
    required IncomeStatementStatement isData,
    required PdfThemeFonts fonts,
  }) {
    return pw.Column(
      children: [
        _statementHeader(
          'STATEMENT OF FINANCIAL PERFORMANCE (12-MONTH SUMMARY)',
          fonts,
        ),
        _statementDataRow(
          indent: false,
          label: 'Total Operating Inflows (Income)',
          annotation: 'Cumulative 12-Mo',
          value: FinancialPdfTheme.formatKes(isData.totalIncomeMinor),
          fonts: fonts,
          valueColor: FinancialPdfTheme.successGreen,
        ),
        _statementDataRow(
          indent: false,
          label: 'Total Operating Outflows (Expenses)',
          annotation: 'Cumulative 12-Mo',
          value: FinancialPdfTheme.formatKes(isData.totalExpensesMinor),
          fonts: fonts,
          valueColor: FinancialPdfTheme.errorRed,
        ),
        _totalRow(
          'NET OPERATING SURPLUS / (DEFICIT)',
          FinancialPdfTheme.formatKesSigned(isData.totalNetMinor),
          isData.totalNetMinor >= 0
              ? FinancialPdfTheme.successGreen
              : FinancialPdfTheme.errorRed,
          fonts,
        ),
        _statementDataRow(
          indent: false,
          label: 'Annual Net Savings Rate',
          annotation: isData.savingsRate >= 0.20
              ? 'Optimal (>=20%)'
              : 'Below Target (<20%)',
          value: '${(isData.savingsRate * 100).toStringAsFixed(1)}%',
          fonts: fonts,
          valueColor: isData.savingsRate >= 0.20
              ? FinancialPdfTheme.successGreen
              : FinancialPdfTheme.warningAmber,
        ),
      ],
    );
  }

  // ── 3. Monthly Performance Table (Clean, No Row Zebra Shading, No Dark Header)

  static pw.Widget buildMonthlyTable({
    required List<MonthlyTrendItem> monthlyTrends,
    required PdfThemeFonts fonts,
  }) {
    return pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: FinancialPdfTheme.borderColor, width: 0.8),
        bottom: pw.BorderSide(color: FinancialPdfTheme.borderColor, width: 0.8),
        horizontalInside: pw.BorderSide(
          color: FinancialPdfTheme.borderColor,
          width: 0.4,
        ),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.2), // Month
        1: pw.FlexColumnWidth(1.8), // Inflows
        2: pw.FlexColumnWidth(1.8), // Outflows
        3: pw.FlexColumnWidth(1.8), // Net
        4: pw.FlexColumnWidth(1.4), // Savings Rate
        5: pw.FlexColumnWidth(1.2), // MoM Inc
        6: pw.FlexColumnWidth(1.2), // MoM Exp
      },
      children: [
        // Header row - Clean white background with subtle line
        pw.TableRow(
          children: [
            _th('Month', fonts),
            _th('Inflows', fonts, align: pw.TextAlign.right),
            _th('Outflows', fonts, align: pw.TextAlign.right),
            _th('Net Surplus', fonts, align: pw.TextAlign.right),
            _th('Savings %', fonts, align: pw.TextAlign.right),
            _th('MoM In', fonts, align: pw.TextAlign.right),
            _th('MoM Out', fonts, align: pw.TextAlign.right),
          ],
        ),
        // Rows - No zebra stripe background
        ...monthlyTrends.reversed.map((item) {
          final p = item.pnl;
          final net = p.netMinor;
          final isPos = net >= 0;

          return pw.TableRow(
            children: [
              _td(FinancialPdfTheme.formatPeriod(p.period), fonts, bold: true),
              _td(
                FinancialPdfTheme.formatKes(p.incomeMinor),
                fonts,
                align: pw.TextAlign.right,
                color: FinancialPdfTheme.successGreen,
              ),
              _td(
                FinancialPdfTheme.formatKes(p.expensesMinor),
                fonts,
                align: pw.TextAlign.right,
                color: FinancialPdfTheme.errorRed,
              ),
              _td(
                FinancialPdfTheme.formatKesSigned(net),
                fonts,
                align: pw.TextAlign.right,
                bold: true,
                color: isPos
                    ? FinancialPdfTheme.successGreen
                    : FinancialPdfTheme.errorRed,
              ),
              _td(
                '${(p.savingsRate * 100).toStringAsFixed(1)}%',
                fonts,
                align: pw.TextAlign.right,
                color: p.savingsRate >= 0.20
                    ? FinancialPdfTheme.successGreen
                    : FinancialPdfTheme.slateDark,
              ),
              _td(
                item.momIncomePct.abs() > 0.001
                    ? '${item.momIncomePct > 0 ? '+' : ''}${(item.momIncomePct * 100).toStringAsFixed(0)}%'
                    : '-',
                fonts,
                align: pw.TextAlign.right,
                color: item.momIncomePct >= 0
                    ? FinancialPdfTheme.successGreen
                    : FinancialPdfTheme.slateMedium,
              ),
              _td(
                item.momExpensePct.abs() > 0.001
                    ? '${item.momExpensePct > 0 ? '+' : ''}${(item.momExpensePct * 100).toStringAsFixed(0)}%'
                    : '-',
                fonts,
                align: pw.TextAlign.right,
                color: item.momExpensePct <= 0
                    ? FinancialPdfTheme.successGreen
                    : FinancialPdfTheme.errorRed,
              ),
            ],
          );
        }),
      ],
    );
  }

  // ── 4. Debt Schedule Table (Clean, No Shading) ─────────────────────────────

  static pw.Widget buildDebtTable({
    required List<LoanReportRow> loans,
    required PdfThemeFonts fonts,
  }) {
    if (loans.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 8),
        child: pw.Text(
          'No outstanding loan liabilities recorded.',
          style: pw.TextStyle(
            font: fonts.italic,
            fontSize: 8.5,
            color: FinancialPdfTheme.slateMedium,
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: FinancialPdfTheme.borderColor, width: 0.8),
        bottom: pw.BorderSide(color: FinancialPdfTheme.borderColor, width: 0.8),
        horizontalInside: pw.BorderSide(
          color: FinancialPdfTheme.borderColor,
          width: 0.4,
        ),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.2), // Creditor
        1: pw.FlexColumnWidth(1.2), // Type
        2: pw.FlexColumnWidth(1.6), // Principal
        3: pw.FlexColumnWidth(1.6), // Outstanding
        4: pw.FlexColumnWidth(1.2), // Rate
        5: pw.FlexColumnWidth(1.5), // Int. Paid
        6: pw.FlexColumnWidth(1.5), // Remaining Int
        7: pw.FlexColumnWidth(1.0), // Remaining Mo
      },
      children: [
        pw.TableRow(
          children: [
            _th('Creditor / Counterparty', fonts),
            _th('Direction', fonts),
            _th('Principal', fonts, align: pw.TextAlign.right),
            _th('Outstanding', fonts, align: pw.TextAlign.right),
            _th('Rate p.a.', fonts, align: pw.TextAlign.right),
            _th('Int. Paid', fonts, align: pw.TextAlign.right),
            _th('Rem. Int.', fonts, align: pw.TextAlign.right),
            _th('Mo. Left', fonts, align: pw.TextAlign.right),
          ],
        ),
        ...loans.map((r) {
          final isBorrowed = r.loan.direction == LoanDirection.borrowed;
          final outstanding = r.summary.outstandingMinor;

          return pw.TableRow(
            children: [
              _td(r.loan.counterparty, fonts, bold: true),
              _td(
                isBorrowed ? 'BORROWED' : 'LENT',
                fonts,
                color: isBorrowed
                    ? FinancialPdfTheme.errorRed
                    : FinancialPdfTheme.successGreen,
              ),
              _td(
                FinancialPdfTheme.formatKes(r.loan.principalMinor),
                fonts,
                align: pw.TextAlign.right,
              ),
              _td(
                FinancialPdfTheme.formatKes(outstanding),
                fonts,
                align: pw.TextAlign.right,
                bold: true,
                color: isBorrowed
                    ? FinancialPdfTheme.errorRed
                    : FinancialPdfTheme.successGreen,
              ),
              _td(
                '${(r.loan.annualRateBp / 100).toStringAsFixed(1)}%',
                fonts,
                align: pw.TextAlign.right,
              ),
              _td(
                FinancialPdfTheme.formatKes(r.summary.interestPaidMinor),
                fonts,
                align: pw.TextAlign.right,
                color: FinancialPdfTheme.warningAmber,
              ),
              _td(
                FinancialPdfTheme.formatKes(r.interestRemainingMinor),
                fonts,
                align: pw.TextAlign.right,
              ),
              _td(
                '${r.summary.remainingMonths}',
                fonts,
                align: pw.TextAlign.right,
              ),
            ],
          );
        }),
      ],
    );
  }

  // ── 5. Investment Portfolio Table (Clean, No Shading) ──────────────────────

  static pw.Widget buildInvestmentTable({
    required List<Holding> holdings,
    required PdfThemeFonts fonts,
  }) {
    if (holdings.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 8),
        child: pw.Text(
          'No investment holdings recorded.',
          style: pw.TextStyle(
            font: fonts.italic,
            fontSize: 8.5,
            color: FinancialPdfTheme.slateMedium,
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: FinancialPdfTheme.borderColor, width: 0.8),
        bottom: pw.BorderSide(color: FinancialPdfTheme.borderColor, width: 0.8),
        horizontalInside: pw.BorderSide(
          color: FinancialPdfTheme.borderColor,
          width: 0.4,
        ),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.4), // Holding
        1: pw.FlexColumnWidth(1.6), // Institution
        2: pw.FlexColumnWidth(1.6), // Cost Basis
        3: pw.FlexColumnWidth(1.8), // Market Value
        4: pw.FlexColumnWidth(1.6), // Unrealised
        5: pw.FlexColumnWidth(1.2), // Return %
        6: pw.FlexColumnWidth(1.4), // Income
      },
      children: [
        pw.TableRow(
          children: [
            _th('Holding Name', fonts),
            _th('Institution', fonts),
            _th('Cost Basis', fonts, align: pw.TextAlign.right),
            _th('Market Value', fonts, align: pw.TextAlign.right),
            _th('Unrealised', fonts, align: pw.TextAlign.right),
            _th('Gain %', fonts, align: pw.TextAlign.right),
            _th('Income Rec.', fonts, align: pw.TextAlign.right),
          ],
        ),
        ...holdings.map((h) {
          final gain = h.unrealisedGainMinor;
          final isPos = gain >= 0;

          return pw.TableRow(
            children: [
              _td(h.name, fonts, bold: true),
              _td(h.institution, fonts),
              _td(
                FinancialPdfTheme.formatKes(h.totalCostBasisMinor),
                fonts,
                align: pw.TextAlign.right,
              ),
              _td(
                FinancialPdfTheme.formatKes(h.marketValueMinor),
                fonts,
                align: pw.TextAlign.right,
                bold: true,
                color: FinancialPdfTheme.primaryNavy,
              ),
              _td(
                FinancialPdfTheme.formatKesSigned(gain),
                fonts,
                align: pw.TextAlign.right,
                bold: true,
                color: isPos
                    ? FinancialPdfTheme.successGreen
                    : FinancialPdfTheme.errorRed,
              ),
              _td(
                '${isPos ? '+' : ''}${h.unrealisedGainPct.toStringAsFixed(1)}%',
                fonts,
                align: pw.TextAlign.right,
                color: isPos
                    ? FinancialPdfTheme.successGreen
                    : FinancialPdfTheme.errorRed,
              ),
              _td(
                '+${FinancialPdfTheme.formatKes(h.totalIncomeMinor)}',
                fonts,
                align: pw.TextAlign.right,
                color: FinancialPdfTheme.successGreen,
              ),
            ],
          );
        }),
      ],
    );
  }

  // ── 6. Fixed Asset Register Table (Clean, No Shading) ──────────────────────

  static pw.Widget buildAssetTable({
    required List<Asset> assets,
    required PdfThemeFonts fonts,
  }) {
    if (assets.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 8),
        child: pw.Text(
          'No physical assets registered.',
          style: pw.TextStyle(
            font: fonts.italic,
            fontSize: 8.5,
            color: FinancialPdfTheme.slateMedium,
          ),
        ),
      );
    }

    final now = DateTime.now();

    return pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: FinancialPdfTheme.borderColor, width: 0.8),
        bottom: pw.BorderSide(color: FinancialPdfTheme.borderColor, width: 0.8),
        horizontalInside: pw.BorderSide(
          color: FinancialPdfTheme.borderColor,
          width: 0.4,
        ),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.4), // Asset
        1: pw.FlexColumnWidth(1.4), // Class
        2: pw.FlexColumnWidth(1.6), // Acquired
        3: pw.FlexColumnWidth(1.6), // Cost
        4: pw.FlexColumnWidth(1.8), // Book Value
        5: pw.FlexColumnWidth(1.6), // Gain / Loss
        6: pw.FlexColumnWidth(1.2), // Insurance
      },
      children: [
        pw.TableRow(
          children: [
            _th('Asset Description', fonts),
            _th('Asset Class', fonts),
            _th('Acquisition', fonts),
            _th('Cost Basis', fonts, align: pw.TextAlign.right),
            _th('Book Value', fonts, align: pw.TextAlign.right),
            _th('Unrealised', fonts, align: pw.TextAlign.right),
            _th('Insurance', fonts, align: pw.TextAlign.center),
          ],
        ),
        ...assets.map((a) {
          final gl = a.bookValue - a.costMinor;
          final isInsured =
              a.insuranceExpiry != null && a.insuranceExpiry!.isAfter(now);

          return pw.TableRow(
            children: [
              _td(a.name, fonts, bold: true),
              _td(a.assetClass.name.toUpperCase(), fonts),
              _td(FinancialPdfTheme.formatDate(a.acquisitionDate), fonts),
              _td(
                FinancialPdfTheme.formatKes(a.costMinor),
                fonts,
                align: pw.TextAlign.right,
              ),
              _td(
                FinancialPdfTheme.formatKes(a.bookValue),
                fonts,
                align: pw.TextAlign.right,
                bold: true,
                color: FinancialPdfTheme.primaryNavy,
              ),
              _td(
                FinancialPdfTheme.formatKesSigned(gl),
                fonts,
                align: pw.TextAlign.right,
                color: gl >= 0
                    ? FinancialPdfTheme.successGreen
                    : FinancialPdfTheme.errorRed,
              ),
              _td(
                isInsured ? 'ACTIVE' : 'NONE',
                fonts,
                align: pw.TextAlign.center,
                bold: true,
                color: isInsured
                    ? FinancialPdfTheme.successGreen
                    : FinancialPdfTheme.warningAmber,
              ),
            ],
          );
        }),
      ],
    );
  }

  // ── Helper Row Builders (Clean, No Card Backgrounds, No Dark Headers) ──────

  static pw.Widget _statementHeader(String title, PdfThemeFonts fonts) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(0, 8, 0, 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: FinancialPdfTheme.borderColor, width: 0.8),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: fonts.bold,
          fontSize: 8,
          color: FinancialPdfTheme.primaryNavy,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  static pw.Widget _subHeaderRow(String label, PdfThemeFonts fonts) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(4, 5, 4, 3),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          font: fonts.bold,
          fontSize: 7.5,
          color: FinancialPdfTheme.slateMedium,
        ),
      ),
    );
  }

  static pw.Widget _statementDataRow({
    required bool indent,
    required String label,
    required String annotation,
    required String value,
    required PdfThemeFonts fonts,
    PdfColor? valueColor,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.fromLTRB(indent ? 12 : 4, 3.5, 4, 3.5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: FinancialPdfTheme.borderColor,
            width: 0.35,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(
                  font: fonts.regular,
                  fontSize: 7.5,
                  color: FinancialPdfTheme.slateDark,
                ),
              ),
              if (annotation.isNotEmpty) ...[
                pw.SizedBox(width: 5),
                pw.Text(
                  '($annotation)',
                  style: pw.TextStyle(
                    font: fonts.italic,
                    fontSize: 7,
                    color: FinancialPdfTheme.slateMedium,
                  ),
                ),
              ],
            ],
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 7.5,
              color: valueColor ?? FinancialPdfTheme.slateDark,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _subtotalRow(
    String label,
    String value,
    PdfThemeFonts fonts,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(8, 4, 4, 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: FinancialPdfTheme.borderColor,
            width: 0.5,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 7.5,
              color: FinancialPdfTheme.slateDark,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 7.5,
              color: FinancialPdfTheme.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _totalRow(
    String label,
    String value,
    PdfColor color,
    PdfThemeFonts fonts,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: FinancialPdfTheme.borderColor,
            width: 0.8,
          ),
          bottom: pw.BorderSide(
            color: FinancialPdfTheme.borderColor,
            width: 0.8,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 8,
              color: FinancialPdfTheme.primaryNavy,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 9,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _th(
    String text,
    PdfThemeFonts fonts, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4.5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: fonts.bold,
          fontSize: 7.5,
          color: FinancialPdfTheme.slateDark,
        ),
      ),
    );
  }

  static pw.Widget _td(
    String text,
    PdfThemeFonts fonts, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: bold ? fonts.bold : fonts.regular,
          fontSize: 7.5,
          color: color ?? FinancialPdfTheme.slateDark,
        ),
      ),
    );
  }
}
