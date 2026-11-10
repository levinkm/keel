import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import '../entities/net_worth.dart';

abstract class NetWorthRepository {
  Future<Either<Failure, NetWorth>> getNetWorth();
}
