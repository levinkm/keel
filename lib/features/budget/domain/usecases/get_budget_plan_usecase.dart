import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/core/usecases/usecase.dart';
import '../entities/budget_plan.dart';
import '../repositories/budget_repository.dart';

class GetBudgetPlanUsecase implements Usecase<BudgetPlan?, String> {
  final BudgetRepository _repository;
  GetBudgetPlanUsecase(this._repository);

  @override
  Future<Either<Failure, BudgetPlan?>> call([String? period]) {
    Usecase.assertParamsRequired(period);
    return _repository.getPlanByPeriod(period!);
  }
}
