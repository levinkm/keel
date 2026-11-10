part of 'reports_cubit.dart';

@freezed
abstract class ReportsState with _$ReportsState {
  const factory ReportsState.initial() = _Initial;
  const factory ReportsState.loading() = _Loading;
  const factory ReportsState.loaded({
    required List<MonthlyPnL> monthlyPnL,
    required List<ExpenseCategory> expenseCategories,
    required List<PayeeRow> topPayees,
    required List<BudgetVsActual> budgetVsActual,
    required List<LoanReportRow> loanRows,
    required List<Holding> holdings,
    required List<Asset> assets,
    required List<Account> accounts,
    required List<JournalEntry> allEntries,
    required Map<String, int> accountBalances,
  }) = _Loaded;
  const factory ReportsState.error(String message) = _Error;
}
