import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/core/usecases/usecase.dart';
import '../repositories/settings_repository.dart';

class GetSettingsUsecase implements Usecase<Map<String, String>, NoParams> {
  final SettingsRepository _repository;
  GetSettingsUsecase(this._repository);

  @override
  Future<Either<Failure, Map<String, String>>> call([NoParams? params]) =>
      _repository.getAll();
}
