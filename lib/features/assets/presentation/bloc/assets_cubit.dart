import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:keel/features/assets/domain/entities/asset.dart';
import 'package:keel/features/assets/domain/repositories/assets_repository.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:keel/features/projects/domain/entities/project.dart';
import 'package:keel/features/projects/domain/repositories/project_repository.dart';
import 'package:uuid/uuid.dart';

part 'assets_state.dart';
part 'assets_cubit.freezed.dart';

class AssetsCubit extends Cubit<AssetsState> {
  final AssetsRepository _repo;
  final ProjectRepository _projectRepo;
  final LedgerRepository _ledgerRepo;

  AssetsCubit(this._repo, this._projectRepo, this._ledgerRepo)
      : super(const AssetsState.initial());

  Future<void> load() async {
    emit(const AssetsState.loading());
    await _reload();
  }

  Future<void> setFilter(AssetFilter filter) async {
    final current = state;
    if (current is! _Loaded) return;
    emit(current.copyWith(filter: filter, selectedAssetId: null,
        linkedProjects: [], linkedSummaries: {}, linkedEntries: {},
        attachments: []));
  }

  Future<void> selectAsset(String? id) async {
    final current = state;
    if (current is! _Loaded) return;
    if (id == null) {
      emit(current.copyWith(selectedAssetId: null,
          linkedProjects: [], linkedSummaries: {}, linkedEntries: {},
          attachments: []));
      return;
    }
    final (projects, summaries, entries) = await _loadLinkedProjects(id);
    final attachments = await _loadAttachments(id);
    emit(current.copyWith(
      selectedAssetId: id,
      linkedProjects: projects,
      linkedSummaries: summaries,
      linkedEntries: entries,
      attachments: attachments,
    ));
  }

  Future<void> createAsset(Asset asset) async {
    final withId = asset.copyWith(id: const Uuid().v4());
    final result = await _repo.createAsset(withId);
    result.fold(
      (f) => _emitError(f.message),
      (_) async => await _reload(selectedId: withId.id),
    );
  }

  Future<void> updateAsset(Asset asset) async {
    final result = await _repo.updateAsset(asset);
    result.fold(
      (f) => _emitError(f.message),
      (_) async => await _reload(selectedId: asset.id),
    );
  }

  Future<void> refreshLinkedProjects() async {
    final current = state;
    if (current is! _Loaded || current.selectedAssetId == null) return;
    final (projects, summaries, entries) =
        await _loadLinkedProjects(current.selectedAssetId!);
    emit(current.copyWith(
      linkedProjects: projects,
      linkedSummaries: summaries,
      linkedEntries: entries,
    ));
  }

  Future<void> addAttachment(String assetId, String filePath, String fileName, String? mime) async {
    final attachment = AssetAttachment(
      id: const Uuid().v4(),
      assetId: assetId,
      filePath: filePath,
      fileName: fileName,
      mimeType: mime,
      createdAt: DateTime.now(),
    );
    await _repo.addAttachment(attachment);
    final current = state;
    if (current is! _Loaded) return;
    final attachments = await _loadAttachments(assetId);
    emit(current.copyWith(attachments: attachments));
  }

  Future<void> removeAttachment(String attachmentId) async {
    await _repo.removeAttachment(attachmentId);
    final current = state;
    if (current is! _Loaded || current.selectedAssetId == null) return;
    final attachments = await _loadAttachments(current.selectedAssetId!);
    emit(current.copyWith(attachments: attachments));
  }

  void clearValidationError() {
    final current = state;
    if (current is! _Loaded) return;
    emit(current.copyWith(validationError: null));
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _emitError(String message) {
    final current = state;
    if (current is _Loaded) {
      emit(current.copyWith(validationError: message));
    } else {
      emit(AssetsState.error(message));
    }
  }

  Future<List<AssetAttachment>> _loadAttachments(String assetId) async {
    final result = await _repo.getAttachments(assetId);
    return result.fold((_) => [], (a) => a);
  }

  Future<(List<Project>, Map<String, ProjectSummary>, Map<String, List<JournalEntry>>)>
      _loadLinkedProjects(String assetId) async {
    final result = await _projectRepo.getProjectsForAsset(assetId);
    final projects = result.fold((_) => <Project>[], (p) => p);

    final summaries = <String, ProjectSummary>{};
    final entriesMap = <String, List<JournalEntry>>{};

    // Get entries for each project
    for (final project in projects) {
      final entryIdsResult = await _projectRepo.getEntryIdsForProject(project.id);
      final entryIds = entryIdsResult.fold((_) => <String>[], (ids) => ids);

      final entries = <JournalEntry>[];
      for (final id in entryIds) {
        final r = await _ledgerRepo.getEntryById(id);
        r.fold((_) => null, (e) { if (e != null) entries.add(e); });
      }
      entries.sort((a, b) => b.date.compareTo(a.date));
      entriesMap[project.id] = entries;

      // Compute summary: debits = spend, credits = income
      int spent = 0;
      int income = 0;
      DateTime? lastActivity;
      for (final entry in entries) {
        if (lastActivity == null || entry.date.isAfter(lastActivity)) {
          lastActivity = entry.date;
        }
        for (final line in entry.lines) {
          if (line.side == JournalSide.debit) spent += line.amountMinor;
          if (line.side == JournalSide.credit) income += line.amountMinor;
        }
      }
      // Net out double-entry: actual spend = debit - credit on expense lines
      // Simple heuristic: half of total debits (since every debit has a credit)
      spent = spent ~/ 2;
      income = income ~/ 2;

      summaries[project.id] = ProjectSummary(
        projectId: project.id,
        totalSpentMinor: spent,
        totalIncomeMinor: income,
        entryCount: entries.length,
        lastActivityDate: lastActivity,
      );
    }

    return (projects, summaries, entriesMap);
  }

  Future<void> _reload({String? selectedId}) async {
    final result = await _repo.getAssets();
    final assets = result.fold((_) => <Asset>[], (a) => a);

    int totalCost = 0;
    int totalBook = 0;
    int insured = 0;
    final now = DateTime.now();

    for (final a in assets) {
      totalCost += a.costMinor;
      totalBook += a.bookValue;
      if (a.insuranceExpiry != null && a.insuranceExpiry!.isAfter(now)) insured++;
    }

    final current = state;
    final filter = current is _Loaded ? current.filter : AssetFilter.all;
    final resolvedId = selectedId ?? (current is _Loaded ? current.selectedAssetId : null) ??
        (assets.isNotEmpty ? assets.first.id : null);

    List<Project> linkedProjects = [];
    Map<String, ProjectSummary> linkedSummaries = {};
    Map<String, List<JournalEntry>> linkedEntries = {};
    List<AssetAttachment> attachments = [];

    if (resolvedId != null) {
      final (p, s, e) = await _loadLinkedProjects(resolvedId);
      linkedProjects = p;
      linkedSummaries = s;
      linkedEntries = e;
      attachments = await _loadAttachments(resolvedId);
    }

    emit(AssetsState.loaded(
      assets: assets,
      filter: filter,
      selectedAssetId: resolvedId,
      totalCostMinor: totalCost,
      totalBookValueMinor: totalBook,
      insuredCount: insured,
      linkedProjects: linkedProjects,
      linkedSummaries: linkedSummaries,
      linkedEntries: linkedEntries,
      attachments: attachments,
    ));
  }
}
