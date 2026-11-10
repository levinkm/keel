import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'package:keel/core/database/app_database.dart';

class SettingsLocalDatasource {
  final AppDatabase _db;
  SettingsLocalDatasource(this._db);

  Future<Map<String, String>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('settings');
    return {for (final r in rows) r['key'] as String: r['value'] as String};
  }

  Future<void> set(String key, String value) async {
    final db = await _db.database;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
