part of 'budget_cubit.dart';

class BudgetLineSparkline {
  final String lineId;
  final List<int> monthlyActuals; // 6 months oldest→newest
  final List<String> periods;
  const BudgetLineSparkline({
    required this.lineId,
    required this.monthlyActuals,
    required this.periods,
  });
}

@freezed
abstract class BudgetState with _$BudgetState {
  const factory BudgetState.initial() = _Initial;
  const factory BudgetState.loading() = _Loading;
  const factory BudgetState.loaded({
    required List<String> periods,
    required String selectedPeriod,
    required BudgetPlan? plan,
    required Map<String, int> actuals,
    required Map<String, int> prevActuals,
    required List<Account> expenseAccounts,
    required int totalIncomeMinor,
    required List<BudgetPlan> templates,
    String? selectedLineId,
    required List<BudgetLineSparkline> sparklines,
    required String activeStrategyId,
    required String activeStrategyName,
  }) = _Loaded;
  const factory BudgetState.error(String message) = _Error;
}
