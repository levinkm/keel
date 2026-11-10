import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/core/usecases/usecase.dart';
import '../entities/loan.dart';
import '../repositories/loans_repository.dart';

class GetLoansUsecase implements Usecase<List<Loan>, NoParams> {
  final LoansRepository _repository;
  GetLoansUsecase(this._repository);

  @override
  Future<Either<Failure, List<Loan>>> call([NoParams? params]) =>
      _repository.getLoans();
}
