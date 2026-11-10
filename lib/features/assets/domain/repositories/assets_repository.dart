import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import '../entities/asset.dart';

abstract class AssetsRepository {
  Future<Either<Failure, List<Asset>>> getAssets();
  Future<Either<Failure, Asset>> createAsset(Asset asset);
  Future<Either<Failure, void>> updateAsset(Asset asset);
  Future<Either<Failure, void>> addAttachment(AssetAttachment attachment);
  Future<Either<Failure, List<AssetAttachment>>> getAttachments(String assetId);
  Future<Either<Failure, void>> removeAttachment(String attachmentId);
}
