part of 'dashboard_cubit.dart';

class DashboardData {
  final int netWorthMinor;
  final int prevNetWorthMinor;
  final int incomeMinor;
  final int expensesMinor;
  final int budgetedExpensesMinor;
  final int budgetedIncomeMinor;
  final int physicalAssetsMinor;
  final int liquidMinor;          // instant-liquidity asset accounts
  final int totalDebtMinor;       // total outstanding borrowed loans
  final int totalLentMinor;       // total outstanding lent loans
  final int totalInterestMinor;   // monthly interest cost across all loans
  final List<Account> accounts;
  final Map<String, int> balances;
  final List<BudgetLine> budgetLines;
  final Map<String, int> actualByAccount;
  final List<JournalEntry> recentEntries;
  final List<MonthlyCashFlow> cashFlow;
  final List<MonthlyNetWorth> netWorthHistory; // 6-month net worth trend
  final String activeStrategyName;
  final int strategyTargetSavingsPct;

  const DashboardData({
    required this.netWorthMinor,
    required this.prevNetWorthMinor,
    required this.incomeMinor,
    required this.expensesMinor,
    required this.budgetedExpensesMinor,
    required this.budgetedIncomeMinor,
    required this.physicalAssetsMinor,
    required this.liquidMinor,
    required this.totalDebtMinor,
    required this.totalLentMinor,
    required this.totalInterestMinor,
    required this.accounts,
    required this.balances,
    required this.budgetLines,
    required this.actualByAccount,
    required this.recentEntries,
    required this.cashFlow,
    required this.netWorthHistory,
    required this.activeStrategyName,
    required this.strategyTargetSavingsPct,
  });

  double get savingsRate {
    if (incomeMinor == 0) return 0;
    final saved = incomeMinor - expensesMinor;
    return (saved / incomeMinor).clamp(0.0, 1.0);
  }

  bool get savingsOnTrack =>
      strategyTargetSavingsPct == 0 ||
      (savingsRate * 100) >= strategyTargetSavingsPct;

  /// Monthly interest as % of income
  double get interestBurdenPct =>
      incomeMinor > 0 ? (totalInterestMinor / incomeMinor).clamp(0.0, 1.0) : 0.0;
}

class MonthlyCashFlow {
  final String period;
  final int incomeMinor;
  final int expensesMinor;
  const MonthlyCashFlow({required this.period, required this.incomeMinor, required this.expensesMinor});
}

class MonthlyNetWorth {
  final String period;
  final int netWorthMinor;
  const MonthlyNetWorth({required this.period, required this.netWorthMinor});
}

@freezed
abstract class DashboardState with _$DashboardState {
  const factory DashboardState.initial() = _Initial;
  const factory DashboardState.loading() = _Loading;
  const factory DashboardState.loaded(DashboardData data) = _Loaded;
  const factory DashboardState.error(String message) = _Error;
}
