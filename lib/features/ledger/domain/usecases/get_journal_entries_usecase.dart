import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/core/usecases/usecase.dart';
import '../entities/journal_entry.dart';
import '../repositories/ledger_repository.dart';

class GetJournalEntriesUsecase implements Usecase<List<JournalEntry>, String> {
  final LedgerRepository _repository;
  GetJournalEntriesUsecase(this._repository);

  @override
  Future<Either<Failure, List<JournalEntry>>> call([String? period]) {
    Usecase.assertParamsRequired(period);
    return _repository.getEntriesByPeriod(period!);
  }
}
