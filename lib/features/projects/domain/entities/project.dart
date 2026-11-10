enum ProjectType { capital, revenue }
enum ProjectStatus { planning, active, onHold, completed, cancelled }

extension ProjectTypeLabel on ProjectType {
  String get label => switch (this) {
        ProjectType.capital => 'Capital',
        ProjectType.revenue => 'Revenue',
      };
  String get description => switch (this) {
        ProjectType.capital =>
          'Creates or improves an asset (car restoration, construction)',
        ProjectType.revenue =>
          'Generates income with operating costs (farming, trading)',
      };
}

extension ProjectStatusLabel on ProjectStatus {
  String get label => switch (this) {
        ProjectStatus.planning => 'Planning',
        ProjectStatus.active => 'Active',
        ProjectStatus.onHold => 'On Hold',
        ProjectStatus.completed => 'Completed',
        ProjectStatus.cancelled => 'Cancelled',
      };
}

class Project {
  final String id;
  final String name;
  final String? description;
  final ProjectType type;
  final ProjectStatus status;
  final int budgetMinor;         // total expected cost
  final int? revenueTargetMinor; // revenue projects only
  final String currency;
  final String? fundingAccountId; // primary account funding this project
  final String? assetAccountId;   // capital projects: asset account to capitalise into
  final String? assetId;          // linked physical asset from assets table
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> tags;
  final DateTime createdAt;

  const Project({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.status,
    required this.budgetMinor,
    this.revenueTargetMinor,
    required this.currency,
    this.fundingAccountId,
    this.assetAccountId,
    this.assetId,
    required this.startDate,
    this.endDate,
    this.tags = const [],
    required this.createdAt,
  });

  bool get isActive => status == ProjectStatus.active;
  bool get isCapital => type == ProjectType.capital;
  bool get isRevenue => type == ProjectType.revenue;

  Duration? get duration =>
      endDate != null ? endDate!.difference(startDate) : null;

  int get daysElapsed =>
      DateTime.now().difference(startDate).inDays.clamp(0, 999999);

  int? get daysRemaining =>
      endDate != null ? endDate!.difference(DateTime.now()).inDays : null;

  double? get timeProgressPct {
    if (endDate == null) return null;
    final total = endDate!.difference(startDate).inDays;
    if (total <= 0) return 1.0;
    return (daysElapsed / total).clamp(0.0, 1.0);
  }
}

/// Computed summary for a project — derived from journal entries
class ProjectSummary {
  final String projectId;
  final int totalSpentMinor;
  final int totalIncomeMinor; // revenue projects
  final int entryCount;
  final DateTime? lastActivityDate;

  const ProjectSummary({
    required this.projectId,
    required this.totalSpentMinor,
    required this.totalIncomeMinor,
    required this.entryCount,
    this.lastActivityDate,
  });

  int get netMinor => totalIncomeMinor - totalSpentMinor;
  int get remainingBudgetMinor => 0; // computed externally with project.budgetMinor

  double budgetUsedPct(int budgetMinor) {
    if (budgetMinor <= 0) return 0;
    return (totalSpentMinor / budgetMinor).clamp(0.0, 1.0);
  }

  bool isOverBudget(int budgetMinor) => totalSpentMinor > budgetMinor;
}
