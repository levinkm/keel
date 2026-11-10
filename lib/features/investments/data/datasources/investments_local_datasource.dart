import 'package:keel/core/database/app_database.dart';

class InvestmentsLocalDatasource {
  final AppDatabase _db;
  InvestmentsLocalDatasource(this._db);

  Future<List<Map<String, dynamic>>> getHoldings() async {
    final db = await _db.database;
    return db.query('holdings', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getLotsForHolding(String holdingId) async {
    final db = await _db.database;
    return db.query('holding_lots',
        where: 'holding_id = ?', whereArgs: [holdingId], orderBy: 'date ASC');
  }

  Future<void> insertHolding(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.insert('holdings', data);
  }

  Future<void> updateHolding(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.update('holdings', data, where: 'id = ?', whereArgs: [data['id']]);
  }

  Future<void> updateCurrentPrice(String holdingId, int priceMinor) async {
    final db = await _db.database;
    await db.update('holdings', {'current_price_minor': priceMinor},
        where: 'id = ?', whereArgs: [holdingId]);
  }

  Future<void> deactivateHolding(String holdingId) async {
    final db = await _db.database;
    await db.update('holdings', {'is_active': 0},
        where: 'id = ?', whereArgs: [holdingId]);
  }

  Future<void> insertLot(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.insert('holding_lots', data);
  }

  Future<void> deleteLot(String lotId) async {
    final db = await _db.database;
    await db.delete('holding_lots', where: 'id = ?', whereArgs: [lotId]);
  }
}
