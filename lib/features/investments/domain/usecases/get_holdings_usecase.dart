import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/core/usecases/usecase.dart';
import '../entities/holding.dart';
import '../repositories/investments_repository.dart';

class GetHoldingsUsecase implements Usecase<List<Holding>, NoParams> {
  final InvestmentsRepository _repository;
  GetHoldingsUsecase(this._repository);

  @override
  Future<Either<Failure, List<Holding>>> call([NoParams? params]) =>
      _repository.getHoldings();
}
