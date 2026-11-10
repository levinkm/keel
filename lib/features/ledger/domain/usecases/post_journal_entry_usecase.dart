import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/core/usecases/usecase.dart';
import '../entities/journal_entry.dart';
import '../repositories/ledger_repository.dart';

class PostJournalEntryUsecase implements Usecase<JournalEntry, JournalEntry> {
  final LedgerRepository _repository;
  PostJournalEntryUsecase(this._repository);

  @override
  Future<Either<Failure, JournalEntry>> call([JournalEntry? entry]) {
    Usecase.assertParamsRequired(entry);
    return _repository.postEntry(entry!);
  }
}
