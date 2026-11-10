import 'package:keel/core/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class LoansLocalDatasource {
  final AppDatabase _db;
  LoansLocalDatasource(this._db);

  Future<List<Map<String, dynamic>>> getLoans() async {
    final db = await _db.database;
    return db.query('loans', orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getLoanById(String id) async {
    final db = await _db.database;
    final rows = await db.query('loans', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getEventsForLoan(String loanId) async {
    final db = await _db.database;
    return db.query('loan_events',
        where: 'loan_id = ?', whereArgs: [loanId], orderBy: 'date ASC');
  }

  Future<void> insertLoan(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.insert('loans', data);
  }

  Future<void> updateLoan(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.update('loans', data, where: 'id = ?', whereArgs: [data['id']]);
  }

  Future<void> insertEvent(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.insert('loan_events', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
