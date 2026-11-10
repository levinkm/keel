import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/core/usecases/usecase.dart';
import '../entities/net_worth.dart';
import '../repositories/net_worth_repository.dart';

class GetNetWorthUsecase implements Usecase<NetWorth, NoParams> {
  final NetWorthRepository _repository;
  GetNetWorthUsecase(this._repository);

  @override
  Future<Either<Failure, NetWorth>> call([NoParams? params]) =>
      _repository.getNetWorth();
}
