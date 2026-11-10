import 'package:keel/core/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class StrategyLocalDatasource {
  final AppDatabase _db;
  StrategyLocalDatasource(this._db);

  Future<String?> getActiveStrategyId() async {
    final db = await _db.database;
    final rows = await db.query('settings',
        where: 'key = ?', whereArgs: ['activeStrategyId']);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setActiveStrategyId(String id) async {
    final db = await _db.database;
    await db.insert('settings', {'key': 'activeStrategyId', 'value': id},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getBucketsForStrategy(
      String strategyId) async {
    final db = await _db.database;
    // Buckets stored in strategies table as JSON definition
    final rows = await db.query('strategies',
        where: 'id = ?', whereArgs: [strategyId]);
    if (rows.isEmpty) return [];
    // Parse bucket rows from a separate query using strategy_id prefix convention
    // We store buckets as individual rows with id = strategyId_bucketName
    return db.query('strategies',
        where: "id LIKE ?", whereArgs: ['${strategyId}_%']);
  }

  Future<List<Map<String, dynamic>>> getBucketRows(String strategyId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT * FROM strategy_buckets WHERE strategy_id = ?
    ''', [strategyId]);
    return rows;
  }

  Future<void> upsertBucket(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.insert('strategy_buckets', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteBucketsForStrategy(String strategyId) async {
    final db = await _db.database;
    await db.delete('strategy_buckets',
        where: 'strategy_id = ?', whereArgs: [strategyId]);
  }
}
