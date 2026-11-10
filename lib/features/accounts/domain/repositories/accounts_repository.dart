import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import '../entities/account.dart';

abstract class AccountsRepository {
  Future<Either<Failure, List<Account>>> getAccounts();
  Future<Either<Failure, Account>> getAccountById(String id);
  Future<Either<Failure, Account>> createAccount(Account account);
  Future<Either<Failure, void>> updateAccount(Account account);
}
