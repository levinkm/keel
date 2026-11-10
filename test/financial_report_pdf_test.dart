import 'package:flutter_test/flutter_test.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/assets/domain/entities/asset.dart';
import 'package:keel/features/investments/domain/entities/holding.dart';
import 'package:keel/features/loans/domain/entities/loan.dart';
import 'package:keel/features/loans/domain/loan_engine.dart';
import 'package:keel/features/reports/domain/models/financial_report_data.dart';
import 'package:keel/features/reports/presentation/bloc/reports_cubit.dart';
import 'package:keel/features/reports/presentation/pdf/keel_pdf_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FinancialReportData', () {
    test(
      'computes balance sheet, trends, health score and insights accurately',
      () {
        final now = DateTime.now();

        final accounts = <Account>[
          Account(
            id: 'acc-1',
            name: 'Co-op Checking',
            type: AccountType.asset,
            currency: 'KES',
            liquidity: Liquidity.instant,
            isActive: true,
            createdAt: now,
          ),
          Account(
            id: 'acc-2',
            name: 'Loop Savings',
            type: AccountType.asset,
            currency: 'KES',
            liquidity: Liquidity.days,
            isActive: true,
            createdAt: now,
          ),
        ];

        final accountBalances = <String, int>{
          'acc-1': 15000000, // KES 150,000
          'acc-2': 35000000, // KES 350,000
        };

        final monthlyPnL = <MonthlyPnL>[
          const MonthlyPnL(
            period: '2026-08',
            incomeMinor: 20000000,
            expensesMinor: 14000000,
          ),
          const MonthlyPnL(
            period: '2026-09',
            incomeMinor: 22000000,
            expensesMinor: 15000000,
          ),
          const MonthlyPnL(
            period: '2026-10',
            incomeMinor: 25000000,
            expensesMinor: 16000000,
          ),
        ];

        final categories = <ExpenseCategory>[
          const ExpenseCategory(
            accountName: 'Housing & Rent',
            totalMinor: 20000000,
          ),
          const ExpenseCategory(
            accountName: 'Groceries & Supplies',
            totalMinor: 15000000,
          ),
          const ExpenseCategory(
            accountName: 'Transport & Fuel',
            totalMinor: 10000000,
          ),
        ];

        final holdings = <Holding>[
          Holding(
            id: 'h-1',
            name: 'Safaricom PLC',
            institution: 'Dykeman Securities',
            type: HoldingType.stock,
            accountId: 'acc-1',
            currency: 'KES',
            liquidity: Liquidity.days.toString(),
            currentPriceMinor: 3000,
            isActive: true,
            lots: [
              HoldingLot(
                id: 'lot-1',
                holdingId: 'h-1',
                date: now.subtract(const Duration(days: 90)),
                units: 5000,
                priceMinor: 2500,
                feesMinor: 0,
                currency: 'KES',
                lotType: LotType.purchase,
              ),
            ],
            createdAt: now,
          ),
        ];

        final assets = <Asset>[
          Asset(
            id: 'ast-1',
            name: 'Toyota Land Cruiser',
            assetClass: AssetClass.vehicle,
            acquisitionDate: DateTime(2024, 1, 15),
            costMinor: 350000000, // KES 3,500,000
            currency: 'KES',
            ownershipShareBp: 10000,
            currentValueMinor: 310000000,
            salvageMinor: 50000000,
            valuationDate: now,
            status: AssetStatus.inUse,
            createdAt: now,
          ),
        ];

        final loan = Loan(
          id: 'ln-1',
          direction: LoanDirection.borrowed,
          counterparty: 'StanChart Auto Loan',
          principalMinor: 150000000,
          currency: 'KES',
          interestMethod: InterestMethod.reducingBalance,
          annualRateBp: 1350,
          termMonths: 36,
          disbursementDate: DateTime(2024, 2, 1),
          firstDueDate: DateTime(2024, 3, 1),
          instalmentMinor: 5092000,
          isSalaryDeducted: false,
          status: LoanStatus.active,
          createdAt: now,
        );

        final summary = LoanSummary(
          outstandingMinor: 100000000, // KES 1,000,000
          totalPaidMinor: 68000000,
          principalPaidMinor: 50000000,
          interestPaidMinor: 18000000,
          totalInterestMinor: 33000000,
          remainingMonths: 24,
          missedPayments: 0,
          nextDueDate: now.add(const Duration(days: 15)),
          isOverdue: false,
          daysOverdue: 0,
          schedule: const [],
        );

        final loanRows = <LoanReportRow>[
          LoanReportRow(loan: loan, summary: summary),
        ];

        final reportData = FinancialReportData.fromState(
          monthlyPnL: monthlyPnL,
          expenseCategories: categories,
          topPayees: const [PayeeRow(name: 'Quickmart', totalMinor: 8000000)],
          budgetVsActual: const [],
          loanRows: loanRows,
          holdings: holdings,
          assets: assets,
          accounts: accounts,
          accountBalances: accountBalances,
        );

        // Verify Balance Sheet calculations
        expect(reportData.balanceSheet.totalCashMinor, 50000000); // KES 500k
        expect(reportData.balanceSheet.liquidCashMinor, 50000000);
        expect(
          reportData.balanceSheet.totalInvestmentsMarketMinor,
          15000000,
        ); // 5000 units * 3000 = 150k
        expect(
          reportData.balanceSheet.totalPhysicalBookMinor,
          310000000,
        ); // KES 3.1M
        expect(
          reportData.balanceSheet.totalAssetsMinor,
          375000000,
        ); // 500k + 150k + 3.1M = 3.75M
        expect(reportData.balanceSheet.totalLiabilitiesMinor, 100000000); // 1M
        expect(
          reportData.balanceSheet.netWorthMinor,
          275000000,
        ); // 3.75M - 1M = 2.75M

        // Verify Income Statement & Trends
        expect(reportData.incomeStatement.totalIncomeMinor, 67000000);
        expect(reportData.incomeStatement.totalExpensesMinor, 45000000);
        expect(reportData.incomeStatement.totalNetMinor, 22000000);
        expect(reportData.trends.runwayMonths, greaterThan(3.0));

        // Verify Health Score & Insights
        expect(reportData.healthScore.score, greaterThan(60));
        expect(reportData.insights.observations, isNotEmpty);
        expect(reportData.insights.recommendations, isNotEmpty);
        expect(reportData.insights.executiveSummary, contains('KES'));
      },
    );
  });

  group('KeelPdfExporter', () {
    test(
      'builds comprehensive report document and saves to PDF bytes',
      () async {
        final now = DateTime.now();

        final accounts = <Account>[
          Account(
            id: 'acc-1',
            name: 'Main Checking',
            type: AccountType.asset,
            currency: 'KES',
            liquidity: Liquidity.instant,
            isActive: true,
            createdAt: now,
          ),
        ];

        final reportData = FinancialReportData.fromState(
          monthlyPnL: [
            const MonthlyPnL(
              period: '2026-09',
              incomeMinor: 20000000,
              expensesMinor: 12000000,
            ),
            const MonthlyPnL(
              period: '2026-10',
              incomeMinor: 24000000,
              expensesMinor: 14000000,
            ),
          ],
          expenseCategories: const [
            ExpenseCategory(accountName: 'Rent', totalMinor: 10000000),
          ],
          topPayees: const [PayeeRow(name: 'Landlord', totalMinor: 10000000)],
          budgetVsActual: const [],
          loanRows: const [],
          holdings: const [],
          assets: const [],
          accounts: accounts,
          accountBalances: const {'acc-1': 45000000},
        );

        final doc = await KeelPdfExporter.generateComprehensiveReport(
          data: reportData,
        );
        expect(doc.document.pdfPageList.pages.length, greaterThanOrEqualTo(5));

        final bytes = await doc.save();
        expect(bytes, isNotEmpty);
        expect(bytes.length, greaterThan(1000));
      },
    );

    test(
      'builds domain-specific report documents and saves to PDF bytes',
      () async {
        final now = DateTime.now();
        final accounts = <Account>[
          Account(
            id: 'acc-1',
            name: 'Main Checking',
            type: AccountType.asset,
            currency: 'KES',
            liquidity: Liquidity.instant,
            isActive: true,
            createdAt: now,
          ),
        ];

        final reportData = FinancialReportData.fromState(
          monthlyPnL: [
            const MonthlyPnL(
              period: '2026-10',
              incomeMinor: 20000000,
              expensesMinor: 12000000,
            ),
          ],
          expenseCategories: const [
            ExpenseCategory(accountName: 'Food', totalMinor: 5000000),
          ],
          topPayees: const [],
          budgetVsActual: const [],
          loanRows: const [],
          holdings: const [],
          assets: const [],
          accounts: accounts,
          accountBalances: const {'acc-1': 10000000},
        );

        for (final domain in [
          ReportDomain.pnl,
          ReportDomain.budget,
          ReportDomain.loans,
          ReportDomain.investments,
          ReportDomain.assets,
        ]) {
          final doc = await KeelPdfExporter.generateDomainReport(
            domain: domain,
            data: reportData,
          );
          final bytes = await doc.save();
          expect(bytes, isNotEmpty);
        }
      },
    );
  });
}
