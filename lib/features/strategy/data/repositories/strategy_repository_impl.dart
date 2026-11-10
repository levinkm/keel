import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/features/strategy/data/datasources/strategy_local_datasource.dart';
import 'package:keel/features/strategy/domain/entities/strategy.dart';
import 'package:keel/features/strategy/domain/repositories/strategy_repository.dart';

class StrategyRepositoryImpl implements StrategyRepository {
  final StrategyLocalDatasource _datasource;
  StrategyRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, String?>> getActiveStrategyId() async {
    try {
      return Right(await _datasource.getActiveStrategyId());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setActiveStrategyId(String id) async {
    try {
      await _datasource.setActiveStrategyId(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StrategyBucket>>> getBucketsForStrategy(
      String strategyId) async {
    try {
      final rows = await _datasource.getBucketRows(strategyId);
      return Right(rows.map(_rowToBucket).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveBuckets(
      List<StrategyBucket> buckets) async {
    try {
      for (final bucket in buckets) {
        await _datasource.upsertBucket({
          'id': bucket.id,
          'strategy_id': bucket.strategyId,
          'name': bucket.name,
          'target_pct': bucket.targetPct,
          'account_ids': bucket.accountIds.join(','),
          'account_weights': bucket.accountIds
              .map((id) => '${bucket.accountWeights[id] ?? 0}')
              .join(','),
        });
      }
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBucketsForStrategy(
      String strategyId) async {
    try {
      await _datasource.deleteBucketsForStrategy(strategyId);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  StrategyBucket _rowToBucket(Map<String, dynamic> r) {
    final ids = (r['account_ids'] as String)
        .split(',')
        .where((s) => s.isNotEmpty)
        .toList();
    final weightStrs = (r['account_weights'] as String? ?? '')
        .split(',')
        .where((s) => s.isNotEmpty)
        .toList();
    final weights = <String, int>{};
    for (int i = 0; i < ids.length; i++) {
      weights[ids[i]] = i < weightStrs.length
          ? (int.tryParse(weightStrs[i]) ?? 0)
          : 0;
    }
    return StrategyBucket(
      id: r['id'] as String,
      strategyId: r['strategy_id'] as String,
      name: r['name'] as String,
      targetPct: r['target_pct'] as int,
      accountIds: ids,
      accountWeights: weights,
    );
  }
}
