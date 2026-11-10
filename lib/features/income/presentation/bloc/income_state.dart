part of 'income_cubit.dart';

class IncomeStats {
  final int expectedMinor;
  final int receivedMinor;
  final int pendingMinor;
  final int ytdMinor;

  const IncomeStats({
    required this.expectedMinor,
    required this.receivedMinor,
    required this.pendingMinor,
    required this.ytdMinor,
  });
}

class StreamActivity {
  final String period;
  final int receivedMinor;
  const StreamActivity({required this.period, required this.receivedMinor});
}

@freezed
abstract class IncomeState with _$IncomeState {
  const factory IncomeState.initial() = _Initial;
  const factory IncomeState.loading() = _Loading;
  const factory IncomeState.loaded({
    required List<IncomeStream> streams,
    required String selectedPeriod,
    required IncomeStats stats,
    required Map<String, int> receivedByStream,
    required List<Account> incomeAccounts,
    String? selectedStreamId,
    required List<StreamActivity> sparkline,
    required List<JournalEntry> paymentHistory,
    String? validationError,
  }) = _Loaded;
  const factory IncomeState.error(String message) = _Error;
}
