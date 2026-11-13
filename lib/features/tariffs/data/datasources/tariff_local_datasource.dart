import 'package:keel/core/database/app_database.dart';

class TariffLocalDatasource {
  final AppDatabase _db;
  TariffLocalDatasource(this._db);

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _db.database;
    return db.query('tariffs', orderBy: 'provider ASC');
  }

  Future<List<Map<String, dynamic>>> getForAccount(String accountId) async {
    final db = await _db.database;
    return db.query('tariffs',
        where: 'account_id = ?', whereArgs: [accountId]);
  }

  Future<void> insert(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.insert('tariffs', data);
  }

  Future<void> update(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.update('tariffs', data,
        where: 'id = ?', whereArgs: [data['id']]);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('tariffs', where: 'id = ?', whereArgs: [id]);
  }
}
