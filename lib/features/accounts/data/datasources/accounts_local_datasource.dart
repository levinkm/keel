import 'package:keel/core/database/app_database.dart';
import 'package:keel/features/accounts/domain/entities/account.dart';

class AccountsLocalDatasource {
  final AppDatabase _db;
  AccountsLocalDatasource(this._db);

  Future<List<Map<String, dynamic>>> getAccounts() async {
    final db = await _db.database;
    return db.query('accounts', where: 'is_active = ?', whereArgs: [1]);
  }

  Future<Map<String, dynamic>?> getAccountById(String id) async {
    final db = await _db.database;
    final rows = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> insertAccount(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.insert('accounts', data);
  }

  Future<void> updateAccount(Map<String, dynamic> data) async {
    final db = await _db.database;
    await db.update('accounts', data, where: 'id = ?', whereArgs: [data['id']]);
  }
}

extension AccountMapper on Map<String, dynamic> {
  Account toAccount() => Account(
        id: this['id'] as String,
        name: this['name'] as String,
        type: AccountType.values.byName(this['type'] as String),
        currency: this['currency'] as String,
        liquidity: Liquidity.values.byName(this['liquidity'] as String),
        isActive: (this['is_active'] as int) == 1,
        createdAt: DateTime.parse(this['created_at'] as String),
      );
}
