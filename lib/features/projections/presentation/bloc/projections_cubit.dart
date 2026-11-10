import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:keel/features/budget/domain/repositories/budget_repository.dart';
import 'package:keel/features/income/domain/repositories/income_repository.dart';
import 'package:keel/features/loans/domain/entities/loan.dart';
import 'package:keel/features/loans/domain/loan_engine.dart';
import 'package:keel/features/loans/domain/repositories/loans_repository.dart';
import 'package:keel/features/net_worth/domain/repositories/net_worth_repository.dart';

part 'projections_state.dart';
part 'projections_cubit.freezed.dart';

class ProjectionsCubit extends Cubit<ProjectionsState> {
  final NetWorthRepository _netWorthRepo;
  final IncomeRepository _incomeRepo;
  final BudgetRepository _budgetRepo;
  final LoansRepository _loansRepo;

  ProjectionsCubit(this._netWorthRepo, this._incomeRepo, this._budgetRepo,
      this._loansRepo)
      : super(const ProjectionsState.initial());

  Future<void> load() async {
    emit(const ProjectionsState.loading());
    await _reload();
  }

  Future<void> updateAssumptions({
    int? months,
    double? incomeGrowthPct,
    double? expenseGrowthPct,
    int? savingsTargetMinor,
  }) async {
    final current = state;
    if (current is! _Loaded) return;
    emit(current.copyWith(
      projectionMonths: months ?? current.projectionMonths,
      incomeGrowthPct: incomeGrowthPct ?? current.incomeGrowthPct,
      expenseGrowthPct: expenseGrowthPct ?? current.expenseGrowthPct,
      savingsTargetMinor: savingsTargetMinor ?? current.savingsTargetMinor,
    ));
    // Recompute projections with new assumptions
    final s = state as _Loaded;
    final points = _buildProjection(
      startNetWorthMinor: s.currentNetWorthMinor,
      monthlyIncomeMinor: s.monthlyIncomeMinor,
      monthlyExpensesMinor: s.monthlyExpensesMinor,
      loanSchedules: s.loanSchedules,
      months: s.projectionMonths,
      incomeGrowthPct: s.incomeGrowthPct,
      expenseGrowthPct: s.expenseGrowthPct,
    );
    emit(s.copyWith(projectionPoints: points));
  }

  Future<void> _reload() async {
    try {
      // Current net worth
      final nwResult = await _netWorthRepo.getNetWorth();
      final currentNW = nwResult.fold((_) => 0, (nw) => nw.totalMinor);

      // Monthly income from active streams
      final incomeResult = await _incomeRepo.getStreams();
      final streams = incomeResult.fold((_) => <dynamic>[], (s) => s);
      final monthlyIncome = streams.fold<int>(
          0, (s, stream) => s + (stream.effectiveReliableAmount as int));

      // Monthly expenses: current budget plan, else 3-month ledger average
      final now = DateTime.now();
      final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final budgetResult = await _budgetRepo.getPlanByPeriod(period);
      final budgetPlan = budgetResult.fold((_) => null, (p) => p);
      int monthlyExpenses = budgetPlan?.lines
              .fold<int>(0, (s, l) => s + l.plannedMinor) ??
          0;

      if (monthlyExpenses == 0) {
        int totalActual = 0;
        int periodsWithData = 0;
        for (int i = 1; i <= 3; i++) {
          var m = now.month - i;
          var y = now.year;
          if (m <= 0) { m += 12; y--; }
          final p = '$y-${m.toString().padLeft(2, '0')}';
          final pr = await _budgetRepo.getPlanByPeriod(p);
          final plan = pr.fold((_) => null, (x) => x);
          if (plan != null && plan.lines.isNotEmpty) {
            totalActual += plan.lines.fold<int>(0, (s, l) => s + l.plannedMinor);
            periodsWithData++;
          }
        }
        if (periodsWithData > 0) {
          monthlyExpenses = totalActual ~/ periodsWithData;
        }
      }
      // ignore: unused_local_variable
      final expensesFromBudget = budgetPlan?.lines.isNotEmpty ?? false;

      // Loan schedules for payoff projection
      final loansResult = await _loansRepo.getLoans();
      final loans = loansResult.fold((_) => <Loan>[], (l) => l);
      final loanSchedules = <LoanProjection>[];

      for (final loan in loans.where((l) => l.status == LoanStatus.active &&
          l.direction == LoanDirection.borrowed)) {
        final eventsResult = await _loansRepo.getEventsForLoan(loan.id);
        final events = eventsResult.fold((_) => <LoanEvent>[], (e) => e);
        final summary = LoanEngine.compute(loan, events);
        loanSchedules.add(LoanProjection(
          loan: loan,
          outstandingMinor: summary.outstandingMinor,
          monthlyPaymentMinor: loan.instalmentMinor,
          remainingMonths: summary.remainingMonths,
        ));
      }

      const defaultMonths = 24;
      const defaultIncomeGrowth = 0.0;
      const defaultExpenseGrowth = 0.0;

      final points = _buildProjection(
        startNetWorthMinor: currentNW,
        monthlyIncomeMinor: monthlyIncome,
        monthlyExpensesMinor: monthlyExpenses,
        loanSchedules: loanSchedules,
        months: defaultMonths,
        incomeGrowthPct: defaultIncomeGrowth,
        expenseGrowthPct: defaultExpenseGrowth,
      );

      emit(ProjectionsState.loaded(
        currentNetWorthMinor: currentNW,
        monthlyIncomeMinor: monthlyIncome,
        monthlyExpensesMinor: monthlyExpenses,
        incomeStreamCount: streams.length,
        expensesFromBudget: (budgetPlan?.lines.isNotEmpty ?? false),
        loanSchedules: loanSchedules,
        projectionPoints: points,
        projectionMonths: defaultMonths,
        incomeGrowthPct: defaultIncomeGrowth,
        expenseGrowthPct: defaultExpenseGrowth,
        savingsTargetMinor: 0,
      ));
    } catch (e) {
      emit(ProjectionsState.error(e.toString()));
    }
  }

  List<ProjectionPoint> _buildProjection({
    required int startNetWorthMinor,
    required int monthlyIncomeMinor,
    required int monthlyExpensesMinor,
    required List<LoanProjection> loanSchedules,
    required int months,
    required double incomeGrowthPct,
    required double expenseGrowthPct,
  }) {
    final points = <ProjectionPoint>[];
    int netWorth = startNetWorthMinor;
    final now = DateTime.now();

    for (int i = 0; i <= months; i++) {
      final date = DateTime(now.year, now.month + i);

      // Apply growth rates
      final income = (monthlyIncomeMinor *
              (1 + incomeGrowthPct / 100 / 12 * i))
          .round();
      final expenses = (monthlyExpensesMinor *
              (1 + expenseGrowthPct / 100 / 12 * i))
          .round();

      final loanPayments = loanSchedules
          .where((lp) => i < lp.remainingMonths)
          .fold<int>(0, (s, lp) => s + lp.monthlyPaymentMinor);

      if (i > 0) {
        netWorth += income - expenses - loanPayments;
      }

      points.add(ProjectionPoint(
        date: date,
        netWorthMinor: netWorth,
        incomeMinor: income,
        expensesMinor: expenses,
        loanPaymentsMinor: loanPayments,
        savingsMinor: income - expenses - loanPayments,
      ));
    }
    return points;
  }
}

class LoanProjection {
  final Loan loan;
  final int outstandingMinor;
  final int monthlyPaymentMinor;
  final int remainingMonths;
  const LoanProjection({
    required this.loan,
    required this.outstandingMinor,
    required this.monthlyPaymentMinor,
    required this.remainingMonths,
  });
}

class ProjectionPoint {
  final DateTime date;
  final int netWorthMinor;
  final int incomeMinor;
  final int expensesMinor;
  final int loanPaymentsMinor;
  final int savingsMinor;
  const ProjectionPoint({
    required this.date,
    required this.netWorthMinor,
    required this.incomeMinor,
    required this.expensesMinor,
    required this.loanPaymentsMinor,
    required this.savingsMinor,
  });
}
