part of 'accounts_cubit.dart';

enum AccountFilter { all, asset, liability, income, expense }

class MonthlyBalance {
  final String period;
  final int balanceMinor;
  const MonthlyBalance({required this.period, required this.balanceMinor});
}

@freezed
abstract class AccountsState with _$AccountsState {
  const factory AccountsState.initial() = _Initial;
  const factory AccountsState.loading() = _Loading;
  const factory AccountsState.loaded({
    required List<Account> accounts,
    required Map<String, int> balances,
    required AccountFilter filter,
    String? selectedAccountId,
    required List<JournalEntry> selectedHistory,
    required List<MonthlyBalance> selectedSparkline,
  }) = _Loaded;
  const factory AccountsState.error(String message) = _Error;
}
