part of 'ledger_cubit.dart';

@freezed
abstract class LedgerState with _$LedgerState {
  const factory LedgerState.initial() = _Initial;
  const factory LedgerState.loading() = _Loading;
  const factory LedgerState.loaded(
    List<JournalEntry> entries,
    String period, {
    JournalEntry? selectedEntry,
    String? validationError,
  }) = _Loaded;
  const factory LedgerState.error(String message) = _Error;
}
