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

  Map<String, dynamic> _streamToRow(IncomeStream stream) => {
        'id': stream.id,
        'name': stream.name,
        'type': stream.type.name,
        'account_id': stream.accountId,
        'frequency': _legacyFreq(stream.frequency), // keep old column for compat
        'frequency_unit': stream.frequency.unit.name,
        'frequency_interval': stream.frequency.interval,
        'payment_mode': stream.paymentMode.name,
        'amount_minor': stream.amountMinor,
        'reliable_amount_minor': stream.reliableAmountMinor,
        'currency': stream.currency,
        'is_active': stream.isActive ? 1 : 0,
        'start_date': stream.startDate?.toIso8601String(),
        'end_date': stream.endDate?.toIso8601String(),
        'created_at': stream.createdAt.toIso8601String(),
      };

  /// Write a best-effort legacy value so old code reading the column doesn't crash.
  String _legacyFreq(IncomeFrequency f) {
    if (f.isIrregular) return 'irregular';
    if (f.unit == FrequencyUnit.week && f.interval == 1) return 'weekly';
    return 'monthly';
  }

  @override
  Future<Either<Failure, IncomeStream>> updateStream(IncomeStream stream) async {
    try {
      await _datasource.updateStream(_streamToRow(stream));
      return Right(stream);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, IncomeStream>> createStream(IncomeStream stream) async {
    try {
      final row = _streamToRow(stream)..["is_active"] = 1
        ..['created_at'] = DateTime.now().toIso8601String();
      await _datasource.insertStream(row);
      return Right(stream);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  IncomeStream _rowToStream(Map<String, dynamic> r) {
    // Prefer new columns; fall back to legacy frequency column for old rows.
    final IncomeFrequency frequency;
    final unitStr = r['frequency_unit'] as String?;
    final intervalRaw = r['frequency_interval'];
    if (unitStr != null && intervalRaw != null) {
      frequency = IncomeFrequency(
        unit: FrequencyUnit.values.byName(unitStr),
        interval: intervalRaw as int,
      );
    } else {
      // Migrate legacy value
      frequency = switch (r['frequency'] as String) {
        'weekly'    => const IncomeFrequency.weekly(),
        'irregular' => const IncomeFrequency.irregular(),
        _           => const IncomeFrequency.monthly(),
      };
    }

    return IncomeStream(
      id: r['id'] as String,
      name: r['name'] as String,
      type: IncomeType.values.byName(r['type'] as String),
      accountId: r['account_id'] as String,
      frequency: frequency,
      paymentMode: r['payment_mode'] != null
          ? PaymentMode.values.byName(r['payment_mode'] as String)
          : PaymentMode.regular,
      amountMinor: r['amount_minor'] as int,
      reliableAmountMinor: r['reliable_amount_minor'] as int?,
      currency: r['currency'] as String,
      isActive: (r['is_active'] as int) == 1,
      startDate: r['start_date'] != null ? DateTime.parse(r['start_date'] as String) : null,
      endDate: r['end_date'] != null ? DateTime.parse(r['end_date'] as String) : null,
      createdAt: DateTime.parse(r['created_at'] as String),
    );
  }
}