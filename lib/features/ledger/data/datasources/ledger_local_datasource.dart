import 'package:keel/core/database/app_database.dart';
import 'package:keel/features/ledger/domain/entities/journal_entry.dart';
import 'package:sqflite/sqflite.dart';

class LedgerLocalDatasource {
  final AppDatabase _db;
  LedgerLocalDatasource(this._db);

  Future<List<Map<String, dynamic>>> getEntriesByPeriod(String period) async {
    final db = await _db.database;
    return db.query('journal_entries', where: 'period = ?', whereArgs: [period], orderBy: 'date DESC');
  }

  Future<Map<String, dynamic>?> getEntryById(String id) async {
    final db = await _db.database;
    final rows = await db.query('journal_entries', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getLinesForEntry(String entryId) async {
    final db = await _db.database;
    return db.query('journal_lines', where: 'entry_id = ?', whereArgs: [entryId]);
  }

  Future<List<Map<String, dynamic>>> getEntriesByAccount(String accountId) async {
    final db = await _db.database;
    final lines = await db.query('journal_lines', where: 'account_id = ?', whereArgs: [accountId]);
    final entryIds = lines.map((l) => "'${l['entry_id']}'").toSet().join(',');
    if (entryIds.isEmpty) return [];
    return db.rawQuery('SELECT * FROM journal_entries WHERE id IN ($entryIds) ORDER BY date DESC');
  }

  Future<void> insertEntry(Map<String, dynamic> entry, List<Map<String, dynamic>> lines) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert('journal_entries', entry);
      for (final line in lines) {
        await txn.insert('journal_lines', line);
      }
    });
  }
  Future<void> updateEntryMeta(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.update('journal_entries', data,
        where: 'id = ?', whereArgs: [data['id']]);
  }

  Future<void> addLine(Map<String, dynamic> line) async {
    final db = await _db.database;
    await db.insert('journal_lines', line,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteLine(String lineId) async {
    final db = await _db.database;
    await db.delete('journal_lines', where: 'id = ?', whereArgs: [lineId]);
  }

  Future<void> insertAttachment(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.insert('entry_attachments', data);
  }

  Future<List<Map<String, dynamic>>> getAttachmentsForEntry(String entryId) async {
    final db = await _db.database;
    return db.query('entry_attachments',
        where: 'entry_id = ?', whereArgs: [entryId], orderBy: 'created_at ASC');
  }

  Future<void> deleteAttachment(String id) async {
    final db = await _db.database;
    await db.delete('entry_attachments', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getAccountBalances() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT account_id,
             SUM(CASE WHEN side = 'debit' THEN amount_minor ELSE -amount_minor END) AS balance
      FROM journal_lines
      GROUP BY account_id
    ''');
    return {for (final r in rows) r['account_id'] as String: (r['balance'] as num).toInt()};
  }
}

extension JournalEntryMapper on Map<String, dynamic> {
  JournalEntry toJournalEntry(List<Map<String, dynamic>> lineRows,
      [List<Map<String, dynamic>> attachmentRows = const []]) =>
      JournalEntry(
        id: this['id'] as String,
        date: DateTime.parse(this['date'] as String),
        description: this['description'] as String,
        reference: this['reference'] as String?,
        payee: this['payee'] as String?,
        notes: this['notes'] as String?,
        location: this['location'] as String?,
        contactId: this['contact_id'] as String?,
        period: this['period'] as String,
        isLocked: (this['is_locked'] as int) == 1,
        lines: lineRows.map((l) => l.toJournalLine()).toList(),
        attachments: attachmentRows.map((a) => a.toAttachment()).toList(),
        createdAt: DateTime.parse(this['created_at'] as String),
        tags: (this['tags'] as String? ?? '')
            .split(',')
            .where((t) => t.isNotEmpty)
            .toList(),
      );
}

extension JournalLineMapper on Map<String, dynamic> {
  JournalLine toJournalLine() => JournalLine(
        id: this['id'] as String,
        entryId: this['entry_id'] as String,
        accountId: this['account_id'] as String,
        amountMinor: this['amount_minor'] as int,
        currency: this['currency'] as String,
        side: JournalSide.values.byName(this['side'] as String),
        memo: this['memo'] as String?,
      );
}

extension AttachmentMapper on Map<String, dynamic> {
  EntryAttachment toAttachment() => EntryAttachment(
        id: this['id'] as String,
        entryId: this['entry_id'] as String,
        filePath: this['file_path'] as String,
        fileName: this['file_name'] as String,
        mimeType: this['mime_type'] as String?,
        createdAt: DateTime.parse(this['created_at'] as String),
      );
}
