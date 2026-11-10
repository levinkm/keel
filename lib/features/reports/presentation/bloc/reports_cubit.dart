import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:keel/features/assets/domain/entities/asset.dart';
import 'package:keel/features/assets/domain/repositories/assets_repository.dart';
import 'package:keel/features/budget/domain/repositories/budget_repository.dart';
import 'package:keel/features/investments/domain/entities/holding.dart';
import 'package:keel/features/investments/domain/repositories/investments_repository.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:keel/features/loans/domain/entities/loan.dart';
import 'package:keel/features/loans/domain/loan_engine.dart';
import 'package:keel/features/loans/domain/repositories/loans_repository.dart';
import 'package:keel/features/reports/domain/models/financial_report_data.dart';
import 'package:keel/features/reports/presentation/pdf/keel_pdf_exporter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

part 'reports_state.dart';
part 'reports_cubit.freezed.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final LedgerRepository _ledgerRepo;
  final AccountsRepository _accountsRepo;
  final BudgetRepository _budgetRepo;
  final LoansRepository _loansRepo;
  final InvestmentsRepository _investmentsRepo;
  final AssetsRepository _assetsRepo;

  ReportsCubit(this._ledgerRepo, this._accountsRepo, this._budgetRepo,
      this._loansRepo, this._investmentsRepo, this._assetsRepo)
      : super(const ReportsState.initial());

  Future<void> load() async {
    emit(const ReportsState.loading());
    try {
      final accountsResult = await _accountsRepo.getAccounts();
      final accounts = accountsResult.fold((_) => <Account>[], (a) => a);
      final accountMap = {for (final a in accounts) a.id: a};
      final balancesResult = await _ledgerRepo.getAccountBalances();
      final accountBalances = balancesResult.fold((_) => <String, int>{}, (b) => b);
      final incomeIds = accounts.where((a) => a.type == AccountType.income).map((a) => a.id).toSet();
      final expenseIds = accounts.where((a) => a.type == AccountType.expense).map((a) => a.id).toSet();

      final now = DateTime.now();

      // ── 12-month P&L + expense breakdown + payee analysis ─────────────────
      final monthlyPnL = <MonthlyPnL>[];
      final expenseByAccount = <String, int>{}; // accountId -> total 12mo
      final payeeSpend = <String, int>{}; // payee -> total spend
      final allEntries12mo = <JournalEntry>[];

      for (int i = 11; i >= 0; i--) {
        var m = now.month - i;
        var y = now.year;
        while (m <= 0) { m += 12; y--; }
        final period = '$y-${m.toString().padLeft(2, '0')}';
        final result = await _ledgerRepo.getEntriesByPeriod(period);
        final entries = result.fold((_) => <JournalEntry>[], (e) => e);
        allEntries12mo.addAll(entries);
        int income = 0, expenses = 0;
        for (final entry in entries) {
          final payee = entry.payee ?? entry.description;
          for (final line in entry.lines) {
            if (incomeIds.contains(line.accountId) && line.side == JournalSide.credit) {
              income += line.amountMinor;
            }
            if (expenseIds.contains(line.accountId) && line.side == JournalSide.debit) {
              expenses += line.amountMinor;
              expenseByAccount[line.accountId] =
                  (expenseByAccount[line.accountId] ?? 0) + line.amountMinor;
              payeeSpend[payee] = (payeeSpend[payee] ?? 0) + line.amountMinor;
            }
          }
        }
        monthlyPnL.add(MonthlyPnL(period: period, incomeMinor: income, expensesMinor: expenses));
      }

      // Top expense categories
      final expenseCategories = expenseByAccount.entries
          .map((e) => ExpenseCategory(
                accountName: accountMap[e.key]?.name ?? e.key,
                totalMinor: e.value,
              ))
          .toList()
        ..sort((a, b) => b.totalMinor.compareTo(a.totalMinor));

      // Top payees
      final topPayees = payeeSpend.entries
          .map((e) => PayeeRow(name: e.key, totalMinor: e.value))
          .toList()
        ..sort((a, b) => b.totalMinor.compareTo(a.totalMinor));

      // ── Budget vs Actual with per-line breakdown ───────────────────────────
      final budgetRows = <BudgetVsActual>[];
      for (int i = 5; i >= 0; i--) {
        var m = now.month - i;
        var y = now.year;
        while (m <= 0) { m += 12; y--; }
        final period = '$y-${m.toString().padLeft(2, '0')}';
        final budgetResult = await _budgetRepo.getPlanByPeriod(period);
        final plan = budgetResult.fold((_) => null, (p) => p);
        if (plan == null) continue;
        final entriesResult = await _ledgerRepo.getEntriesByPeriod(period);
        final entries = entriesResult.fold((_) => <JournalEntry>[], (e) => e);

        // Actual per account
        final actualByAccount = <String, int>{};
        for (final entry in entries) {
          for (final line in entry.lines) {
            if (expenseIds.contains(line.accountId) && line.side == JournalSide.debit) {
              actualByAccount[line.accountId] =
                  (actualByAccount[line.accountId] ?? 0) + line.amountMinor;
            }
          }
        }

        final lineRows = plan.lines.map((l) {
          final actual = actualByAccount[l.accountId] ?? 0;
          return BudgetLineRow(
            accountName: accountMap[l.accountId]?.name ?? l.accountId,
            bucket: l.bucket,
            plannedMinor: l.plannedMinor,
            actualMinor: actual,
          );
        }).toList()
          ..sort((a, b) => b.plannedMinor.compareTo(a.plannedMinor));

        final planned = plan.lines.fold<int>(0, (s, l) => s + l.plannedMinor);
        final actual = actualByAccount.values.fold<int>(0, (s, v) => s + v);
        budgetRows.add(BudgetVsActual(
          period: period,
          plannedMinor: planned,
          actualMinor: actual,
          lines: lineRows,
        ));
      }

      // ── Loan summary with cost of borrowing ───────────────────────────────
      final loansResult = await _loansRepo.getLoans();
      final loans = loansResult.fold((_) => <Loan>[], (l) => l);
      final loanRows = <LoanReportRow>[];
      for (final loan in loans) {
        final eventsResult = await _loansRepo.getEventsForLoan(loan.id);
        final events = eventsResult.fold((_) => <LoanEvent>[], (e) => e);
        final summary = LoanEngine.compute(loan, events);
        loanRows.add(LoanReportRow(loan: loan, summary: summary));
      }

      // ── Investment performance ─────────────────────────────────────────────
      final holdingsResult = await _investmentsRepo.getHoldings();
      final holdings = holdingsResult.fold((_) => <Holding>[], (h) => h);

      // ── Asset summary ──────────────────────────────────────────────────────
      final assetsResult = await _assetsRepo.getAssets();
      final assets = assetsResult.fold((_) => <Asset>[], (a) => a)
          .where((a) => a.holdingId == null)
          .toList();

      emit(ReportsState.loaded(
        monthlyPnL: monthlyPnL,
        expenseCategories: expenseCategories,
        topPayees: topPayees.take(10).toList(),
        budgetVsActual: budgetRows,
        loanRows: loanRows,
        holdings: holdings,
        assets: assets,
        accounts: accounts,
        allEntries: allEntries12mo,
        accountBalances: accountBalances,
      ));
    } catch (e) {
      emit(ReportsState.error(e.toString()));
    }
  }

  // ── High-Fidelity PDF Exports with Graphs, Trends & Insights ─────────────

  Future<void> exportComprehensivePdf() async {
    await state.maybeWhen(
      loaded: (monthlyPnL, expenseCategories, topPayees, budgetVsActual,
          loanRows, holdings, assets, accounts, allEntries, accountBalances) async {
        final data = FinancialReportData.fromState(
          monthlyPnL: monthlyPnL,
          expenseCategories: expenseCategories,
          topPayees: topPayees,
          budgetVsActual: budgetVsActual,
          loanRows: loanRows,
          holdings: holdings,
          assets: assets,
          accounts: accounts,
          accountBalances: accountBalances,
        );

        final logoBytes = await _loadAssetBytes('assets/png/logos/keel_icon_1024.png');
        final wordmarkBytes = await _loadAssetBytes('assets/png/logos/keel_wordmark_1024.png');

        final doc = await KeelPdfExporter.generateComprehensiveReport(
          data: data,
          logoBytes: logoBytes,
          wordmarkBytes: wordmarkBytes,
        );

        final dateStr = _dateStamp();
        await Printing.layoutPdf(
          onLayout: (_) async => doc.save(),
          name: 'Keel_Comprehensive_Financial_Statement_$dateStr.pdf',
        );
      },
      orElse: () async {},
    );
  }

  Future<void> exportDomainPdf(ReportDomain domain) async {
    await state.maybeWhen(
      loaded: (monthlyPnL, expenseCategories, topPayees, budgetVsActual,
          loanRows, holdings, assets, accounts, allEntries, accountBalances) async {
        final data = FinancialReportData.fromState(
          monthlyPnL: monthlyPnL,
          expenseCategories: expenseCategories,
          topPayees: topPayees,
          budgetVsActual: budgetVsActual,
          loanRows: loanRows,
          holdings: holdings,
          assets: assets,
          accounts: accounts,
          accountBalances: accountBalances,
        );

        final logoBytes = await _loadAssetBytes('assets/png/logos/keel_icon_1024.png');
        final wordmarkBytes = await _loadAssetBytes('assets/png/logos/keel_wordmark_1024.png');

        final doc = await KeelPdfExporter.generateDomainReport(
          domain: domain,
          data: data,
          logoBytes: logoBytes,
          wordmarkBytes: wordmarkBytes,
        );

        final dateStr = _dateStamp();
        final domainName = domain.name.toUpperCase();
        await Printing.layoutPdf(
          onLayout: (_) async => doc.save(),
          name: 'Keel_${domainName}_Statement_$dateStr.pdf',
        );
      },
      orElse: () async {},
    );
  }

  // ── Legacy PDF export ──────────────────────────────────────────────────────

  Future<void> generatePdf(String title, List<String> headers,
      List<List<String>> rows, List<String> kpis) async {
    // Load Unicode-capable fonts
    final regular = await PdfGoogleFonts.interRegular();
    final bold = await PdfGoogleFonts.interBold();
    final italic = await PdfGoogleFonts.interItalic();

    // Load logo from assets
    final logoBytes = await _loadAssetBytes('assets/png/logos/keel_icon_1024.png');
    final wordmarkBytes = await _loadAssetBytes('assets/png/logos/keel_wordmark_1024.png');
    final logoImage = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
    final wordmarkImage = wordmarkBytes != null ? pw.MemoryImage(wordmarkBytes) : null;

    final doc = pw.Document();
    final now = DateTime.now();
    final dateStr = '${now.day} ${_monthName(now.month)} ${now.year}';

    // Colours
    const blue = PdfColor.fromInt(0xFF4169E1);
    const lightGrey = PdfColor.fromInt(0xFFF4F7FC);
    const darkGrey = PdfColor.fromInt(0xFF68758B);
    const black = PdfColor.fromInt(0xFF18243A);
    const white = PdfColors.white;
    const borderColor = PdfColor.fromInt(0xFFDFE7F5);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Logo + wordmark
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        width: 32, height: 32,
                        decoration: pw.BoxDecoration(
                          borderRadius: pw.BorderRadius.circular(7),
                        ),
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      ),
                    pw.SizedBox(width: 8),
                    if (wordmarkImage != null)
                      pw.Image(wordmarkImage, width: 48, height: 16,
                          fit: pw.BoxFit.contain)
                    else
                      pw.Text('Keel',
                          style: pw.TextStyle(
                              font: bold, fontSize: 18, color: blue)),
                  ],
                ),
                // Report title + date
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(title,
                        style: pw.TextStyle(
                            font: bold, fontSize: 12, color: black)),
                    pw.Text('Generated $dateStr',
                        style: pw.TextStyle(
                            font: regular, fontSize: 9, color: darkGrey)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: borderColor),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (ctx) => [
          // KPI summary row
          if (kpis.isNotEmpty) ...
            [
              pw.Row(
                children: kpis.map((k) => pw.Expanded(
                  child: pw.Container(
                    margin: const pw.EdgeInsets.only(right: 8),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: lightGrey,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(k,
                        style: pw.TextStyle(font: regular, fontSize: 9, color: darkGrey)),
                  ),
                )).toList(),
              ),
              pw.SizedBox(height: 16),
            ],

          // Table
          pw.Table(
            border: pw.TableBorder(
              bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFDFE7F5)),
              horizontalInside: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFDFE7F5), width: 0.5),
            ),
            columnWidths: {for (int i = 0; i < headers.length; i++)
                i: const pw.FlexColumnWidth()},
            children: [
              // Header row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: blue),
                children: headers.map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  child: pw.Text(h,
                      style: pw.TextStyle(
                          font: bold,
                          fontSize: 8,
                          color: white)),
                )).toList(),
              ),
              // Data rows
              ...rows.asMap().entries.map((e) {
                final isEven = e.key % 2 == 0;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: isEven ? white : lightGrey),
                  children: e.value.map((cell) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    child: pw.Text(
                        // Replace Unicode minus with ASCII hyphen for safety
                        cell.replaceAll('\u2212', '-'),
                        style: pw.TextStyle(
                            font: regular,
                            fontSize: 8,
                            color: black)),
                  )).toList(),
                );
              }),
            ],
          ),

          // Footer note
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'All amounts in KES. Generated by Keel personal finance app.',
                style: pw.TextStyle(font: italic, fontSize: 8, color: darkGrey),
              ),
              if (logoImage != null)
                pw.Opacity(
                  opacity: 0.4,
                  child: pw.Image(logoImage, width: 16, height: 16,
                      fit: pw.BoxFit.contain),
                ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: '${title.replaceAll(' ', '_')}_$dateStr.pdf',
    );
  }

  String _monthName(int m) {
    const months = ['', 'January', 'February', 'March', 'April', 'May',
        'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[m];
  }

  // ── CSV export ─────────────────────────────────────────────────────────────

  Future<String?> exportCsv(String reportName, List<List<String>> rows) async {
    try {
      final result = await Process.run('osascript', [
        '-e',
        'POSIX path of (choose folder with prompt "Choose export location")'
      ]);
      if (result.exitCode != 0) return null;
      final folder = (result.stdout as String).trim();
      if (folder.isEmpty) return null;
      final stamp = _dateStamp();
      final path = '$folder/keel_${reportName}_$stamp.csv';
      final csv = rows.map((r) => r.map(_escapeCsv).join(',')).join('\n');
      await File(path).writeAsString(csv);
      return path;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _loadAssetBytes(String path) async {
    try {
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  String _escapeCsv(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  String _dateStamp() {
    final n = DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class MonthlyPnL {
  final String period;
  final int incomeMinor;
  final int expensesMinor;
  const MonthlyPnL({required this.period, required this.incomeMinor, required this.expensesMinor});
  int get netMinor => incomeMinor - expensesMinor;
  double get savingsRate => incomeMinor > 0 ? netMinor / incomeMinor : 0;
}

class ExpenseCategory {
  final String accountName;
  final int totalMinor;
  const ExpenseCategory({required this.accountName, required this.totalMinor});
}

class PayeeRow {
  final String name;
  final int totalMinor;
  const PayeeRow({required this.name, required this.totalMinor});
}

class BudgetLineRow {
  final String accountName;
  final String bucket;
  final int plannedMinor;
  final int actualMinor;
  const BudgetLineRow({required this.accountName, required this.bucket,
      required this.plannedMinor, required this.actualMinor});
  int get varianceMinor => plannedMinor - actualMinor;
  bool get isUnder => actualMinor <= plannedMinor;
  double get usedPct => plannedMinor > 0 ? (actualMinor / plannedMinor).clamp(0.0, 2.0) : 0;
}

class BudgetVsActual {
  final String period;
  final int plannedMinor;
  final int actualMinor;
  final List<BudgetLineRow> lines;
  const BudgetVsActual({required this.period, required this.plannedMinor,
      required this.actualMinor, required this.lines});
  int get varianceMinor => plannedMinor - actualMinor;
  bool get isUnder => actualMinor <= plannedMinor;
}

class LoanReportRow {
  final Loan loan;
  final LoanSummary summary;
  const LoanReportRow({required this.loan, required this.summary});
  int get totalCostMinor => loan.principalMinor + summary.totalInterestMinor;
  int get interestRemainingMinor =>
      summary.totalInterestMinor - summary.interestPaidMinor;
}
