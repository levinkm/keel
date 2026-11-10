import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:keel/features/budget/domain/entities/budget_plan.dart';
import 'package:keel/features/budget/domain/repositories/budget_repository.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/income/domain/entities/income_stream.dart';
import 'package:keel/features/income/domain/repositories/income_repository.dart';
import 'package:keel/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:keel/features/strategy/domain/entities/strategy.dart';
import 'package:keel/features/strategy/domain/repositories/strategy_repository.dart';
import 'package:uuid/uuid.dart';

part 'strategy_state.dart';
part 'strategy_cubit.freezed.dart';

class StrategyCubit extends Cubit<StrategyState> {
  final StrategyRepository _strategyRepo;
  final AccountsRepository _accountsRepo;
  final LedgerRepository _ledgerRepo;
  final BudgetRepository _budgetRepo;
  final IncomeRepository _incomeRepo;

  StrategyCubit(
    this._strategyRepo,
    this._accountsRepo,
    this._ledgerRepo,
    this._budgetRepo,
    this._incomeRepo,
  ) : super(const StrategyState.initial());

  static String _todayPeriod() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> load() async {
    emit(const StrategyState.loading());
    await _reload();
  }

  Future<void> switchStrategy(String strategyId) async {
    await _strategyRepo.setActiveStrategyId(strategyId);
    await _reload();
  }

  Future<void> saveBuckets(List<StrategyBucket> buckets) async {
    final current = state;
    if (current is! _Loaded) return;

    // Validate total = 100
    final total = buckets.fold(0, (s, b) => s + b.targetPct);
    if (total != 100) {
      emit(current.copyWith(
          validationError: 'Bucket percentages must add up to 100% (currently $total%).'));
      return;
    }

    await _strategyRepo.deleteBucketsForStrategy(current.activeStrategy.id);
    await _strategyRepo.saveBuckets(buckets);
    await _reload();
  }

  Future<void> applyToBudget() async {
    final current = state;
    if (current is! _Loaded) return;

    // Block if any bucket has no linked accounts
    final unlinked = current.buckets
        .where((b) => b.accountIds.isEmpty)
        .map((b) => b.name)
        .toList();
    if (unlinked.isNotEmpty) {
      emit(current.copyWith(
          validationError:
              'Link accounts to these buckets first: ${unlinked.join(', ')}.'));
      return;
    }

    // Resolve base income: prefer actual ledger income, fall back to stream totals
    int baseIncome = current.monthlyIncomeMinor;
    if (baseIncome == 0) {
      final streamsResult = await _incomeRepo.getStreams();
      streamsResult.fold((_) => null, (streams) {
        for (final s in streams) {
          if (s.isActive && s.frequency != IncomeFrequency.irregular) {
            baseIncome += s.effectiveReliableAmount;
          }
        }
      });
    }

    if (baseIncome == 0) {
      emit(current.copyWith(
          validationError:
              'No income found. Record income or add income streams first.'));
      return;
    }

    final period = _todayPeriod();
    final planResult = await _budgetRepo.getPlanByPeriod(period);
    var plan = planResult.fold((_) => null, (p) => p);

    if (plan == null) {
      plan = BudgetPlan(
        id: const Uuid().v4(),
        period: period,
        strategyId: current.activeStrategy.id,
        strategyVersion: 1,
        baseAmountMinor: baseIncome,
        currency: 'KES',
        lines: const [],
        createdAt: DateTime.now(),
      );
      await _budgetRepo.savePlan(plan);
    }

    for (final bucket in current.buckets) {
      final bucketAmount = (baseIncome * bucket.targetPct / 100).round();
      final weights = bucket.resolvedWeights();
      int distributed = 0;
      for (int i = 0; i < bucket.accountIds.length; i++) {
        final accountId = bucket.accountIds[i];
        final isLast = i == bucket.accountIds.length - 1;
        final planned = isLast
            ? bucketAmount - distributed
            : (bucketAmount * (weights[accountId] ?? 0) / 100).round();
        distributed += planned;
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

    emit(current.copyWith(validationError: null));
  }

  void clearValidationError() {
    final current = state;
    if (current is! _Loaded) return;
    emit(current.copyWith(validationError: null));
  }

  Future<void> _reload() async {
    final activeIdResult = await _strategyRepo.getActiveStrategyId();
    final activeId = activeIdResult.fold((_) => null, (id) => id) ?? '50_30_20';

    // Load user-customised buckets from DB; fall back to builtin defaults
    final bucketsResult = await _strategyRepo.getBucketsForStrategy(activeId);
    final dbBuckets = bucketsResult.fold((_) => <StrategyBucket>[], (b) => b);

    final builtinStrategy = BuiltinStrategies.findById(activeId);
    final activeStrategy = builtinStrategy ??
        Strategy(
          id: activeId,
          name: activeId,
          tagline: 'Custom',
          description: '',
          isBuiltin: false,
          buckets: dbBuckets,
          createdAt: DateTime.now(),
        );

    // Use DB buckets if saved, else use builtin defaults
    final buckets = dbBuckets.isNotEmpty
        ? dbBuckets
        : List<StrategyBucket>.from(activeStrategy.buckets);

    final accountsResult = await _accountsRepo.getAccounts();
    final allAccounts = accountsResult.fold((_) => <Account>[], (a) => a);
    final expenseAccounts =
        allAccounts.where((a) => a.type == AccountType.expense).toList();
    final assetAccounts =
        allAccounts.where((a) => a.type == AccountType.asset).toList();

    // Monthly income from ledger
    final incomeAccountIds = allAccounts
        .where((a) => a.type == AccountType.income)
        .map((a) => a.id)
        .toSet();
    final entriesResult =
        await _ledgerRepo.getEntriesByPeriod(_todayPeriod());
    int monthlyIncome = 0;
    entriesResult.fold((_) => null, (entries) {
      for (final entry in entries) {
        for (final line in entry.lines) {
          if (incomeAccountIds.contains(line.accountId) &&
              line.side == JournalSide.credit) {
            monthlyIncome += line.amountMinor;
          }
        }
      }
    });

    emit(StrategyState.loaded(
      activeStrategy: activeStrategy,
      buckets: buckets,
      allStrategies: BuiltinStrategies.all,
      expenseAccounts: expenseAccounts,
      assetAccounts: assetAccounts,
      monthlyIncomeMinor: monthlyIncome,
    ));
  }
}
