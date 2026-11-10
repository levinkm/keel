import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import '../entities/journal_entry.dart';

abstract class LedgerRepository {
  Future<Either<Failure, List<JournalEntry>>> getEntriesByPeriod(String period);
  Future<Either<Failure, List<JournalEntry>>> getEntriesByAccount(String accountId);
  Future<Either<Failure, JournalEntry?>> getEntryById(String id);
  Future<Either<Failure, JournalEntry>> postEntry(JournalEntry entry);
  Future<Either<Failure, void>> updateEntryMeta(JournalEntry entry);
  Future<Either<Failure, void>> addTransactionCost({
    required String entryId,
    required String feeAccountId,
    required String paidFromAccountId,
    required int amountMinor,
    required String currency,
    required String memo,
  });
  Future<Either<Failure, EntryAttachment>> addAttachment({
    required String entryId,
    required String filePath,
    required String fileName,
    String? mimeType,
  });
  Future<Either<Failure, void>> removeAttachment(String attachmentId);
  Future<Either<Failure, JournalEntry>> reverseEntry(String entryId, String reason);
  Future<Either<Failure, Map<String, int>>> getAccountBalances();
}
