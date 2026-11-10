import 'package:keel/core/database/app_database.dart';

class AssetsLocalDatasource {
  final AppDatabase _db;
  AssetsLocalDatasource(this._db);

  Future<List<Map<String, dynamic>>> getAssets() async {
    final db = await _db.database;
    return db.query('assets', where: "status != 'writtenOff'", orderBy: 'created_at DESC');
  }

  Future<void> insertAsset(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.insert('assets', data);
  }

  Future<void> updateAsset(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.update('assets', data, where: 'id = ?', whereArgs: [data['id']]);
  }

  Future<void> insertAttachment(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.insert('asset_attachments', data);
  }

  Future<List<Map<String, dynamic>>> getAttachmentsForAsset(String assetId) async {
    final db = await _db.database;
    return db.query('asset_attachments',
        where: 'asset_id = ?', whereArgs: [assetId], orderBy: 'created_at ASC');
  }

  Future<void> deleteAttachment(String id) async {
    final db = await _db.database;
    await db.delete('asset_attachments', where: 'id = ?', whereArgs: [id]);
  }
}
