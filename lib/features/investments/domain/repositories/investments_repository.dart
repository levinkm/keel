import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import '../entities/holding.dart';

abstract class InvestmentsRepository {
  Future<Either<Failure, List<Holding>>> getHoldings();
  Future<Either<Failure, String>> createHolding(Holding holding); // returns new id
  Future<Either<Failure, void>> updateHolding(Holding holding);
  Future<Either<Failure, void>> updateCurrentPrice(String holdingId, int priceMinor);
  Future<Either<Failure, void>> deactivateHolding(String holdingId);
  Future<Either<Failure, void>> addLot(HoldingLot lot);
  Future<Either<Failure, void>> deleteLot(String lotId);
}
