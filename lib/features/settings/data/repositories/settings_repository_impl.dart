import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:keel/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDatasource _datasource;
  SettingsRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, Map<String, String>>> getAll() async {
    try {
      return Right(await _datasource.getAll());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> set(String key, String value) async {
    try {
      await _datasource.set(key, value);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
