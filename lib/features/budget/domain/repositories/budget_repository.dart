import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import '../entities/budget_plan.dart';

abstract class BudgetRepository {
  Future<Either<Failure, List<String>>> getAllPeriods();
  Future<Either<Failure, BudgetPlan?>> getPlanByPeriod(String period);
  Future<Either<Failure, BudgetPlan>> savePlan(BudgetPlan plan);
  Future<Either<Failure, void>> upsertLine(BudgetLine line, String planId);
  Future<Either<Failure, void>> deleteLine(String lineId);
  Future<Either<Failure, void>> updateLineRollover(String lineId, int rolloverMinor);
  Future<Either<Failure, List<BudgetPlan>>> getTemplates();
}
