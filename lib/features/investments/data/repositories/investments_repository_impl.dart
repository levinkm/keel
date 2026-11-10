import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/features/investments/data/datasources/investments_local_datasource.dart';
import 'package:keel/features/investments/domain/entities/holding.dart';
import 'package:keel/features/investments/domain/repositories/investments_repository.dart';
import 'package:uuid/uuid.dart';

class InvestmentsRepositoryImpl implements InvestmentsRepository {
  final InvestmentsLocalDatasource _datasource;
  InvestmentsRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<Holding>>> getHoldings() async {
    try {
      final rows = await _datasource.getHoldings();
      final holdings = await Future.wait(rows.map((r) async {
        final lotRows = await _datasource.getLotsForHolding(r['id'] as String);
        final lots = lotRows.map((l) => HoldingLot(
              id: l['id'] as String,
              holdingId: l['holding_id'] as String,
              date: DateTime.parse(l['date'] as String),
              units: (l['units'] as num).toDouble(),
              priceMinor: l['price_minor'] as int,
              feesMinor: l['fees_minor'] as int,
              currency: l['currency'] as String,
              lotType: LotType.values.byName(
                  (l['lot_type'] as String?) ?? 'purchase'),
            )).toList();
        return Holding(
          id: r['id'] as String,
          name: r['name'] as String,
          type: HoldingType.values.byName(r['type'] as String),
          institution: r['institution'] as String,
          accountId: r['account_id'] as String,
          currency: r['currency'] as String,
          liquidity: r['liquidity'] as String,
          isActive: (r['is_active'] as int) == 1,
          currentPriceMinor: r['current_price_minor'] as int?,
          linkedAssetId: null,
          annualRateBp: r['annual_rate_bp'] as int?,
          compoundingFreq: CompoundingFreq.values.byName(
              (r['compounding_freq'] as String?) ?? 'none'),
          maturityDate: r['maturity_date'] != null
              ? DateTime.parse(r['maturity_date'] as String)
              : null,
          lots: lots,
          createdAt: DateTime.parse(r['created_at'] as String),
        );
      }));
      return Right(holdings);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createHolding(Holding holding) async {
    try {
      final id = holding.id.isEmpty ? const Uuid().v4() : holding.id;
      await _datasource.insertHolding({
        'id': id,
        'name': holding.name,
        'type': holding.type.name,
        'institution': holding.institution,
        'account_id': holding.accountId,
        'currency': holding.currency,
        'liquidity': holding.liquidity,
        'is_active': 1,
        'current_price_minor': holding.currentPriceMinor,
        'annual_rate_bp': holding.annualRateBp,
        'compounding_freq': holding.compoundingFreq.name,
        'maturity_date': holding.maturityDate?.toIso8601String(),
        'created_at': holding.createdAt.toIso8601String(),
      });
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateHolding(Holding holding) async {
    try {
      await _datasource.updateHolding({
        'id': holding.id,
        'name': holding.name,
        'type': holding.type.name,
        'institution': holding.institution,
        'account_id': holding.accountId,
        'currency': holding.currency,
        'liquidity': holding.liquidity,
        'is_active': holding.isActive ? 1 : 0,
        'current_price_minor': holding.currentPriceMinor,
        'annual_rate_bp': holding.annualRateBp,
        'compounding_freq': holding.compoundingFreq.name,
        'maturity_date': holding.maturityDate?.toIso8601String(),
      });
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCurrentPrice(String holdingId, int priceMinor) async {
    try {
      await _datasource.updateCurrentPrice(holdingId, priceMinor);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deactivateHolding(String holdingId) async {
    try {
      await _datasource.deactivateHolding(holdingId);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addLot(HoldingLot lot) async {
    try {
      await _datasource.insertLot({
        'id': lot.id.isEmpty ? const Uuid().v4() : lot.id,
        'holding_id': lot.holdingId,
        'date': lot.date.toIso8601String(),
        'units': lot.units,
        'price_minor': lot.priceMinor,
        'fees_minor': lot.feesMinor,
        'currency': lot.currency,
        'lot_type': lot.lotType.name,
      });
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLot(String lotId) async {
    try {
      await _datasource.deleteLot(lotId);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
