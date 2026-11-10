part of 'net_worth_cubit.dart';

@freezed
abstract class NetWorthState with _$NetWorthState {
  const factory NetWorthState.initial() = _Initial;
  const factory NetWorthState.loading() = _Loading;
  const factory NetWorthState.loaded({
    required int netWorthMinor,
    required int totalAssetsMinor,
    required int totalLiabilitiesMinor,
    required int liquidMinor,
    required int totalCashMinor,
    required int totalPhysicalMinor,
    required int totalInvestmentsMinor,
    required List<AccountBalance> cashAccounts,
    required List<Asset> physicalAssets,
    required List<Holding> activeHoldings,
    required List<LoanBalance> loanBalances,
  }) = _Loaded;
  const factory NetWorthState.error(String message) = _Error;
}
