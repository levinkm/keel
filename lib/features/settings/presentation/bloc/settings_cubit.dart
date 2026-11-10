import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:keel/core/database/app_database.dart';
import 'package:keel/features/settings/domain/repositories/settings_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

part 'settings_state.dart';
part 'settings_cubit.freezed.dart';

/// Global notifier so theme changes apply instantly without restart.
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

class DbStats {
  final int accounts;
  final int transactions;
  final int loans;
  final int assets;
  final int holdings;
  final int contacts;
  final int projects;
  final int incomeStreams;
  final int dbSizeBytes;
  const DbStats({
    required this.accounts, required this.transactions,
    required this.loans, required this.assets,
    required this.holdings, required this.contacts,
    required this.projects, required this.incomeStreams,
    required this.dbSizeBytes,
  });
}

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repo;
  final AppDatabase _db;
  SettingsCubit(this._repo, this._db) : super(const SettingsState.initial());

  Future<void> load() async {
    emit(const SettingsState.loading());
    final result = await _repo.getAll();
    await result.fold(
      (f) async => emit(SettingsState.error(f.message)),
      (settings) async {
        _applyTheme(settings['themeMode']);
        final stats = await _loadStats();
        emit(SettingsState.loaded(settings, stats));
      },
    );
  }

  Future<void> set(String key, String value) async {
    await _repo.set(key, value);
    final current = state;
    if (current is! _Loaded) return;
    final updated = Map<String, String>.from(current.settings)..[key] = value;
    emit(SettingsState.loaded(updated, current.stats));
  }

  Future<void> setTheme(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await set('themeMode', value);
    _applyTheme(value);
  }

  Future<void> resetSettings() async {
    await _repo.set('displayName', '');
    await _repo.set('currency', 'KES');
    await _repo.set('themeMode', 'system');
    await _repo.set('fiscalYearStart', '1');
    await _repo.set('dateFormat', 'dd MMM yyyy');
    await load();
  }

  Future<String?> exportDatabase() async {
    try {
      final dbPath = p.join(await getDatabasesPath(), 'keel.db');
      final result = await Process.run('osascript', [
        '-e',
        'POSIX path of (choose folder with prompt "Choose export location")'
      ]);
      if (result.exitCode != 0) return null;
      final folder = (result.stdout as String).trim();
      if (folder.isEmpty) return null;
      final dest = p.join(folder, 'keel_backup_${_dateStamp()}.db');
      await File(dbPath).copy(dest);
      return dest;
    } catch (_) {
      return null;
    }
  }

  Future<DbStats> _loadStats() async {
    final db = await _db.database;
    int count(List<Map> rows) => (rows.first['c'] as int? ?? 0);
    final accounts = count(await db.rawQuery('SELECT COUNT(*) as c FROM accounts'));
    final transactions = count(await db.rawQuery('SELECT COUNT(*) as c FROM journal_entries'));
    final loans = count(await db.rawQuery('SELECT COUNT(*) as c FROM loans'));
    final assets = count(await db.rawQuery('SELECT COUNT(*) as c FROM assets'));
    final holdings = count(await db.rawQuery('SELECT COUNT(*) as c FROM holdings'));
    final contacts = count(await db.rawQuery('SELECT COUNT(*) as c FROM contacts'));
    final projects = count(await db.rawQuery('SELECT COUNT(*) as c FROM projects'));
    final incomeStreams = count(await db.rawQuery('SELECT COUNT(*) as c FROM income_streams'));
    int dbSize = 0;
    try {
      final dbPath = p.join(await getDatabasesPath(), 'keel.db');
      dbSize = await File(dbPath).length();
    } catch (_) {}
    return DbStats(
      accounts: accounts, transactions: transactions,
      loans: loans, assets: assets, holdings: holdings,
      contacts: contacts, projects: projects,
      incomeStreams: incomeStreams, dbSizeBytes: dbSize,
    );
  }

  void _applyTheme(String? value) {
    themeModeNotifier.value = switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  String _dateStamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}';
  }
}
