import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import '../entities/tariff.dart';

abstract class TariffRepository {
  Future<Either<Failure, List<Tariff>>> getTariffs();
  Future<Either<Failure, List<Tariff>>> getTariffsForAccount(String accountId);
  Future<Either<Failure, Tariff>> createTariff(Tariff tariff);
  Future<Either<Failure, Tariff>> updateTariff(Tariff tariff);
  Future<Either<Failure, void>> deleteTariff(String id);
}
