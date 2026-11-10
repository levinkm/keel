import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/core/usecases/usecase.dart';
import '../entities/income_stream.dart';
import '../repositories/income_repository.dart';

class GetIncomeStreamsUsecase implements Usecase<List<IncomeStream>, NoParams> {
  final IncomeRepository _repository;
  GetIncomeStreamsUsecase(this._repository);

  @override
  Future<Either<Failure, List<IncomeStream>>> call([NoParams? params]) =>
      _repository.getStreams();
}
