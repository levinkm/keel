import 'package:keel/core/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class ProjectLocalDatasource {
  final AppDatabase _db;
  ProjectLocalDatasource(this._db);

  Future<List<Map<String, dynamic>>> getProjects() async {
    final db = await _db.database;
    return db.query('projects', orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getProjectById(String id) async {
    final db = await _db.database;
    final rows = await db.query('projects', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> insertProject(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.insert('projects', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProject(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.update('projects', data, where: 'id = ?', whereArgs: [data['id']]);
  }

  Future<void> deleteProject(String id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('project_entries', where: 'project_id = ?', whereArgs: [id]);
      await txn.delete('projects', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> tagEntry(String projectId, String journalEntryId) async {
    final db = await _db.database;
    await db.insert(
      'project_entries',
      {'project_id': projectId, 'journal_entry_id': journalEntryId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> untagEntry(String projectId, String journalEntryId) async {
    final db = await _db.database;
    await db.delete(
      'project_entries',
      where: 'project_id = ? AND journal_entry_id = ?',
      whereArgs: [projectId, journalEntryId],
    );
  }

  Future<List<String>> getEntryIdsForProject(String projectId) async {
    final db = await _db.database;
    final rows = await db.query(
      'project_entries',
      columns: ['journal_entry_id'],
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
    return rows.map((r) => r['journal_entry_id'] as String).toList();
  }

  Future<List<String>> getProjectIdsForEntry(String journalEntryId) async {
    final db = await _db.database;
    final rows = await db.query(
      'project_entries',
      columns: ['project_id'],
      where: 'journal_entry_id = ?',
      whereArgs: [journalEntryId],
    );
    return rows.map((r) => r['project_id'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getProjectsForAsset(String assetId) async {
    final db = await _db.database;
    return db.query('projects', where: 'asset_id = ?', whereArgs: [assetId], orderBy: 'created_at DESC');
  }
}
