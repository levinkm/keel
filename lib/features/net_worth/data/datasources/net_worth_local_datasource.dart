import 'package:keel/core/database/app_database.dart';

class NetWorthLocalDatasource {
  final AppDatabase _db;
  NetWorthLocalDatasource(this._db);

  /// Returns sum of debit-normal balances for asset accounts minus liability balances.
  Future<Map<String, int>> getAccountBalancesByType() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT a.type, a.liquidity,
             SUM(CASE WHEN jl.side = 'debit' THEN jl.amount_minor ELSE -jl.amount_minor END) AS balance
      FROM accounts a
      LEFT JOIN journal_lines jl ON jl.account_id = a.id
      WHERE a.is_active = 1
      GROUP BY a.id, a.type, a.liquidity
    ''');
    return {for (final r in rows) '${r['type']}_${r['liquidity']}': (r['balance'] as num? ?? 0).toInt()};
  }
}
