import 'dart:math';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/assets/domain/entities/asset.dart';
import 'package:keel/features/investments/domain/entities/holding.dart';
import 'package:keel/features/loans/domain/entities/loan.dart';
import 'package:keel/features/reports/presentation/bloc/reports_cubit.dart';

/// Encapsulates structured financial data, trend metrics, formal accounting
/// statements, and analytical diagnostic insights for PDF generation.
class FinancialReportData {
  final DateTime asOf;
  final String currency;

  // Domain state
  final List<MonthlyPnL> monthlyPnL;
  final List<ExpenseCategory> expenseCategories;
  final List<PayeeRow> topPayees;
  final List<BudgetVsActual> budgetVsActual;
  final List<LoanReportRow> loanRows;
  final List<Holding> holdings;
  final List<Asset> assets;
  final List<Account> accounts;
  final Map<String, int> accountBalances;

  // Synthesized Financial Statements
  final BalanceSheetStatement balanceSheet;
  final IncomeStatementStatement incomeStatement;
  final BudgetPerformanceStatement budgetPerformance;
  final DebtScheduleStatement debtSchedule;
  final InvestmentPortfolioStatement investmentPortfolio;
  final FixedAssetRegisterStatement assetRegister;

  // Insights & Diagnostics
  final FinancialHealthScore healthScore;
  final FinancialTrends trends;
  final FinancialInsights insights;

  const FinancialReportData({
    required this.asOf,
    required this.currency,
    required this.monthlyPnL,
    required this.expenseCategories,
    required this.topPayees,
    required this.budgetVsActual,
    required this.loanRows,
    required this.holdings,
    required this.assets,
    required this.accounts,
    required this.accountBalances,
    required this.balanceSheet,
    required this.incomeStatement,
    required this.budgetPerformance,
    required this.debtSchedule,
    required this.investmentPortfolio,
    required this.assetRegister,
    required this.healthScore,
    required this.trends,
    required this.insights,
  });

  factory FinancialReportData.fromState({
    required List<MonthlyPnL> monthlyPnL,
    required List<ExpenseCategory> expenseCategories,
    required List<PayeeRow> topPayees,
    required List<BudgetVsActual> budgetVsActual,
    required List<LoanReportRow> loanRows,
    required List<Holding> holdings,
    required List<Asset> assets,
    required List<Account> accounts,
    required Map<String, int> accountBalances,
    DateTime? asOfDate,
  }) {
    final asOf = asOfDate ?? DateTime.now();
    const currency = 'KES';

    // ── 1. Balance Sheet Computation ──────────────────────────────────────────
    final cashAccounts = <AccountBalanceItem>[];
    for (final a in accounts.where((a) => a.type == AccountType.asset && a.isActive)) {
      final bal = accountBalances[a.id] ?? 0;
      cashAccounts.add(AccountBalanceItem(
        id: a.id,
        name: a.name,
        liquidity: a.liquidity,
        balanceMinor: bal,
      ));
    }
    cashAccounts.sort((a, b) => b.balanceMinor.compareTo(a.balanceMinor));

    final totalCashMinor = cashAccounts.fold<int>(0, (s, a) => s + a.balanceMinor);
    final liquidCashMinor = cashAccounts
        .where((a) => a.liquidity == Liquidity.instant || a.liquidity == Liquidity.days)
        .fold<int>(0, (s, a) => s + a.balanceMinor);

    final activeHoldings = holdings.where((h) => h.isActive).toList()
      ..sort((a, b) => b.marketValueMinor.compareTo(a.marketValueMinor));
    final totalInvestmentsCostMinor =
        activeHoldings.fold<int>(0, (s, h) => s + h.totalCostBasisMinor);
    final totalInvestmentsMarketMinor =
        activeHoldings.fold<int>(0, (s, h) => s + h.marketValueMinor);

    final physicalAssets = assets
        .where((a) => a.holdingId == null && a.status == AssetStatus.inUse)
        .toList()
      ..sort((a, b) => b.bookValue.compareTo(a.bookValue));
    final totalPhysicalCostMinor =
        physicalAssets.fold<int>(0, (s, a) => s + a.costMinor);
    final totalPhysicalBookMinor =
        physicalAssets.fold<int>(0, (s, a) => s + a.bookValue);

    final totalAssetsMinor =
        totalCashMinor + totalInvestmentsMarketMinor + totalPhysicalBookMinor;

    final borrowedLoans = loanRows
        .where((r) => r.loan.direction == LoanDirection.borrowed)
        .toList();
    final totalDebtMinor =
        borrowedLoans.fold<int>(0, (s, r) => s + r.summary.outstandingMinor);
    final totalLiabilitiesMinor = totalDebtMinor;

    final netWorthMinor = totalAssetsMinor - totalLiabilitiesMinor;
    final liquidNetWorthMinor = liquidCashMinor - totalLiabilitiesMinor;
    final illiquidNetWorthMinor =
        totalInvestmentsMarketMinor + totalPhysicalBookMinor;

    final balanceSheet = BalanceSheetStatement(
      cashAccounts: cashAccounts,
      totalCashMinor: totalCashMinor,
      liquidCashMinor: liquidCashMinor,
      holdings: activeHoldings,
      totalInvestmentsCostMinor: totalInvestmentsCostMinor,
      totalInvestmentsMarketMinor: totalInvestmentsMarketMinor,
      physicalAssets: physicalAssets,
      totalPhysicalCostMinor: totalPhysicalCostMinor,
      totalPhysicalBookMinor: totalPhysicalBookMinor,
      totalAssetsMinor: totalAssetsMinor,
      borrowedLoans: borrowedLoans,
      totalLiabilitiesMinor: totalLiabilitiesMinor,
      netWorthMinor: netWorthMinor,
      liquidNetWorthMinor: liquidNetWorthMinor,
      illiquidNetWorthMinor: illiquidNetWorthMinor,
    );

    // ── 2. Income Statement & P&L Computation ───────────────────────────────
    final total12moIncome = monthlyPnL.fold<int>(0, (s, d) => s + d.incomeMinor);
    final total12moExpenses =
        monthlyPnL.fold<int>(0, (s, d) => s + d.expensesMinor);
    final total12moNet = total12moIncome - total12moExpenses;
    final annualSavingsRate =
        total12moIncome > 0 ? total12moNet / total12moIncome : 0.0;

    // Monthly rows with MoM calculations
    final monthlyTrends = <MonthlyTrendItem>[];
    for (int i = 0; i < monthlyPnL.length; i++) {
      final current = monthlyPnL[i];
      MonthlyPnL? prev = i > 0 ? monthlyPnL[i - 1] : null;

      double momIncPct = 0.0;
      if (prev != null && prev.incomeMinor > 0) {
        momIncPct = (current.incomeMinor - prev.incomeMinor) / prev.incomeMinor;
      }

      double momExpPct = 0.0;
      if (prev != null && prev.expensesMinor > 0) {
        momExpPct = (current.expensesMinor - prev.expensesMinor) / prev.expensesMinor;
      }

      monthlyTrends.add(MonthlyTrendItem(
        pnl: current,
        momIncomePct: momIncPct,
        momExpensePct: momExpPct,
        momNetChangeMinor: prev != null ? current.netMinor - prev.netMinor : 0,
      ));
    }

    final incomeStatement = IncomeStatementStatement(
      monthlyTrends: monthlyTrends,
      totalIncomeMinor: total12moIncome,
      totalExpensesMinor: total12moExpenses,
      totalNetMinor: total12moNet,
      savingsRate: annualSavingsRate,
      topCategories: expenseCategories,
      topPayees: topPayees,
    );

    // ── 3. Budget Statement Computation ─────────────────────────────────────
    final totalPlannedMinor =
        budgetVsActual.fold<int>(0, (s, b) => s + b.plannedMinor);
    final totalActualMinor =
        budgetVsActual.fold<int>(0, (s, b) => s + b.actualMinor);
    final totalBudgetVarianceMinor = totalPlannedMinor - totalActualMinor;
    final periodsUnderCount =
        budgetVsActual.where((b) => b.isUnder).length;
    final budgetCompliancePct = budgetVsActual.isNotEmpty
        ? periodsUnderCount / budgetVsActual.length
        : 1.0;

    final budgetPerformance = BudgetPerformanceStatement(
      periods: budgetVsActual,
      totalPlannedMinor: totalPlannedMinor,
      totalActualMinor: totalActualMinor,
      totalVarianceMinor: totalBudgetVarianceMinor,
      periodsUnderCount: periodsUnderCount,
      totalPeriods: budgetVsActual.length,
      compliancePct: budgetCompliancePct,
    );

    // ── 4. Debt Schedule Statement Computation ──────────────────────────────
    final totalInterestPaidMinor =
        borrowedLoans.fold<int>(0, (s, r) => s + r.summary.interestPaidMinor);
    final totalProjectedInterestMinor =
        borrowedLoans.fold<int>(0, (s, r) => s + r.summary.totalInterestMinor);
    final totalCostOfBorrowingMinor =
        borrowedLoans.fold<int>(0, (s, r) => s + r.totalCostMinor);
    final lentLoans =
        loanRows.where((r) => r.loan.direction == LoanDirection.lent).toList();
    final totalLentMinor =
        lentLoans.fold<int>(0, (s, r) => s + r.summary.outstandingMinor);

    final debtSchedule = DebtScheduleStatement(
      borrowedLoans: borrowedLoans,
      lentLoans: lentLoans,
      totalOutstandingMinor: totalDebtMinor,
      totalInterestPaidMinor: totalInterestPaidMinor,
      totalProjectedInterestMinor: totalProjectedInterestMinor,
      totalCostOfBorrowingMinor: totalCostOfBorrowingMinor,
      totalLentMinor: totalLentMinor,
    );

    // ── 5. Investment Portfolio Statement ───────────────────────────────────
    final totalUnrealisedGainMinor = activeHoldings.fold<int>(
        0, (s, h) => s + h.unrealisedGainMinor);
    final totalRealisedGainMinor = activeHoldings.fold<int>(
        0, (s, h) => s + h.realisedGainMinor);
    final totalInvestmentIncomeMinor =
        activeHoldings.fold<int>(0, (s, h) => s + h.totalIncomeMinor);
    final totalInvestmentReturnMinor = totalUnrealisedGainMinor +
        totalRealisedGainMinor +
        totalInvestmentIncomeMinor;

    final investmentPortfolio = InvestmentPortfolioStatement(
      holdings: activeHoldings,
      totalCostBasisMinor: totalInvestmentsCostMinor,
      totalMarketValueMinor: totalInvestmentsMarketMinor,
      totalUnrealisedGainMinor: totalUnrealisedGainMinor,
      totalRealisedGainMinor: totalRealisedGainMinor,
      totalIncomeMinor: totalInvestmentIncomeMinor,
      totalReturnMinor: totalInvestmentReturnMinor,
    );

    // ── 6. Fixed Asset Register Statement ───────────────────────────────────
    final insuredCount = physicalAssets
        .where((a) =>
            a.insuranceExpiry != null && a.insuranceExpiry!.isAfter(asOf))
        .length;

    final assetRegister = FixedAssetRegisterStatement(
      assets: physicalAssets,
      totalCostMinor: totalPhysicalCostMinor,
      totalBookValueMinor: totalPhysicalBookMinor,
      totalRevaluationMinor: totalPhysicalBookMinor - totalPhysicalCostMinor,
      insuredCount: insuredCount,
    );

    // ── 7. Trends Analysis ──────────────────────────────────────────────────
    final nonZeroMonths = monthlyPnL.where((m) => m.incomeMinor > 0 || m.expensesMinor > 0).toList();
    final monthsCount = max(1, nonZeroMonths.length);
    final avgMonthlyExpenses = total12moExpenses ~/ monthsCount;
    final avgMonthlyIncome = total12moIncome ~/ monthsCount;

    // Runway
    final runwayMonths = avgMonthlyExpenses > 0
        ? liquidCashMinor / avgMonthlyExpenses
        : (liquidCashMinor > 0 ? 24.0 : 0.0);

    // MoM latest vs previous
    MonthlyTrendItem? latestMonth = monthlyTrends.isNotEmpty ? monthlyTrends.last : null;
    MonthlyTrendItem? prevMonth =
        monthlyTrends.length > 1 ? monthlyTrends[monthlyTrends.length - 2] : null;

    final incomeMoM = TrendMetric(
      title: 'Monthly Inflow',
      currentValue: latestMonth?.pnl.incomeMinor ?? 0,
      previousValue: prevMonth?.pnl.incomeMinor ?? 0,
      changePct: latestMonth?.momIncomePct ?? 0.0,
      isFavorable: (latestMonth?.momIncomePct ?? 0.0) >= 0,
    );

    final expenseMoM = TrendMetric(
      title: 'Monthly Outflow',
      currentValue: latestMonth?.pnl.expensesMinor ?? 0,
      previousValue: prevMonth?.pnl.expensesMinor ?? 0,
      changePct: latestMonth?.momExpensePct ?? 0.0,
      isFavorable: (latestMonth?.momExpensePct ?? 0.0) <= 0,
    );

    final netMoM = TrendMetric(
      title: 'Net Surplus',
      currentValue: latestMonth?.pnl.netMinor ?? 0,
      previousValue: prevMonth?.pnl.netMinor ?? 0,
      changePct: prevMonth != null && prevMonth.pnl.netMinor.abs() > 0
          ? (latestMonth!.pnl.netMinor - prevMonth.pnl.netMinor) /
              prevMonth.pnl.netMinor.abs()
          : 0.0,
      isFavorable: (latestMonth?.pnl.netMinor ?? 0) >= (prevMonth?.pnl.netMinor ?? 0),
    );

    // 3-month savings rate vs 12-month
    final last3Months = nonZeroMonths.length >= 3
        ? nonZeroMonths.sublist(nonZeroMonths.length - 3)
        : nonZeroMonths;
    final last3Income = last3Months.fold<int>(0, (s, m) => s + m.incomeMinor);
    final last3Net = last3Months.fold<int>(0, (s, m) => s + m.netMinor);
    final last3SavingsRate =
        last3Income > 0 ? last3Net / last3Income : annualSavingsRate;

    final trends = FinancialTrends(
      avgMonthlyIncome: avgMonthlyIncome,
      avgMonthlyExpenses: avgMonthlyExpenses,
      runwayMonths: runwayMonths,
      incomeMoM: incomeMoM,
      expenseMoM: expenseMoM,
      netMoM: netMoM,
      annualSavingsRate: annualSavingsRate,
      recentSavingsRate: last3SavingsRate,
      savingsRateDelta: last3SavingsRate - annualSavingsRate,
    );

    // ── 8. Health Score ─────────────────────────────────────────────────────
    int score = 0;

    // Savings rate component (0 - 30 pts)
    if (annualSavingsRate >= 0.30) {
      score += 30;
    } else if (annualSavingsRate >= 0.20) {
      score += 25;
    } else if (annualSavingsRate >= 0.10) {
      score += 15;
    } else if (annualSavingsRate >= 0.0) {
      score += 8;
    }

    // Runway component (0 - 30 pts)
    if (runwayMonths >= 6.0) {
      score += 30;
    } else if (runwayMonths >= 3.0) {
      score += 24;
    } else if (runwayMonths >= 1.5) {
      score += 15;
    } else if (runwayMonths >= 0.5) {
      score += 8;
    }

    // Debt leverage component (0 - 25 pts)
    final debtRatio = totalAssetsMinor > 0 ? totalDebtMinor / totalAssetsMinor : 0.0;
    if (debtRatio == 0.0) {
      score += 25;
    } else if (debtRatio < 0.20) {
      score += 22;
    } else if (debtRatio < 0.40) {
      score += 18;
    } else if (debtRatio < 0.60) {
      score += 12;
    } else {
      score += 5;
    }

    // Budget discipline component (0 - 15 pts)
    if (budgetCompliancePct >= 0.80) {
      score += 15;
    } else if (budgetCompliancePct >= 0.60) {
      score += 11;
    } else if (budgetCompliancePct >= 0.40) {
      score += 7;
    } else {
      score += 3;
    }

    String ratingLabel;
    String ratingDesc;
    if (score >= 85) {
      ratingLabel = 'EXCELLENT';
      ratingDesc = 'Exceptional financial resilience, low leverage, and strong surplus generation.';
    } else if (score >= 70) {
      ratingLabel = 'HEALTHY';
      ratingDesc = 'Strong liquidity buffer with controlled expenses and healthy capital growth.';
    } else if (score >= 50) {
      ratingLabel = 'MODERATE';
      ratingDesc = 'Stable base; opportunities exist to improve cash buffer and trim discretionary costs.';
    } else if (score >= 35) {
      ratingLabel = 'VULNERABLE';
      ratingDesc = 'Elevated sensitivity to income disruptions; debt reduction and reserve building needed.';
    } else {
      ratingLabel = 'CRITICAL';
      ratingDesc = 'Liquidity is severely constrained; immediate cash flow restructuring recommended.';
    }

    final healthScore = FinancialHealthScore(
      score: score,
      rating: ratingLabel,
      description: ratingDesc,
      debtToAssetRatio: debtRatio,
    );

    // ── 9. Insights & Diagnostic Synthesis ──────────────────────────────────
    final observations = <String>[];
    final recommendations = <String>[];

    // Liquidity observation
    final runwayStr = runwayMonths >= 12
        ? '12+ months'
        : '${runwayMonths.toStringAsFixed(1)} months';
    if (runwayMonths >= 6.0) {
      observations.add(
        'Liquidity Cushion: Available liquid cash covers $runwayStr of average living costs, surpassing the recommended 3-to-6 month emergency reserve benchmark.',
      );
    } else if (runwayMonths >= 3.0) {
      observations.add(
        'Liquidity Cushion: Current liquid reserves provide $runwayStr of runway, meeting the standard 3-month safety buffer.',
      );
    } else {
      observations.add(
        'Liquidity Warning: Cash runway of $runwayStr is below the 3-month threshold, leaving limited margin for sudden revenue drops or unplanned liabilities.',
      );
      recommendations.add(
        'Prioritize building liquid emergency reserves to at least 3 months of baseline expenses (recommended target: KES ${((avgMonthlyExpenses * 3) / 100).toStringAsFixed(0)}).',
      );
    }

    // Savings trajectory
    final savingsPctStr = '${(annualSavingsRate * 100).toStringAsFixed(1)}%';
    if (annualSavingsRate >= 0.20) {
      observations.add(
        'Savings Rate: 12-month average savings rate of $savingsPctStr meets the 20% wealth-building benchmark, generating a cumulative net surplus of KES ${(total12moNet / 100).toStringAsFixed(0)}.',
      );
    } else if (annualSavingsRate > 0) {
      observations.add(
        'Savings Rate: Annual net savings rate stands at $savingsPctStr. While positive, targeting 20%+ will accelerate long-term financial independence.',
      );
      recommendations.add(
        'Aim to increase monthly savings rate toward 20% by establishing automated payday transfers into high-yield accounts.',
      );
    } else {
      observations.add(
        'Deficit Warning: Outflows have exceeded inflows over the recorded period (net deficit of KES ${((-total12moNet) / 100).toStringAsFixed(0)}), causing capital contraction.',
      );
      recommendations.add(
        'Execute immediate expenditure controls to eliminate monthly operating deficits and protect capital reserves.',
      );
    }

    // Expense concentration
    if (expenseCategories.isNotEmpty) {
      final top3 = expenseCategories.take(3).toList();
      final top3Total = top3.fold<int>(0, (s, c) => s + c.totalMinor);
      final top3Share = total12moExpenses > 0 ? (top3Total / total12moExpenses) * 100 : 0.0;
      final topNames = top3.map((c) => c.accountName).join(', ');
      observations.add(
        'Expense Concentration: Top 3 expense categories ($topNames) account for ${top3Share.toStringAsFixed(1)}% of total outflows.',
      );
      if (top3Share > 65.0) {
        recommendations.add(
          'Review spending contracts and recurring obligations in "${top3.first.accountName}" to negotiate lower rates or eliminate leakage.',
        );
      }
    }

    // Debt service
    if (borrowedLoans.isNotEmpty) {
      final debtSharePct = (debtRatio * 100).toStringAsFixed(1);
      final highestRateLoan = borrowedLoans.reduce((a, b) =>
          a.loan.annualRateBp > b.loan.annualRateBp ? a : b);
      final highestRatePct = (highestRateLoan.loan.annualRateBp / 100).toStringAsFixed(1);

      observations.add(
        'Debt Profile: Outstanding borrowings stand at KES ${(totalDebtMinor / 100).toStringAsFixed(0)} ($debtSharePct% of total assets). Highest nominal interest cost is on ${highestRateLoan.loan.counterparty} at $highestRatePct% p.a.',
      );

      if (highestRateLoan.loan.annualRateBp >= 1200) {
        recommendations.add(
          'Target accelerated prepayments on high-interest debt (${highestRateLoan.loan.counterparty} at $highestRatePct% p.a.) using the avalanche method to minimize interest bleed.',
        );
      }
    } else {
      observations.add(
        'Debt-Free Balance Sheet: Zero active borrowed liabilities, maximizing operating cash flow conversion and financial flexibility.',
      );
    }

    // Budget performance
    if (budgetVsActual.isNotEmpty) {
      final adherencePctStr = '${(budgetCompliancePct * 100).toStringAsFixed(0)}%';
      observations.add(
        'Budget Execution: Maintained spending compliance in $periodsUnderCount of ${budgetVsActual.length} recorded budget cycles ($adherencePctStr discipline rate).',
      );
      if (budgetCompliancePct < 0.60) {
        recommendations.add(
          'Refine monthly budget envelope allocations to better reflect realistic variable expenditure patterns.',
        );
      }
    }

    // Portfolio yield
    if (activeHoldings.isNotEmpty) {
      final gainPctStr = '${investmentPortfolio.totalUnrealisedGainPct.toStringAsFixed(1)}%';
      observations.add(
        'Investment Growth: Active holdings have generated a total unrealised gain of $gainPctStr (KES ${(totalUnrealisedGainMinor / 100).toStringAsFixed(0)}) and distributed KES ${(totalInvestmentIncomeMinor / 100).toStringAsFixed(0)} in cash income.',
      );
    }

    // Physical assets & insurance
    if (physicalAssets.isNotEmpty) {
      if (insuredCount < physicalAssets.length) {
        final uninsuredCount = physicalAssets.length - insuredCount;
        observations.add(
          'Asset Risk: $uninsuredCount of ${physicalAssets.length} capital assets currently lack verified active insurance policies.',
        );
        recommendations.add(
          'Audit and update insurance policies for unverified capital assets to mitigate catastrophic loss exposure.',
        );
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Maintain current disciplined savings cadence and allocate regular monthly surplus toward diversified income-generating assets.',
      );
    }

    final executiveSummary =
        'Overall financial standing is $ratingLabel with a Financial Health Score of $score/100. '
        'Net worth stands at KES ${(netWorthMinor / 100).toStringAsFixed(0)} '
        '(KES ${(liquidNetWorthMinor / 100).toStringAsFixed(0)} liquid equity), '
        'supported by an annual savings rate of $savingsPctStr and emergency runway of $runwayStr.';

    final insights = FinancialInsights(
      executiveSummary: executiveSummary,
      observations: observations,
      recommendations: recommendations,
    );

    return FinancialReportData(
      asOf: asOf,
      currency: currency,
      monthlyPnL: monthlyPnL,
      expenseCategories: expenseCategories,
      topPayees: topPayees,
      budgetVsActual: budgetVsActual,
      loanRows: loanRows,
      holdings: holdings,
      assets: assets,
      accounts: accounts,
      accountBalances: accountBalances,
      balanceSheet: balanceSheet,
      incomeStatement: incomeStatement,
      budgetPerformance: budgetPerformance,
      debtSchedule: debtSchedule,
      investmentPortfolio: investmentPortfolio,
      assetRegister: assetRegister,
      healthScore: healthScore,
      trends: trends,
      insights: insights,
    );
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class AccountBalanceItem {
  final String id;
  final String name;
  final Liquidity liquidity;
  final int balanceMinor;
  const AccountBalanceItem({
    required this.id,
    required this.name,
    required this.liquidity,
    required this.balanceMinor,
  });
}

class MonthlyTrendItem {
  final MonthlyPnL pnl;
  final double momIncomePct;
  final double momExpensePct;
  final int momNetChangeMinor;
  const MonthlyTrendItem({
    required this.pnl,
    required this.momIncomePct,
    required this.momExpensePct,
    required this.momNetChangeMinor,
  });
}

class TrendMetric {
  final String title;
  final int currentValue;
  final int previousValue;
  final double changePct;
  final bool isFavorable;
  const TrendMetric({
    required this.title,
    required this.currentValue,
    required this.previousValue,
    required this.changePct,
    required this.isFavorable,
  });
}

class FinancialTrends {
  final int avgMonthlyIncome;
  final int avgMonthlyExpenses;
  final double runwayMonths;
  final TrendMetric incomeMoM;
  final TrendMetric expenseMoM;
  final TrendMetric netMoM;
  final double annualSavingsRate;
  final double recentSavingsRate;
  final double savingsRateDelta;

  const FinancialTrends({
    required this.avgMonthlyIncome,
    required this.avgMonthlyExpenses,
    required this.runwayMonths,
    required this.incomeMoM,
    required this.expenseMoM,
    required this.netMoM,
    required this.annualSavingsRate,
    required this.recentSavingsRate,
    required this.savingsRateDelta,
  });
}

class FinancialHealthScore {
  final int score;
  final String rating;
  final String description;
  final double debtToAssetRatio;

  const FinancialHealthScore({
    required this.score,
    required this.rating,
    required this.description,
    required this.debtToAssetRatio,
  });
}

class FinancialInsights {
  final String executiveSummary;
  final List<String> observations;
  final List<String> recommendations;

  const FinancialInsights({
    required this.executiveSummary,
    required this.observations,
    required this.recommendations,
  });
}

class BalanceSheetStatement {
  final List<AccountBalanceItem> cashAccounts;
  final int totalCashMinor;
  final int liquidCashMinor;
  final List<Holding> holdings;
  final int totalInvestmentsCostMinor;
  final int totalInvestmentsMarketMinor;
  final List<Asset> physicalAssets;
  final int totalPhysicalCostMinor;
  final int totalPhysicalBookMinor;
  final int totalAssetsMinor;
  final List<LoanReportRow> borrowedLoans;
  final int totalLiabilitiesMinor;
  final int netWorthMinor;
  final int liquidNetWorthMinor;
  final int illiquidNetWorthMinor;

  const BalanceSheetStatement({
    required this.cashAccounts,
    required this.totalCashMinor,
    required this.liquidCashMinor,
    required this.holdings,
    required this.totalInvestmentsCostMinor,
    required this.totalInvestmentsMarketMinor,
    required this.physicalAssets,
    required this.totalPhysicalCostMinor,
    required this.totalPhysicalBookMinor,
    required this.totalAssetsMinor,
    required this.borrowedLoans,
    required this.totalLiabilitiesMinor,
    required this.netWorthMinor,
    required this.liquidNetWorthMinor,
    required this.illiquidNetWorthMinor,
  });
}

class IncomeStatementStatement {
  final List<MonthlyTrendItem> monthlyTrends;
  final int totalIncomeMinor;
  final int totalExpensesMinor;
  final int totalNetMinor;
  final double savingsRate;
  final List<ExpenseCategory> topCategories;
  final List<PayeeRow> topPayees;

  const IncomeStatementStatement({
    required this.monthlyTrends,
    required this.totalIncomeMinor,
    required this.totalExpensesMinor,
    required this.totalNetMinor,
    required this.savingsRate,
    required this.topCategories,
    required this.topPayees,
  });
}

class BudgetPerformanceStatement {
  final List<BudgetVsActual> periods;
  final int totalPlannedMinor;
  final int totalActualMinor;
  final int totalVarianceMinor;
  final int periodsUnderCount;
  final int totalPeriods;
  final double compliancePct;

  const BudgetPerformanceStatement({
    required this.periods,
    required this.totalPlannedMinor,
    required this.totalActualMinor,
    required this.totalVarianceMinor,
    required this.periodsUnderCount,
    required this.totalPeriods,
    required this.compliancePct,
  });
}

class DebtScheduleStatement {
  final List<LoanReportRow> borrowedLoans;
  final List<LoanReportRow> lentLoans;
  final int totalOutstandingMinor;
  final int totalInterestPaidMinor;
  final int totalProjectedInterestMinor;
  final int totalCostOfBorrowingMinor;
  final int totalLentMinor;

  const DebtScheduleStatement({
    required this.borrowedLoans,
    required this.lentLoans,
    required this.totalOutstandingMinor,
    required this.totalInterestPaidMinor,
    required this.totalProjectedInterestMinor,
    required this.totalCostOfBorrowingMinor,
    required this.totalLentMinor,
  });
}

class InvestmentPortfolioStatement {
  final List<Holding> holdings;
  final int totalCostBasisMinor;
  final int totalMarketValueMinor;
  final int totalUnrealisedGainMinor;
  final int totalRealisedGainMinor;
  final int totalIncomeMinor;
  final int totalReturnMinor;

  const InvestmentPortfolioStatement({
    required this.holdings,
    required this.totalCostBasisMinor,
    required this.totalMarketValueMinor,
    required this.totalUnrealisedGainMinor,
    required this.totalRealisedGainMinor,
    required this.totalIncomeMinor,
    required this.totalReturnMinor,
  });

  double get totalUnrealisedGainPct => totalCostBasisMinor > 0
      ? (totalUnrealisedGainMinor / totalCostBasisMinor) * 100
      : 0.0;
}

class FixedAssetRegisterStatement {
  final List<Asset> assets;
  final int totalCostMinor;
  final int totalBookValueMinor;
  final int totalRevaluationMinor;
  final int insuredCount;

  const FixedAssetRegisterStatement({
    required this.assets,
    required this.totalCostMinor,
    required this.totalBookValueMinor,
    required this.totalRevaluationMinor,
    required this.insuredCount,
  });
}
