part of 'projects_cubit.dart';

enum ProjectFilter { all, active, capital, revenue, completed }

@freezed
abstract class ProjectsState with _$ProjectsState {
  const factory ProjectsState.initial() = _Initial;
  const factory ProjectsState.loading() = _Loading;
  const factory ProjectsState.loaded({
    required List<Project> projects,
    required Map<String, ProjectSummary> summaries,
    required ProjectFilter filter,
    String? selectedProjectId,
    required List<JournalEntry> selectedEntries,
    required List<Account> accounts,
    // Aggregate stats
    required int totalBudgetedMinor,
    required int totalSpentMinor,
    required int totalRevenueMinor,
    required int activeCount,
    String? validationError,
  }) = _Loaded;
  const factory ProjectsState.error(String message) = _Error;
}
