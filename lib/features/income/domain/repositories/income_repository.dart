import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import '../entities/income_stream.dart';

abstract class IncomeRepository {
  Future<Either<Failure, List<IncomeStream>>> getStreams();
  Future<Either<Failure, List<IncomeStream>>> getAllStreams();
  Future<Either<Failure, IncomeStream>> createStream(IncomeStream stream);
  Future<Either<Failure, IncomeStream>> updateStream(IncomeStream stream);
}
