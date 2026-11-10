import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/features/assets/data/datasources/assets_local_datasource.dart';
import 'package:keel/features/assets/domain/entities/asset.dart';
import 'package:keel/features/assets/domain/repositories/assets_repository.dart';
import 'package:uuid/uuid.dart';

class AssetsRepositoryImpl implements AssetsRepository {
  final AssetsLocalDatasource _datasource;
  AssetsRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<Asset>>> getAssets() async {
    try {
      final rows = await _datasource.getAssets();
      return Right(rows.map(_rowToAsset).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Asset>> createAsset(Asset asset) async {
    try {
      await _datasource.insertAsset(_assetToRow(asset, const Uuid().v4()));
      return Right(asset);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateAsset(Asset asset) async {
    try {
      await _datasource.updateAsset(_assetToRow(asset, asset.id));
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addAttachment(AssetAttachment a) async {
    try {
      await _datasource.insertAttachment({
        'id': a.id,
        'asset_id': a.assetId,
        'file_path': a.filePath,
        'file_name': a.fileName,
        'mime_type': a.mimeType,
        'created_at': a.createdAt.toIso8601String(),
      });
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AssetAttachment>>> getAttachments(String assetId) async {
    try {
      final rows = await _datasource.getAttachmentsForAsset(assetId);
      return Right(rows.map((r) => AssetAttachment(
        id: r['id'] as String,
        assetId: r['asset_id'] as String,
        filePath: r['file_path'] as String,
        fileName: r['file_name'] as String,
        mimeType: r['mime_type'] as String?,
        createdAt: DateTime.parse(r['created_at'] as String),
      )).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeAttachment(String attachmentId) async {
    try {
      await _datasource.deleteAttachment(attachmentId);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  Map<String, dynamic> _assetToRow(Asset a, String id) => {
        'id': id,
        'name': a.name,
        'class': a.assetClass.name,
        'acquisition_date': a.acquisitionDate.toIso8601String(),
        'cost_minor': a.costMinor,
        'currency': a.currency,
        'ownership_share_bp': a.ownershipShareBp,
        'current_value_minor': a.currentValueMinor,
        'valuation_date': a.valuationDate?.toIso8601String(),
        'valuation_source': a.valuationSource,
        'depreciation_method': a.depreciationMethod?.name,
        'annual_rate_bp': a.annualRateBp,
        'salvage_minor': a.salvageMinor,
        'linked_loan_id': a.linkedLoanId,
        'insurance_expiry': a.insuranceExpiry?.toIso8601String(),
        'status': a.status.name,
        'location': a.location,
        'notes': a.notes,
        'holding_id': a.holdingId,
        'created_at': a.createdAt.toIso8601String(),
      };

  Asset _rowToAsset(Map<String, dynamic> r) => Asset(
        id: r['id'] as String,
        name: r['name'] as String,
        assetClass: AssetClass.values.byName(r['class'] as String),
        acquisitionDate: DateTime.parse(r['acquisition_date'] as String),
        costMinor: r['cost_minor'] as int,
        currency: r['currency'] as String,
        ownershipShareBp: r['ownership_share_bp'] as int,
        currentValueMinor: r['current_value_minor'] as int?,
        valuationDate: r['valuation_date'] != null ? DateTime.parse(r['valuation_date'] as String) : null,
        valuationSource: r['valuation_source'] as String?,
        depreciationMethod: r['depreciation_method'] != null ? DepreciationMethod.values.byName(r['depreciation_method'] as String) : null,
        annualRateBp: r['annual_rate_bp'] as int?,
        salvageMinor: r['salvage_minor'] as int,
        linkedLoanId: r['linked_loan_id'] as String?,
        insuranceExpiry: r['insurance_expiry'] != null ? DateTime.parse(r['insurance_expiry'] as String) : null,
        status: AssetStatus.values.byName(r['status'] as String),
        location: r['location'] as String?,
        notes: r['notes'] as String?,
        holdingId: r['holding_id'] as String?,
        createdAt: DateTime.parse(r['created_at'] as String),
      );
}
