part of 'assets_cubit.dart';

enum AssetFilter { all, cashAndBank, investments, vehicle, machinery, land, building, receivable, other }

@freezed
abstract class AssetsState with _$AssetsState {
  const factory AssetsState.initial() = _Initial;
  const factory AssetsState.loading() = _Loading;
  const factory AssetsState.loaded({
    required List<Asset> assets,
    required AssetFilter filter,
    String? selectedAssetId,
    required int totalCostMinor,
    required int totalBookValueMinor,
    required int insuredCount,
    required List<Project> linkedProjects,
    required Map<String, ProjectSummary> linkedSummaries,
    required Map<String, List<JournalEntry>> linkedEntries,
    required List<AssetAttachment> attachments,
    String? validationError,
  }) = _Loaded;
  const factory AssetsState.error(String message) = _Error;
}
