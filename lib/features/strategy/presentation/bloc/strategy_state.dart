part of 'strategy_cubit.dart';

@freezed
abstract class StrategyState with _$StrategyState {
  const factory StrategyState.initial() = _Initial;
  const factory StrategyState.loading() = _Loading;
  const factory StrategyState.loaded({
    required Strategy activeStrategy,
    required List<StrategyBucket> buckets, // user-customised buckets for active strategy
    required List<Strategy> allStrategies,
    required List<Account> expenseAccounts,
    required List<Account> assetAccounts,
    required int monthlyIncomeMinor,       // from ledger this period
    String? validationError,
  }) = _Loaded;
  const factory StrategyState.error(String message) = _Error;
}
