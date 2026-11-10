import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/features/assets/domain/repositories/assets_repository.dart';
import 'package:keel/features/investments/domain/repositories/investments_repository.dart';
import 'package:keel/features/net_worth/data/datasources/net_worth_local_datasource.dart';
import 'package:keel/features/net_worth/domain/entities/net_worth.dart';
import 'package:keel/features/net_worth/domain/repositories/net_worth_repository.dart';

class NetWorthRepositoryImpl implements NetWorthRepository {
  final NetWorthLocalDatasource _datasource;
  final AssetsRepository _assetsRepo;
  final InvestmentsRepository _holdingsRepo;
  NetWorthRepositoryImpl(this._datasource, this._assetsRepo, this._holdingsRepo);

  @override
  Future<Either<Failure, NetWorth>> getNetWorth() async {
    try {
      final balances = await _datasource.getAccountBalancesByType();
      int totalAssets = 0;
      int liquidAssets = 0;
      int totalLiabilities = 0;

      for (final entry in balances.entries) {
        final parts = entry.key.split('_');
        final type = parts[0];
        final liquidity = parts.length > 1 ? parts[1] : '';
        final balance = entry.value;

        if (type == 'asset') {
          totalAssets += balance;
          if (liquidity == 'instant' || liquidity == 'days') {
            liquidAssets += balance;
          }
        } else if (type == 'liability') {
          totalLiabilities += balance.abs();
        }
      }

      // Include physical asset book values — skip investment assets (tracked via holdings)
      final assetsResult = await _assetsRepo.getAssets();
      final physicalAssets = assetsResult.fold((_) => 0,
          (assets) => assets
              .where((a) => a.holdingId == null) // exclude holding-linked assets
              .fold(0, (sum, a) => sum + a.bookValue));
      totalAssets += physicalAssets;

      // Add holdings market value
      final holdingsResult = await _holdingsRepo.getHoldings();
      final holdingsValue = holdingsResult.fold((_) => 0,
          (holdings) => holdings
              .where((h) => h.isActive)
              .fold(0, (sum, h) => sum + h.marketValueMinor));
      totalAssets += holdingsValue;

      return Right(NetWorth(
        totalMinor: totalAssets - totalLiabilities,
        liquidMinor: liquidAssets - totalLiabilities,
        currency: 'KES',
        asOf: DateTime.now(),
      ));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
