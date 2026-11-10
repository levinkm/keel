import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/features/budget/data/datasources/budget_local_datasource.dart';
import 'package:keel/features/budget/domain/entities/budget_plan.dart';
import 'package:keel/features/budget/domain/repositories/budget_repository.dart';
import 'package:uuid/uuid.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetLocalDatasource _datasource;
  BudgetRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<String>>> getAllPeriods() async {
    try {
      final rows = await _datasource.getAllPeriods();
      return Right(rows
          .where((r) => (r['is_template'] as int? ?? 0) == 0)
          .map((r) => r['period'] as String)
          .toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BudgetPlan?>> getPlanByPeriod(String period) async {
    try {
      final row = await _datasource.getPlanByPeriod(period);
      if (row == null) return const Right(null);
      return Right(await _rowToPlan(row));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BudgetPlan>> savePlan(BudgetPlan plan) async {
    try {
      final id = const Uuid().v4();
      await _datasource.insertPlan(
        {
          'id': id,
          'period': plan.period,
          'strategy_id': plan.strategyId,
          'strategy_version': plan.strategyVersion,
          'base_amount_minor': plan.baseAmountMinor,
          'currency': plan.currency,
          'is_template': plan.isTemplate ? 1 : 0,
          'template_name': plan.templateName,
          'created_at': DateTime.now().toIso8601String(),
        },
        plan.lines.map((l) => {
          'id': const Uuid().v4(),
          'plan_id': id,
          'account_id': l.accountId,
          'bucket': l.bucket,
          'planned_minor': l.plannedMinor,
          'currency': l.currency,
          'rollover_minor': l.rolloverMinor,
          'notes': l.notes,
        }).toList(),
      );
      return Right(plan);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> upsertLine(BudgetLine line, String planId) async {
    try {
      await _datasource.upsertLine({
        'id': line.id,
        'plan_id': planId,
        'account_id': line.accountId,
        'bucket': line.bucket,
        'planned_minor': line.plannedMinor,
        'currency': line.currency,
        'rollover_minor': line.rolloverMinor,
        'notes': line.notes,
      });
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLine(String lineId) async {
    try {
      await _datasource.deleteLine(lineId);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLineRollover(
      String lineId, int rolloverMinor) async {
    try {
      await _datasource.updateLineRollover(lineId, rolloverMinor);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BudgetPlan>>> getTemplates() async {
    try {
      final rows = await _datasource.getTemplates();
      final plans = await Future.wait(rows.map(_rowToPlan));
      return Right(plans);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  Future<BudgetPlan> _rowToPlan(Map<String, dynamic> row) async {
    final lineRows = await _datasource.getLinesForPlan(row['id'] as String);
    final lines = lineRows.map((l) => BudgetLine(
          id: l['id'] as String,
          planId: l['plan_id'] as String,
          accountId: l['account_id'] as String,
          bucket: l['bucket'] as String,
          plannedMinor: l['planned_minor'] as int,
          currency: l['currency'] as String,
          rolloverMinor: l['rollover_minor'] as int,
          notes: l['notes'] as String?,
        )).toList();
    return BudgetPlan(
      id: row['id'] as String,
      period: row['period'] as String,
      strategyId: row['strategy_id'] as String,
      strategyVersion: row['strategy_version'] as int,
      baseAmountMinor: row['base_amount_minor'] as int,
      currency: row['currency'] as String,
      lines: lines,
      isTemplate: (row['is_template'] as int? ?? 0) == 1,
      templateName: row['template_name'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
