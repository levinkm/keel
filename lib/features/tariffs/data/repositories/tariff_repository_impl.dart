import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/features/tariffs/data/datasources/tariff_local_datasource.dart';
import 'package:keel/features/tariffs/domain/entities/tariff.dart';
import 'package:keel/features/tariffs/domain/repositories/tariff_repository.dart';

class TariffRepositoryImpl implements TariffRepository {
  final TariffLocalDatasource _ds;
  TariffRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, List<Tariff>>> getTariffs() async {
    try {
      final rows = await _ds.getAll();
      return Right(rows.map(_rowToTariff).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Tariff>>> getTariffsForAccount(String accountId) async {
    try {
      final rows = await _ds.getForAccount(accountId);
      return Right(rows.map(_rowToTariff).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Tariff>> createTariff(Tariff tariff) async {
    try {
      await _ds.insert(_tariffToRow(tariff));
      return Right(tariff);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Tariff>> updateTariff(Tariff tariff) async {
    try {
      await _ds.update(_tariffToRow(tariff));
      return Right(tariff);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTariff(String id) async {
    try {
      await _ds.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  Map<String, dynamic> _tariffToRow(Tariff t) => {
        'id': t.id,
        'provider': t.provider,
        'account_id': t.accountId,
        'channel': t.operation.name, // reuse 'channel' column for accountId context
        'operation': t.operation.name,
        'tiers': Tariff.tiersToJson(t.tiers),
        'tax_rate_bp': t.taxRateBp,
        'fee_account_id': t.feeAccountId,
        'effective_from': t.effectiveFrom.toIso8601String(),
        'effective_to': t.effectiveTo?.toIso8601String(),
      };

  Tariff _rowToTariff(Map<String, dynamic> r) => Tariff(
        id: r['id'] as String,
        provider: r['provider'] as String,
        accountId: r['account_id'] as String? ?? '',
        operation: TariffOperation.values.byName(r['operation'] as String),
        tiers: Tariff.tiersFromJson(r['tiers'] as String),
        taxRateBp: r['tax_rate_bp'] as int? ?? 0,
        feeAccountId: r['fee_account_id'] as String?,
        effectiveFrom: DateTime.parse(r['effective_from'] as String),
        effectiveTo: r['effective_to'] != null
            ? DateTime.parse(r['effective_to'] as String)
            : null,
      );
}
