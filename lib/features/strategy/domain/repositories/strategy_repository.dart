import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import '../entities/strategy.dart';

abstract class StrategyRepository {
  Future<Either<Failure, String?>> getActiveStrategyId();
  Future<Either<Failure, void>> setActiveStrategyId(String id);
  Future<Either<Failure, List<StrategyBucket>>> getBucketsForStrategy(String strategyId);
  Future<Either<Failure, void>> saveBuckets(List<StrategyBucket> buckets);
  Future<Either<Failure, void>> deleteBucketsForStrategy(String strategyId);
}
