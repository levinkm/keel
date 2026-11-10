import 'package:dartz/dartz.dart';
import 'package:keel/core/error/failures.dart';
import 'package:keel/features/ledger/data/datasources/ledger_local_datasource.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:keel/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:uuid/uuid.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  final LedgerLocalDatasource _datasource;
  LedgerRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<JournalEntry>>> getEntriesByPeriod(
      String period) async {
    try {
      final rows = await _datasource.getEntriesByPeriod(period);
      final entries = await Future.wait(rows.map((r) async {
        final lines = await _datasource.getLinesForEntry(r['id'] as String);
        final attachments =
            await _datasource.getAttachmentsForEntry(r['id'] as String);
        return r.toJournalEntry(lines, attachments);
      }));
      return Right(entries);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<JournalEntry>>> getEntriesByAccount(
      String accountId) async {
    try {
      final rows = await _datasource.getEntriesByAccount(accountId);
      final entries = await Future.wait(rows.map((r) async {
        final lines = await _datasource.getLinesForEntry(r['id'] as String);
        final attachments =
            await _datasource.getAttachmentsForEntry(r['id'] as String);
        return r.toJournalEntry(lines, attachments);
      }));
      return Right(entries);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, JournalEntry?>> getEntryById(String id) async {
    try {
      final row = await _datasource.getEntryById(id);
      if (row == null) return const Right(null);
      final lines = await _datasource.getLinesForEntry(id);
      final attachments = await _datasource.getAttachmentsForEntry(id);
      return Right(row.toJournalEntry(lines, attachments));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, JournalEntry>> postEntry(JournalEntry entry) async {
    if (!entry.isBalanced) {
      return const Left(
          ValidationFailure('Journal entry debits must equal credits'));
    }
    try {
      final id = entry.id.isEmpty ? const Uuid().v4() : entry.id;
      final now = DateTime.now();
      await _datasource.insertEntry(
        {
          'id': id,
          'date': entry.date.toIso8601String(),
          'description': entry.description,
          'reference': entry.reference,
          'payee': entry.payee,
          'notes': entry.notes,
          'location': entry.location,
          'contact_id': entry.contactId,
          'period': entry.period,
          'is_locked': 0,
          'tags': entry.tags.join(','),
          'created_at': now.toIso8601String(),
        },
        entry.lines
            .map((l) => {
                  'id': const Uuid().v4(),
                  'entry_id': id,
                  'account_id': l.accountId,
                  'amount_minor': l.amountMinor,
                  'currency': l.currency,
                  'side': l.side.name,
                  'memo': l.memo,
                })
            .toList(),
      );
      return Right(entry);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateEntryMeta(JournalEntry entry) async {
    try {
      await _datasource.updateEntryMeta({
        'id': entry.id,
        'description': entry.description,
        'date': entry.date.toIso8601String(),
        'reference': entry.reference,
        'payee': entry.payee,
        'notes': entry.notes,
        'location': entry.location,
        'contact_id': entry.contactId,
        'tags': entry.tags.join(','),
      });
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addTransactionCost({
    required String entryId,
    required String feeAccountId,
    required String paidFromAccountId,
    required int amountMinor,
    required String currency,
    required String memo,
  }) async {
    try {
      await _datasource.addLine({
        'id': const Uuid().v4(),
        'entry_id': entryId,
        'account_id': feeAccountId,
        'amount_minor': amountMinor,
        'currency': currency,
        'side': 'debit',
        'memo': memo,
      });
      await _datasource.addLine({
        'id': const Uuid().v4(),
        'entry_id': entryId,
        'account_id': paidFromAccountId,
        'amount_minor': amountMinor,
        'currency': currency,
        'side': 'credit',
        'memo': memo,
      });
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EntryAttachment>> addAttachment({
    required String entryId,
    required String filePath,
    required String fileName,
    String? mimeType,
  }) async {
    try {
      final attachment = EntryAttachment(
        id: const Uuid().v4(),
        entryId: entryId,
        filePath: filePath,
        fileName: fileName,
        mimeType: mimeType,
        createdAt: DateTime.now(),
      );
      await _datasource.insertAttachment({
        'id': attachment.id,
        'entry_id': entryId,
        'file_path': filePath,
        'file_name': fileName,
        'mime_type': mimeType,
        'created_at': attachment.createdAt.toIso8601String(),
      });
      return Right(attachment);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeAttachment(String attachmentId) async {
    try {
      await _datasource.deleteAttachment(attachmentId);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, JournalEntry>> reverseEntry(
      String entryId, String reason) async {
    try {
      final lines = await _datasource.getLinesForEntry(entryId);
      final reversalId = const Uuid().v4();
      final now = DateTime.now();
      final period =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      await _datasource.insertEntry(
        {
          'id': reversalId,
          'date': now.toIso8601String(),
          'description': 'Reversal: $reason',
          'reference': entryId,
          'period': period,
          'is_locked': 0,
          'tags': '',
          'created_at': now.toIso8601String(),
        },
        lines
            .map((l) => {
                  'id': const Uuid().v4(),
                  'entry_id': reversalId,
                  'account_id': l['account_id'],
                  'amount_minor': l['amount_minor'],
                  'currency': l['currency'],
                  'side': l['side'] == 'debit' ? 'credit' : 'debit',
                })
            .toList(),
      );
      final reversalLines =
          await _datasource.getLinesForEntry(reversalId);
      final entryRow = {
        'id': reversalId,
        'date': now.toIso8601String(),
        'description': 'Reversal: $reason',
        'reference': entryId,
        'period': period,
        'is_locked': 0,
        'tags': '',
        'created_at': now.toIso8601String(),
      };
      return Right(entryRow.toJournalEntry(reversalLines));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getAccountBalances() async {
    try {
      return Right(await _datasource.getAccountBalances());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
