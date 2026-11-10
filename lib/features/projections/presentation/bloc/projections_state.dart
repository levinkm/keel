part of 'projections_cubit.dart';

@freezed
abstract class ProjectionsState with _$ProjectionsState {
  const factory ProjectionsState.initial() = _Initial;
  const factory ProjectionsState.loading() = _Loading;
  const factory ProjectionsState.loaded({
    required int currentNetWorthMinor,
    required int monthlyIncomeMinor,
    required int monthlyExpensesMinor,
    required int incomeStreamCount,      // how many streams contributed
    required bool expensesFromBudget,    // true = budget plan, false = 3mo avg
    required List<LoanProjection> loanSchedules,
    required List<ProjectionPoint> projectionPoints,
    required int projectionMonths,
    required double incomeGrowthPct,
    required double expenseGrowthPct,
    required int savingsTargetMinor,
  }) = _Loaded;
  const factory ProjectionsState.error(String message) = _Error;
}
