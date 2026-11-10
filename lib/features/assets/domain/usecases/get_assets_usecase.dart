import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/core/usecases/usecase.dart';
import '../entities/asset.dart';
import '../repositories/assets_repository.dart';

class GetAssetsUsecase implements Usecase<List<Asset>, NoParams> {
  final AssetsRepository _repository;
  GetAssetsUsecase(this._repository);

  @override
  Future<Either<Failure, List<Asset>>> call([NoParams? params]) =>
      _repository.getAssets();
}
