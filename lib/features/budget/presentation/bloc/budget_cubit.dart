import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:keel/features/budget/domain/entities/budget_plan.dart';
import 'package:keel/features/budget/domain/repositories/budget_repository.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:keel/features/strategy/domain/entities/strategy.dart';
import 'package:keel/features/strategy/domain/repositories/strategy_repository.dart';
import 'package:uuid/uuid.dart';

part 'budget_state.dart';
part 'budget_cubit.freezed.dart';

class BudgetCubit extends Cubit<BudgetState> {
  final BudgetRepository _budgetRepo;
  final LedgerRepository _ledgerRepo;
  final AccountsRepository _accountsRepo;
  final StrategyRepository _strategyRepo;

  BudgetCubit(this._budgetRepo, this._ledgerRepo, this._accountsRepo, this._strategyRepo)
      : super(const BudgetState.initial());

  static String _todayPeriod() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  static String _offsetPeriod(String period, int offset) {
    final parts = period.split('-');
    var year = int.parse(parts[0]);
    var month = int.parse(parts[1]) + offset;
    while (month < 1) { month += 12; year--; }
    while (month > 12) { month -= 12; year++; }
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  Future<void> load() async {
    emit(const BudgetState.loading());
    await _loadPeriod(_todayPeriod());
  }

  Future<void> selectPeriod(String period) async {
    final current = state;
    if (current is! _Loaded) return;
    await _loadPeriod(period,
        existingPeriods: current.periods,
        existingAccounts: current.expenseAccounts);
  }

  Future<void> selectLine(String? lineId) async {
    final current = state;
    if (current is! _Loaded) return;
    emit(current.copyWith(selectedLineId: lineId));
  }

  Future<void> createBlankPlan(String period) async {
    final current = state;
    if (current is! _Loaded) return;
    await _budgetRepo.savePlan(BudgetPlan(
      id: const Uuid().v4(),
      period: period,
      strategyId: '',
      strategyVersion: 1,
      baseAmountMinor: 0,
      currency: 'KES',
      lines: const [],
      createdAt: DateTime.now(),
    ));
    await _loadPeriod(period, existingAccounts: current.expenseAccounts);
  }

  Future<void> copyFromPrevious(String period) async {
    final current = state;
    if (current is! _Loaded) return;
    final prevResult = await _budgetRepo.getPlanByPeriod(_offsetPeriod(period, -1));
    final prevLines = prevResult.fold((_) => <BudgetLine>[], (p) => p?.lines ?? []);
    await _budgetRepo.savePlan(BudgetPlan(
      id: const Uuid().v4(),
      period: period,
      strategyId: '',
      strategyVersion: 1,
      baseAmountMinor: 0,
      currency: 'KES',
      lines: prevLines.map((l) => BudgetLine(
        id: const Uuid().v4(),
        planId: '',
        accountId: l.accountId,
        bucket: l.bucket,
        plannedMinor: l.plannedMinor,
        currency: l.currency,
        rolloverMinor: 0,
        notes: l.notes,
      )).toList(),
      createdAt: DateTime.now(),
    ));
    await _loadPeriod(period, existingAccounts: current.expenseAccounts);
  }

  Future<void> upsertLine(BudgetLine line) async {
    final current = state;
    if (current is! _Loaded || current.plan == null) return;
    await _budgetRepo.upsertLine(line, current.plan!.id);
    await _loadPeriod(current.selectedPeriod,
        existingPeriods: current.periods,
        existingAccounts: current.expenseAccounts,
        selectedLineId: line.id);
  }

  Future<void> deleteLine(String lineId) async {
    final current = state;
    if (current is! _Loaded) return;
    await _budgetRepo.deleteLine(lineId);
    await _loadPeriod(current.selectedPeriod,
        existingPeriods: current.periods,
        existingAccounts: current.expenseAccounts);
  }

  Future<Account?> createExpenseAccount(String name) async {
    final account = Account(
      id: const Uuid().v4(),
      name: name.trim(),
      type: AccountType.expense,
      currency: 'KES',
      liquidity: Liquidity.instant,
      isActive: true,
      createdAt: DateTime.now(),
    );
    final result = await _accountsRepo.createAccount(account);
    return result.fold((_) => null, (_) => account);
  }

  // ── Rollover ──────────────────────────────────────────────────────────────

  /// Computes unspent amounts from previous period and applies as rollover
  /// to matching lines in the current period plan.
  Future<void> applyRollover(String period) async {
    final current = state;
    if (current is! _Loaded || current.plan == null) return;

    final prevPeriod = _offsetPeriod(period, -1);
    final prevPlanResult = await _budgetRepo.getPlanByPeriod(prevPeriod);
    final prevPlan = prevPlanResult.fold((_) => null, (p) => p);
    if (prevPlan == null) return;

    final prevEntriesResult = await _ledgerRepo.getEntriesByPeriod(prevPeriod);
    final prevActuals = <String, int>{};
    prevEntriesResult.fold((_) => null, (entries) {
      for (final entry in entries) {
        for (final line in entry.lines) {
          if (line.side == JournalSide.debit) {
            prevActuals[line.accountId] =
                (prevActuals[line.accountId] ?? 0) + line.amountMinor;
          }
        }
      }
    });

    for (final line in current.plan!.lines) {
      final prevLine = prevPlan.lines.cast<BudgetLine?>()
          .firstWhere((l) => l?.accountId == line.accountId, orElse: () => null);
      if (prevLine == null) continue;
      final prevSpent = prevActuals[prevLine.accountId] ?? 0;
      final unspent = (prevLine.plannedMinor - prevSpent).clamp(0, prevLine.plannedMinor);
      if (unspent > 0) {
        await _budgetRepo.updateLineRollover(line.id, unspent);
      }
    }
    await _loadPeriod(period,
        existingPeriods: current.periods,
        existingAccounts: current.expenseAccounts,
        selectedLineId: current.selectedLineId);
  }

  // ── Quick spend ───────────────────────────────────────────────────────────

  Future<void> quickSpend({
    required BudgetLine line,
    required int amountMinor,
    required String description,
    required Account fromAccount,
  }) async {
    final current = state;
    if (current is! _Loaded) return;
    final now = DateTime.now();
    final entry = JournalEntry(
      id: const Uuid().v4(),
      date: now,
      description: description,
      period: current.selectedPeriod,
      isLocked: false,
      createdAt: now,
      lines: [
        JournalLine(
          id: const Uuid().v4(),
          entryId: '',
          accountId: line.accountId,
          amountMinor: amountMinor,
          currency: line.currency,
          side: JournalSide.debit,
        ),
        JournalLine(
          id: const Uuid().v4(),
          entryId: '',
          accountId: fromAccount.id,
          amountMinor: amountMinor,
          currency: line.currency,
          side: JournalSide.credit,
        ),
      ],
    );
    await _ledgerRepo.postEntry(entry);
    await _loadPeriod(current.selectedPeriod,
        existingPeriods: current.periods,
        existingAccounts: current.expenseAccounts,
        selectedLineId: current.selectedLineId);
  }

  // ── Templates ─────────────────────────────────────────────────────────────

  Future<void> saveAsTemplate(String templateName) async {
    final current = state;
    if (current is! _Loaded || current.plan == null) return;
    final plan = current.plan!;
    await _budgetRepo.savePlan(BudgetPlan(
      id: const Uuid().v4(),
      period: 'template',
      strategyId: plan.strategyId,
      strategyVersion: plan.strategyVersion,
      baseAmountMinor: plan.baseAmountMinor,
      currency: plan.currency,
      isTemplate: true,
      templateName: templateName,
      lines: plan.lines.map((l) => BudgetLine(
        id: const Uuid().v4(),
        planId: '',
        accountId: l.accountId,
        bucket: l.bucket,
        plannedMinor: l.plannedMinor,
        currency: l.currency,
        rolloverMinor: 0,
        notes: l.notes,
      )).toList(),
      createdAt: DateTime.now(),
    ));
    await _loadPeriod(current.selectedPeriod,
        existingPeriods: current.periods,
        existingAccounts: current.expenseAccounts,
        selectedLineId: current.selectedLineId);
  }

  Future<void> applyTemplate(BudgetPlan template, String period) async {
    final current = state;
    if (current is! _Loaded) return;
    await _budgetRepo.savePlan(BudgetPlan(
      id: const Uuid().v4(),
      period: period,
      strategyId: template.strategyId,
      strategyVersion: template.strategyVersion,
      baseAmountMinor: template.baseAmountMinor,
      currency: template.currency,
      lines: template.lines.map((l) => BudgetLine(
        id: const Uuid().v4(),
        planId: '',
        accountId: l.accountId,
        bucket: l.bucket,
        plannedMinor: l.plannedMinor,
        currency: l.currency,
        rolloverMinor: 0,
        notes: l.notes,
      )).toList(),
      createdAt: DateTime.now(),
    ));
    await _loadPeriod(period, existingAccounts: current.expenseAccounts);
  }

  // ── Strategy allocation ───────────────────────────────────────────────────

  /// Applies the active strategy's bucket allocations to the current period.
  Future<void> applyActiveStrategy(String period) async {
    final current = state;
    if (current is! _Loaded) return;
    if (current.totalIncomeMinor == 0) return;

    // Get active strategy id
    final activeIdResult = await _strategyRepo.getActiveStrategyId();
    final activeId = activeIdResult.fold((_) => null, (id) => id) ?? '50_30_20';

    // Load saved buckets, fall back to builtin
    final bucketsResult = await _strategyRepo.getBucketsForStrategy(activeId);
    final dbBuckets = bucketsResult.fold((_) => <StrategyBucket>[], (b) => b);
    final builtinStrategy = BuiltinStrategies.findById(activeId);
    final buckets = dbBuckets.isNotEmpty
        ? dbBuckets
        : (builtinStrategy?.buckets ?? <StrategyBucket>[]);

    if (buckets.isEmpty) return;

    // Ensure plan exists
    var planResult = await _budgetRepo.getPlanByPeriod(period);
    var plan = planResult.fold((_) => null, (p) => p);
    if (plan == null) {
      plan = BudgetPlan(
        id: const Uuid().v4(),
        period: period,
        strategyId: activeId,
        strategyVersion: 1,
        baseAmountMinor: current.totalIncomeMinor,
        currency: 'KES',
        lines: const [],
        createdAt: DateTime.now(),
      );
      await _budgetRepo.savePlan(plan);
    }

    // Upsert a line per bucket per linked account
    for (final bucket in buckets) {
      final planned =
          (current.totalIncomeMinor * bucket.targetPct / 100).round();
      if (bucket.accountIds.isEmpty) {
        // No linked account — create a placeholder line using first expense account
        // matching the bucket name, or skip
        final match = current.expenseAccounts.cast<Account?>().firstWhere(
            (a) => a!.name.toLowerCase().contains(bucket.name.toLowerCase()),
            orElse: () => null);
        if (match == null) continue;
        await _budgetRepo.upsertLine(
          BudgetLine(
            id: const Uuid().v4(),
            planId: plan.id,
            accountId: match.id,
            bucket: bucket.name,
            plannedMinor: planned,
            currency: 'KES',
            rolloverMinor: 0,
          ),
          plan.id,
        );
      } else {
        for (final accountId in bucket.accountIds) {
          await _budgetRepo.upsertLine(
            BudgetLine(
              id: const Uuid().v4(),
              planId: plan.id,
              accountId: accountId,
              bucket: bucket.name,
              plannedMinor: planned,
              currency: 'KES',
              rolloverMinor: 0,
            ),
            plan.id,
          );
        }
      }
    }

    await _loadPeriod(period,
        existingPeriods: current.periods,
        existingAccounts: current.expenseAccounts);
  }

  /// Auto-generates budget lines from income using a percentage split.
  /// ratios: map of accountId -> percentage (0-100), must sum to ≤ 100.
  Future<void> applyStrategyAllocation(
      Map<String, double> ratios, int totalIncomeMinor) async {
    final current = state;
    if (current is! _Loaded || current.plan == null) return;
    final plan = current.plan!;

    for (final entry in ratios.entries) {
      final accountId = entry.key;
      final pct = entry.value;
      final planned = (totalIncomeMinor * pct / 100).round();
      final account = current.expenseAccounts.cast<Account?>()
          .firstWhere((a) => a?.id == accountId, orElse: () => null);
      if (account == null) continue;

      final existingLine = plan.lines.cast<BudgetLine?>()
          .firstWhere((l) => l?.accountId == accountId, orElse: () => null);

      final line = BudgetLine(
        id: existingLine?.id ?? const Uuid().v4(),
        planId: plan.id,
        accountId: accountId,
        bucket: account.name,
        plannedMinor: planned,
        currency: plan.currency,
        rolloverMinor: existingLine?.rolloverMinor ?? 0,
        notes: existingLine?.notes,
      );
      await _budgetRepo.upsertLine(line, plan.id);
    }
    await _loadPeriod(current.selectedPeriod,
        existingPeriods: current.periods,
        existingAccounts: current.expenseAccounts,
        selectedLineId: current.selectedLineId);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _loadPeriod(
    String period, {
    List<String>? existingPeriods,
    List<Account>? existingAccounts,
    String? selectedLineId,
  }) async {
    final List<String> periods;
    if (existingPeriods != null) {
      periods = existingPeriods;
    } else {
      final r = await _budgetRepo.getAllPeriods();
      periods = r.fold((_) => <String>[], (p) => p);
    }

    final List<Account> allAccounts;
    if (existingAccounts != null) {
      allAccounts = existingAccounts;
    } else {
      final r = await _accountsRepo.getAccounts();
      allAccounts = r.fold((_) => <Account>[], (a) => a);
    }
    final expenseAccounts =
        allAccounts.where((a) => a.type == AccountType.expense).toList();
    final incomeAccountIds = allAccounts
        .where((a) => a.type == AccountType.income)
        .map((a) => a.id)
        .toSet();

    final planResult = await _budgetRepo.getPlanByPeriod(period);
    final plan = planResult.fold((_) => null, (p) => p);

    // Current period actuals
    final entriesResult = await _ledgerRepo.getEntriesByPeriod(period);
    final actuals = <String, int>{};
    int totalIncomeMinor = 0;
    entriesResult.fold((_) => null, (entries) {
      for (final entry in entries) {
        for (final line in entry.lines) {
          if (line.side == JournalSide.debit) {
            actuals[line.accountId] =
                (actuals[line.accountId] ?? 0) + line.amountMinor;
          }
          if (incomeAccountIds.contains(line.accountId) &&
              line.side == JournalSide.credit) {
            totalIncomeMinor += line.amountMinor;
          }
        }
      }
    });

    // Previous period actuals for MoM comparison
    final prevEntriesResult =
        await _ledgerRepo.getEntriesByPeriod(_offsetPeriod(period, -1));
    final prevActuals = <String, int>{};
    prevEntriesResult.fold((_) => null, (entries) {
      for (final entry in entries) {
        for (final line in entry.lines) {
          if (line.side == JournalSide.debit) {
            prevActuals[line.accountId] =
                (prevActuals[line.accountId] ?? 0) + line.amountMinor;
          }
        }
      }
    });

    // Sparklines: 6-month actuals per budget line
    final sparklines = <BudgetLineSparkline>[];
    if (plan != null) {
      for (final line in plan.lines) {
        final monthlyActuals = <int>[];
        final sparkPeriods = <String>[];
        for (int i = -5; i <= 0; i++) {
          final p = _offsetPeriod(period, i);
          sparkPeriods.add(p);
          final r = await _ledgerRepo.getEntriesByPeriod(p);
          int spent = 0;
          r.fold((_) => null, (entries) {
            for (final entry in entries) {
              for (final l in entry.lines) {
                if (l.accountId == line.accountId && l.side == JournalSide.debit) {
                  spent += l.amountMinor;
                }
              }
            }
          });
          monthlyActuals.add(spent);
        }
        sparklines.add(BudgetLineSparkline(
          lineId: line.id,
          monthlyActuals: monthlyActuals,
          periods: sparkPeriods,
        ));
      }
    }

    // Templates
    final templatesResult = await _budgetRepo.getTemplates();
    final templates = templatesResult.fold((_) => <BudgetPlan>[], (t) => t);

    final allPeriods =
        periods.contains(period) ? periods : [period, ...periods];
    final resolvedLineId = selectedLineId ?? (plan != null && plan.lines.isNotEmpty ? plan.lines.first.id : null);

    // Load active strategy name
    final activeIdResult = await _strategyRepo.getActiveStrategyId();
    final activeId = activeIdResult.fold((_) => null, (id) => id) ?? '50_30_20';
    final activeStrategy = BuiltinStrategies.findById(activeId);
    final activeStrategyName = activeStrategy?.name ?? activeId;

    emit(BudgetState.loaded(
      periods: allPeriods,
      selectedPeriod: period,
      plan: plan,
      actuals: actuals,
      prevActuals: prevActuals,
      expenseAccounts: expenseAccounts,
      totalIncomeMinor: totalIncomeMinor,
      templates: templates,
      selectedLineId: resolvedLineId,
      sparklines: sparklines,
      activeStrategyId: activeId,
      activeStrategyName: activeStrategyName,
    ));
  }
}
