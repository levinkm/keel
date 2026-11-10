part of 'investments_cubit.dart';

@freezed
abstract class InvestmentsState with _$InvestmentsState {
  const factory InvestmentsState.initial() = _Initial;
  const factory InvestmentsState.loading() = _Loading;
  const factory InvestmentsState.loaded({
    required List<Holding> holdings,
    String? selectedHoldingId,
    required int totalInvestedMinor,
    required int totalMarketValueMinor,
    required int totalGainMinor,
    required int totalRealisedGainMinor,
    required int totalIncomeMinor,
    String? validationError,
  }) = _Loaded;
  const factory InvestmentsState.error(String message) = _Error;
}
