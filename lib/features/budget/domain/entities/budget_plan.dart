class BudgetLine {
  final String id;
  final String planId;
  final String accountId;
  final String bucket;
  final int plannedMinor;
  final String currency;
  final int rolloverMinor;
  final String? notes;

  const BudgetLine({
    required this.id,
    required this.planId,
    required this.accountId,
    required this.bucket,
    required this.plannedMinor,
    required this.currency,
    required this.rolloverMinor,
    this.notes,
  });

  int get effectivePlanned => plannedMinor + rolloverMinor;
}

class BudgetPlan {
  final String id;
  final String period;
  final String strategyId;
  final int strategyVersion;
  final int baseAmountMinor;
  final String currency;
  final List<BudgetLine> lines;
  final bool isTemplate;
  final String? templateName;
  final DateTime createdAt;

  const BudgetPlan({
    required this.id,
    required this.period,
    required this.strategyId,
    required this.strategyVersion,
    required this.baseAmountMinor,
    required this.currency,
    required this.lines,
    this.isTemplate = false,
    this.templateName,
    required this.createdAt,
  });
}
