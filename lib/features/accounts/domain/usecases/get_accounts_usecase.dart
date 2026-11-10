import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/core/usecases/usecase.dart';
import '../entities/account.dart';
import '../repositories/accounts_repository.dart';

class GetAccountsUsecase implements Usecase<List<Account>, NoParams> {
  final AccountsRepository _repository;
  GetAccountsUsecase(this._repository);

  @override
  Future<Either<Failure, List<Account>>> call([NoParams? params]) =>
      _repository.getAccounts();
}
