import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';

abstract class SettingsRepository {
  Future<Either<Failure, Map<String, String>>> getAll();
  Future<Either<Failure, void>> set(String key, String value);
}
