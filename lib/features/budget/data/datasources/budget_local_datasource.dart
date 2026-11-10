import 'package:keel/core/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class BudgetLocalDatasource {
  final AppDatabase _db;
  BudgetLocalDatasource(this._db);

  Future<Map<String, dynamic>?> getPlanByPeriod(String period) async {
    final db = await _db.database;
    final rows = await db.query('budget_plans', where: 'period = ?', whereArgs: [period]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getLinesForPlan(String planId) async {
    final db = await _db.database;
    return db.query('budget_lines', where: 'plan_id = ?', whereArgs: [planId]);
  }

  Future<List<Map<String, dynamic>>> getAllPeriods() async {
    final db = await _db.database;
    return db.query('budget_plans', orderBy: 'period DESC');
  }

  Future<void> insertPlan(Map<String, dynamic> plan, List<Map<String, dynamic>> lines) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert('budget_plans', plan);
      for (final line in lines) {
        await txn.insert('budget_lines', line);
      }
    });
  }

  Future<void> upsertLine(Map<String, dynamic> line) async {
    final db = await _db.database;
    await db.insert('budget_lines', line,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateLineRollover(String lineId, int rolloverMinor) async {
    final db = await _db.database;
    await db.update('budget_lines', {'rollover_minor': rolloverMinor},
        where: 'id = ?', whereArgs: [lineId]);
  }

  Future<List<Map<String, dynamic>>> getTemplates() async {
    final db = await _db.database;
    return db.query('budget_plans',
        where: 'is_template = ?', whereArgs: [1], orderBy: 'created_at DESC');
  }

  Future<void> deleteLine(String lineId) async {
    final db = await _db.database;
    await db.delete('budget_lines', where: 'id = ?', whereArgs: [lineId]);
  }
}
