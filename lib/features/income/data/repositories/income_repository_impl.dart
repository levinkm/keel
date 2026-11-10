import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/features/income/data/datasources/income_local_datasource.dart';
import 'package:keel/features/income/domain/entities/income_stream.dart';
import 'package:keel/features/income/domain/repositories/income_repository.dart';

class IncomeRepositoryImpl implements IncomeRepository {
  final IncomeLocalDatasource _datasource;
  IncomeRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<IncomeStream>>> getStreams() async {
    try {
      final rows = await _datasource.getStreams();
      return Right(rows.map(_rowToStream).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<IncomeStream>>> getAllStreams() async {
    try {
      final rows = await _datasource.getAllStreams();
      return Right(rows.map(_rowToStream).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, IncomeStream>> updateStream(IncomeStream stream) async {
    try {
      await _datasource.updateStream({
        'id': stream.id,
        'name': stream.name,
        'type': stream.type.name,
        'account_id': stream.accountId,
        'frequency': stream.frequency.name,
        'amount_minor': stream.amountMinor,
        'reliable_amount_minor': stream.reliableAmountMinor,
        'currency': stream.currency,
        'is_active': stream.isActive ? 1 : 0,
        'start_date': stream.startDate?.toIso8601String(),
        'end_date': stream.endDate?.toIso8601String(),
        'created_at': stream.createdAt.toIso8601String(),
      });
      return Right(stream);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, IncomeStream>> createStream(IncomeStream stream) async {
    try {
      await _datasource.insertStream({
        'id': stream.id,
        'name': stream.name,
        'type': stream.type.name,
        'account_id': stream.accountId,
        'frequency': stream.frequency.name,
        'amount_minor': stream.amountMinor,
        'reliable_amount_minor': stream.reliableAmountMinor,
        'currency': stream.currency,
        'is_active': 1,
        'start_date': stream.startDate?.toIso8601String(),
        'end_date': stream.endDate?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
      return Right(stream);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  IncomeStream _rowToStream(Map<String, dynamic> r) => IncomeStream(
        id: r['id'] as String,
        name: r['name'] as String,
        type: IncomeType.values.byName(r['type'] as String),
        accountId: r['account_id'] as String,
        frequency: IncomeFrequency.values.byName(r['frequency'] as String),
        amountMinor: r['amount_minor'] as int,
        reliableAmountMinor: r['reliable_amount_minor'] as int?,
        currency: r['currency'] as String,
        isActive: (r['is_active'] as int) == 1,
        startDate: r['start_date'] != null ? DateTime.parse(r['start_date'] as String) : null,
        endDate: r['end_date'] != null ? DateTime.parse(r['end_date'] as String) : null,
        createdAt: DateTime.parse(r['created_at'] as String),
      );
}
