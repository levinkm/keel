import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:keel/features/assets/domain/repositories/assets_repository.dart';
import 'package:keel/features/investments/domain/repositories/investments_repository.dart';
import 'package:keel/features/budget/domain/entities/budget_plan.dart';
import 'package:keel/features/budget/domain/repositories/budget_repository.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:keel/features/loans/domain/entities/loan.dart';
import 'package:keel/features/loans/domain/loan_engine.dart';
import 'package:keel/features/loans/domain/repositories/loans_repository.dart';
import 'package:keel/features/strategy/domain/entities/strategy.dart';
import 'package:keel/features/strategy/domain/repositories/strategy_repository.dart';

part 'dashboard_state.dart';
part 'dashboard_cubit.freezed.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final AccountsRepository _accountsRepo;
  final LedgerRepository _ledgerRepo;
  final BudgetRepository _budgetRepo;
  final StrategyRepository _strategyRepo;
  final AssetsRepository _assetsRepo;
  final InvestmentsRepository _investmentsRepo;
  final LoansRepository _loansRepo;

  DashboardCubit(this._accountsRepo, this._ledgerRepo, this._budgetRepo, this._strategyRepo, this._assetsRepo, this._investmentsRepo, this._loansRepo)
      : super(const DashboardState.initial());

  static String _period([int monthOffset = 0]) {
    final now = DateTime.now();
    var year = now.year;
    var month = now.month + monthOffset;
    while (month < 1) { month += 12; year--; }
    while (month > 12) { month -= 12; year++; }
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  Future<void> load() async {
    emit(const DashboardState.loading());

    final accountsResult = await _accountsRepo.getAccounts();
    final balancesResult = await _ledgerRepo.getAccountBalances();
    final currentPeriod = _period();
    final entriesResult = await _ledgerRepo.getEntriesByPeriod(currentPeriod);
    final prevEntriesResult = await _ledgerRepo.getEntriesByPeriod(_period(-1));
    final budgetResult = await _budgetRepo.getPlanByPeriod(currentPeriod);

    final accounts = accountsResult.fold((_) => <Account>[], (a) => a);
    final balances = balancesResult.fold((_) => <String, int>{}, (b) => b);
    final entries = entriesResult.fold((_) => <JournalEntry>[], (e) => e);
    final prevEntries = prevEntriesResult.fold((_) => <JournalEntry>[], (e) => e);
    final budgetPlan = budgetResult.fold((_) => null, (p) => p);

    // Classify accounts
    final assetIds = accounts
        .where((a) => a.type == AccountType.asset)
        .map((a) => a.id)
        .toSet();
    final liabilityIds = accounts
        .where((a) => a.type == AccountType.liability)
        .map((a) => a.id)
        .toSet();
    final incomeIds = accounts
        .where((a) => a.type == AccountType.income)
        .map((a) => a.id)
        .toSet();
    final expenseIds = accounts
        .where((a) => a.type == AccountType.expense)
        .map((a) => a.id)
        .toSet();

    // Physical assets + holdings
    final assetsResult = await _assetsRepo.getAssets();
    final physicalAssetsMinor = assetsResult.fold(
      (_) => 0,
      (assets) => assets
          .where((a) => a.holdingId == null)
          .fold<int>(0, (sum, a) => sum + a.bookValue),
    );
    final holdingsResult = await _investmentsRepo.getHoldings();
    final holdingsMinor = holdingsResult.fold(
      (_) => 0,
      (holdings) => holdings
          .where((h) => h.isActive)
          .fold<int>(0, (sum, h) => sum + h.marketValueMinor),
    );
    final totalPhysicalMinor = physicalAssetsMinor + holdingsMinor;

    int netWorth = 0;
    for (final id in assetIds) { netWorth += balances[id] ?? 0; }
    for (final id in liabilityIds) { netWorth -= balances[id] ?? 0; }
    netWorth += totalPhysicalMinor;

    // Prev net worth
    final prevNetWorth = _calcNetWorthFromEntries(prevEntries, assetIds, liabilityIds, balances);

    final income = _sumLines(entries, incomeIds, JournalSide.credit);
    final expenses = _sumLines(entries, expenseIds, JournalSide.debit);

    // Liquid balance — instant-liquidity asset accounts only
    final liquidMinor = accounts
        .where((a) => a.type == AccountType.asset && a.liquidity == Liquidity.instant)
        .fold<int>(0, (s, a) => s + (balances[a.id] ?? 0));

    // Loans — debt, lent, monthly interest
    final loansResult = await _loansRepo.getLoans();
    final loans = loansResult.fold((_) => <Loan>[], (l) => l);
    int totalDebt = 0, totalLent = 0, totalMonthlyInterest = 0;
    for (final loan in loans.where((l) => l.status == LoanStatus.active)) {
      final eventsResult = await _loansRepo.getEventsForLoan(loan.id);
      final events = eventsResult.fold((_) => <LoanEvent>[], (e) => e);
      final summary = LoanEngine.compute(loan, events);
      if (loan.direction == LoanDirection.borrowed) {
        totalDebt += summary.outstandingMinor;
        // Monthly interest = outstanding * monthly rate
        totalMonthlyInterest += (summary.outstandingMinor * loan.monthlyRate).round();
      } else {
        totalLent += summary.outstandingMinor;
      }
    }

    // Actual spend per budget account
    final actualByAccount = <String, int>{};
    for (final entry in entries) {
      for (final line in entry.lines) {
        if (expenseIds.contains(line.accountId) && line.side == JournalSide.debit) {
          actualByAccount[line.accountId] =
              (actualByAccount[line.accountId] ?? 0) + line.amountMinor;
        }
      }
    }

    // Cash flow + net worth history for last 6 months
    final cashFlow = <MonthlyCashFlow>[];
    final netWorthHistory = <MonthlyNetWorth>[];
    for (int i = -5; i <= 0; i++) {
      final p = _period(i);
      if (i == 0) {
        cashFlow.add(MonthlyCashFlow(period: p, incomeMinor: income, expensesMinor: expenses));
        netWorthHistory.add(MonthlyNetWorth(period: p, netWorthMinor: netWorth));
      } else {
        final r = await _ledgerRepo.getEntriesByPeriod(p);
        final e = r.fold((_) => <JournalEntry>[], (x) => x);
        cashFlow.add(MonthlyCashFlow(
          period: p,
          incomeMinor: _sumLines(e, incomeIds, JournalSide.credit),
          expensesMinor: _sumLines(e, expenseIds, JournalSide.debit),
        ));
        // Approximate net worth for past months
        final pastNW = _calcNetWorthFromEntries(e, assetIds, liabilityIds, balances);
        netWorthHistory.add(MonthlyNetWorth(period: p, netWorthMinor: pastNW + totalPhysicalMinor));
      }
    }

    final budgetLines = budgetPlan?.lines ?? [];
    final budgetedExpenses = budgetLines.fold(0, (s, l) => s + l.plannedMinor);

    // Load active strategy for savings target
    final activeIdResult = await _strategyRepo.getActiveStrategyId();
    final activeId = activeIdResult.fold((_) => null, (id) => id) ?? '50_30_20';
    final activeStrategy = BuiltinStrategies.findById(activeId);
    final activeStrategyName = activeStrategy?.name ?? activeId;
    // Find savings bucket target pct
    final bucketsResult = await _strategyRepo.getBucketsForStrategy(activeId);
    final dbBuckets = bucketsResult.fold((_) => <StrategyBucket>[], (b) => b);
    final buckets = dbBuckets.isNotEmpty ? dbBuckets : (activeStrategy?.buckets ?? []);
    final savingsBucket = buckets.cast<StrategyBucket?>().firstWhere(
        (b) => b!.name.toLowerCase().contains('sav'),
        orElse: () => null);
    final strategyTargetSavingsPct = savingsBucket?.targetPct ?? 0;

    emit(DashboardState.loaded(DashboardData(
      netWorthMinor: netWorth,
      prevNetWorthMinor: prevNetWorth,
      incomeMinor: income,
      expensesMinor: expenses,
      budgetedExpensesMinor: budgetedExpenses,
      budgetedIncomeMinor: 0,
      physicalAssetsMinor: totalPhysicalMinor,
      liquidMinor: liquidMinor,
      totalDebtMinor: totalDebt,
      totalLentMinor: totalLent,
      totalInterestMinor: totalMonthlyInterest,
      accounts: accounts.where((a) => a.isActive).toList(),
      balances: balances,
      budgetLines: budgetLines,
      actualByAccount: actualByAccount,
      recentEntries: entries.take(8).toList(),
      cashFlow: cashFlow,
      netWorthHistory: netWorthHistory,
      activeStrategyName: activeStrategyName,
      strategyTargetSavingsPct: strategyTargetSavingsPct,
    )));
  }

  int _sumLines(List<JournalEntry> entries, Set<String> accountIds, JournalSide side) {
    int total = 0;
    for (final entry in entries) {
      for (final line in entry.lines) {
        if (accountIds.contains(line.accountId) && line.side == side) {
          total += line.amountMinor;
        }
      }
    }
    return total;
  }

  int _calcNetWorthFromEntries(
    List<JournalEntry> entries,
    Set<String> assetIds,
    Set<String> liabilityIds,
    Map<String, int> currentBalances,
  ) {
    // Approximate: current net worth minus current period net movement
    int movement = 0;
    for (final entry in entries) {
      for (final line in entry.lines) {
        if (assetIds.contains(line.accountId)) {
          movement += line.side == JournalSide.debit ? line.amountMinor : -line.amountMinor;
        } else if (liabilityIds.contains(line.accountId)) {
          movement += line.side == JournalSide.credit ? line.amountMinor : -line.amountMinor;
        }
      }
    }
    int netWorth = 0;
    for (final id in assetIds) { netWorth += currentBalances[id] ?? 0; }
    for (final id in liabilityIds) { netWorth -= currentBalances[id] ?? 0; }
    return netWorth - movement;
  }
}
