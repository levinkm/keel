import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:keel/features/projects/domain/entities/project.dart';
import 'package:keel/features/projects/domain/repositories/project_repository.dart';

part 'projects_state.dart';
part 'projects_cubit.freezed.dart';

class ProjectsCubit extends Cubit<ProjectsState> {
  final ProjectRepository _repo;
  final LedgerRepository _ledgerRepo;
  final AccountsRepository _accountsRepo;

  ProjectsCubit(this._repo, this._ledgerRepo, this._accountsRepo)
      : super(const ProjectsState.initial());

  Future<void> load() async {
    emit(const ProjectsState.loading());
    await _reload();
  }

  Future<void> setFilter(ProjectFilter filter) async {
    final current = state;
    if (current is! _Loaded) return;
    emit(current.copyWith(filter: filter, selectedProjectId: null, selectedEntries: []));
  }

  Future<void> selectProject(String? projectId) async {
    final current = state;
    if (current is! _Loaded) return;
    if (projectId == null) {
      emit(current.copyWith(selectedProjectId: null, selectedEntries: []));
      return;
    }
    final entries = await _loadEntriesForProject(projectId);
    emit(current.copyWith(selectedProjectId: projectId, selectedEntries: entries));
  }

  Future<void> createProject(Project project) async {
    final result = await _repo.createProject(project);
    result.fold(
      (f) => _emitError(f.message),
      (_) async => await _reload(selectedProjectId: project.id),
    );
  }

  Future<void> updateProject(Project project) async {
    final result = await _repo.updateProject(project);
    result.fold(
      (f) => _emitError(f.message),
      (_) async => await _reload(selectedProjectId: project.id),
    );
  }

  Future<void> deleteProject(String projectId) async {
    final result = await _repo.deleteProject(projectId);
    result.fold(
      (f) => _emitError(f.message),
      (_) async => await _reload(),
    );
  }

  Future<void> setStatus(Project project, ProjectStatus status) async {
    await updateProject(Project(
      id: project.id,
      name: project.name,
      description: project.description,
      type: project.type,
      status: status,
      budgetMinor: project.budgetMinor,
      revenueTargetMinor: project.revenueTargetMinor,
      currency: project.currency,
      fundingAccountId: project.fundingAccountId,
      assetAccountId: project.assetAccountId,
      startDate: project.startDate,
      endDate: status == ProjectStatus.completed
          ? (project.endDate ?? DateTime.now())
          : project.endDate,
      tags: project.tags,
      createdAt: project.createdAt,
    ));
  }

  Future<void> tagEntry(String projectId, String journalEntryId) async {
    final current = state;
    if (current is! _Loaded) return;
    await _repo.tagEntry(projectId, journalEntryId);
    if (current.selectedProjectId == projectId) {
      final entries = await _loadEntriesForProject(projectId);
      final summaries = Map<String, ProjectSummary>.from(current.summaries);
      summaries[projectId] = await _computeSummary(projectId, entries);
      emit(current.copyWith(selectedEntries: entries, summaries: summaries));
    }
    await _reload(selectedProjectId: current.selectedProjectId);
  }

  Future<void> untagEntry(String projectId, String journalEntryId) async {
    final current = state;
    if (current is! _Loaded) return;
    await _repo.untagEntry(projectId, journalEntryId);
    if (current.selectedProjectId == projectId) {
      final entries = await _loadEntriesForProject(projectId);
      final summaries = Map<String, ProjectSummary>.from(current.summaries);
      summaries[projectId] = await _computeSummary(projectId, entries);
      emit(current.copyWith(selectedEntries: entries, summaries: summaries));
    }
    await _reload(selectedProjectId: current.selectedProjectId);
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
      emit(ProjectsState.error(message));
    }
  }

  Future<List<JournalEntry>> _loadEntriesForProject(String projectId) async {
    final entryIdsResult = await _repo.getEntryIdsForProject(projectId);
    final entryIds = entryIdsResult.fold((_) => <String>[], (ids) => ids);
    if (entryIds.isEmpty) return [];

    final entries = <JournalEntry>[];
    for (final id in entryIds) {
      final result = await _ledgerRepo.getEntryById(id);
      result.fold((_) => null, (entry) {
        if (entry != null) entries.add(entry);
      });
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Future<ProjectSummary> _computeSummary(
      String projectId, List<JournalEntry> entries) async {
    int spent = 0;
    int income = 0;
    DateTime? lastActivity;

    // Get all accounts to classify debit lines
    final accountsResult = await _accountsRepo.getAccounts();
    final accounts = accountsResult.fold((_) => <Account>[], (a) => a);
    final expenseIds =
        accounts.where((a) => a.type == AccountType.expense).map((a) => a.id).toSet();
    final incomeIds =
        accounts.where((a) => a.type == AccountType.income).map((a) => a.id).toSet();

    for (final entry in entries) {
      if (lastActivity == null || entry.date.isAfter(lastActivity)) {
        lastActivity = entry.date;
      }
      for (final line in entry.lines) {
        if (line.side == JournalSide.debit && expenseIds.contains(line.accountId)) {
          spent += line.amountMinor;
        }
        if (line.side == JournalSide.credit && incomeIds.contains(line.accountId)) {
          income += line.amountMinor;
        }
      }
    }

    return ProjectSummary(
      projectId: projectId,
      totalSpentMinor: spent,
      totalIncomeMinor: income,
      entryCount: entries.length,
      lastActivityDate: lastActivity,
    );
  }

  Future<void> _reload({String? selectedProjectId}) async {
    final projectsResult = await _repo.getProjects();
    final projects = projectsResult.fold((_) => <Project>[], (p) => p);

    final accountsResult = await _accountsRepo.getAccounts();
    final accounts = accountsResult.fold((_) => <Account>[], (a) => a);

    // Build summaries for all projects
    final summaries = <String, ProjectSummary>{};
    for (final project in projects) {
      final entries = await _loadEntriesForProject(project.id);
      summaries[project.id] = await _computeSummary(project.id, entries);
    }

    // Aggregate stats
    int totalBudgeted = 0;
    int totalSpent = 0;
    int totalRevenue = 0;
    int activeCount = 0;

    for (final project in projects) {
      final summary = summaries[project.id]!;
      totalBudgeted += project.budgetMinor;
      totalSpent += summary.totalSpentMinor;
      totalRevenue += summary.totalIncomeMinor;
      if (project.status == ProjectStatus.active) activeCount++;
    }

    final current = state;
    final filter = current is _Loaded ? current.filter : ProjectFilter.all;
    final resolvedId = selectedProjectId ??
        (current is _Loaded ? current.selectedProjectId : null) ??
        (projects.isNotEmpty ? projects.first.id : null);

    final selectedEntries = resolvedId != null
        ? await _loadEntriesForProject(resolvedId)
        : <JournalEntry>[];

    emit(ProjectsState.loaded(
      projects: projects,
      summaries: summaries,
      filter: filter,
      selectedProjectId: resolvedId,
      selectedEntries: selectedEntries,
      accounts: accounts,
      totalBudgetedMinor: totalBudgeted,
      totalSpentMinor: totalSpent,
      totalRevenueMinor: totalRevenue,
      activeCount: activeCount,
    ));
  }
}
