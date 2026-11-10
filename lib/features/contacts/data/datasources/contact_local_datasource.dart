import 'package:keel/core/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class ContactLocalDatasource {
  final AppDatabase _db;
  ContactLocalDatasource(this._db);

  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await _db.database;
    return db.query('contacts', orderBy: 'name ASC');
  }

  Future<void> insertContact(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.insert('contacts', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateContact(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.update('contacts', data,
        where: 'id = ?', whereArgs: [data['id']]);
  }

  Future<void> deleteContact(String id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // Untag all entries for this contact
      await txn.update('journal_entries', {'contact_id': null},
          where: 'contact_id = ?', whereArgs: [id]);
      await txn.delete('contacts', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> tagEntry(String contactId, String journalEntryId) async {
    final db = await _db.database;
    await db.update(
      'journal_entries',
      {'contact_id': contactId},
      where: 'id = ?',
      whereArgs: [journalEntryId],
    );
  }

  Future<void> untagEntry(String journalEntryId) async {
    final db = await _db.database;
    await db.update(
      'journal_entries',
      {'contact_id': null},
      where: 'id = ?',
      whereArgs: [journalEntryId],
    );
  }

  Future<String?> getContactIdForEntry(String journalEntryId) async {
    final db = await _db.database;
    final rows = await db.query('journal_entries',
        columns: ['contact_id'],
        where: 'id = ?',
        whereArgs: [journalEntryId]);
    if (rows.isEmpty) return null;
    return rows.first['contact_id'] as String?;
  }

  Future<List<String>> getEntryIdsForContact(String contactId) async {
    final db = await _db.database;
    final rows = await db.query('journal_entries',
        columns: ['id'],
        where: 'contact_id = ?',
        whereArgs: [contactId]);
    return rows.map((r) => r['id'] as String).toList();
  }
}
