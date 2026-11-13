import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/features/accounts/data/datasources/accounts_local_datasource.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';
import 'package:keel/features/accounts/domain/repositories/accounts_repository.dart';

class AccountsRepositoryImpl implements AccountsRepository {
  final AccountsLocalDatasource _datasource;
  AccountsRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<Account>>> getAccounts() async {
    try {
      final rows = await _datasource.getAccounts();
      return Right(rows.map((r) => r.toAccount()).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Account>> getAccountById(String id) async {
    try {
      final row = await _datasource.getAccountById(id);
      if (row == null) return const Left(DatabaseFailure('Account not found'));
      return Right(row.toAccount());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Account>> createAccount(Account account) async {
    try {
      final data = {
        'id': account.id,
        'name': account.name,
        'type': account.type.name,
        'currency': account.currency,
        'liquidity': account.liquidity.name,
        'is_active': 1,
        'overdraft_limit_minor': account.overdraftLimitMinor,
        'created_at': DateTime.now().toIso8601String(),
      };
      await _datasource.insertAccount(data);
      return Right(account);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateAccount(Account account) async {
    try {
      await _datasource.updateAccount({
        'id': account.id,
        'name': account.name,
        'type': account.type.name,
        'currency': account.currency,
        'liquidity': account.liquidity.name,
        'is_active': account.isActive ? 1 : 0,
        'overdraft_limit_minor': account.overdraftLimitMinor,
        'created_at': account.createdAt.toIso8601String(),
      });
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
