import 'package:keel/core/database/app_database.dart';

class IncomeLocalDatasource {
  final AppDatabase _db;
  IncomeLocalDatasource(this._db);

  Future<List<Map<String, dynamic>>> getStreams() async {
    final db = await _db.database;
    return db.query('income_streams', where: 'is_active = ?', whereArgs: [1]);
  }

  Future<void> insertStream(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.insert('income_streams', data);
  }

  Future<void> updateStream(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.update('income_streams', data, where: 'id = ?', whereArgs: [data['id']]);
  }

  Future<List<Map<String, dynamic>>> getAllStreams() async {
    final db = await _db.database;
    return db.query('income_streams', orderBy: 'created_at DESC');
  }
}
