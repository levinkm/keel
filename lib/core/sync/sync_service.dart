import 'package:flutter/foundation.dart';
import 'package:keel/core/database/app_database.dart';
import 'package:keel/core/sync/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncService {
  SyncService._();
  static final instance = SyncService._();

  static const _keyEnabled = 'cloudSyncEnabled';
  static const _keyLastSync = 'cloudLastSync';
  static const _keyDeviceId = 'cloudDeviceId';

  final syncStatus = ValueNotifier<SyncStatus>(SyncStatus.idle);
  final lastSyncAt = ValueNotifier<DateTime?>(null);
  final isEnabled = ValueNotifier<bool>(false);

  // Tables to sync in dependency order (parents before children)
  static const _tables = [
    'accounts',
    'strategies',
    'strategy_buckets',
    'journal_entries',
    'journal_lines',
    'entry_attachments',
    'budget_plans',
    'budget_lines',
    'loans',
    'loan_events',
    'income_streams',
    'assets',
    'asset_attachments',
    'holdings',
    'holding_lots',
    'contacts',
    'projects',
    'project_entries',
    'period_snapshots',
    'settings',
  ];

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );

    final prefs = await SharedPreferences.getInstance();
    isEnabled.value = prefs.getBool(_keyEnabled) ?? false;
    final lastStr = prefs.getString(_keyLastSync);
    if (lastStr != null) lastSyncAt.value = DateTime.tryParse(lastStr);
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    isEnabled.value = enabled;
  }

  /// Returns the device ID, creating one if needed.
  Future<String> _deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_keyDeviceId);
    if (id == null) {
      id = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString(_keyDeviceId, id);
    }
    return id;
  }

  /// Push all local data to Supabase. Upserts every row.
  Future<void> backup() async {
    if (!isEnabled.value) return;
    syncStatus.value = SyncStatus.syncing;
    try {
      final db = await AppDatabase.instance.database;
      final deviceId = await _deviceId();

      for (final table in _tables) {
        final rows = await db.query(table);
        if (rows.isEmpty) continue;

        // Tag each row with device_id for multi-device awareness
        final tagged = rows.map((r) => {
              ...r,
              'device_id': deviceId,
            }).toList();

        await _client.from('keel_$table').upsert(tagged);
      }

      final now = DateTime.now();
      lastSyncAt.value = now;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastSync, now.toIso8601String());
      syncStatus.value = SyncStatus.success;
    } catch (e) {
      syncStatus.value = SyncStatus.error;
      rethrow;
    }
  }

  /// Pull data from Supabase and write to local DB.
  /// Existing local data is replaced.
  Future<void> restore() async {
    syncStatus.value = SyncStatus.syncing;
    try {
      final db = await AppDatabase.instance.database;

      await db.transaction((txn) async {
        // Delete in reverse dependency order
        for (final table in _tables.reversed) {
          await txn.delete(table);
        }

        // Insert in forward order
        for (final table in _tables) {
          final rows = await _client
              .from('keel_$table')
              .select()
              .order('created_at', ascending: true)
              .limit(10000);

          for (final row in rows) {
            // Strip the device_id column — not in local schema
            final local = Map<String, dynamic>.from(row)
              ..remove('device_id')
              ..remove('id'); // will be re-inserted via primary key below

            // Re-add id from the row
            if (row['id'] != null) local['id'] = row['id'];

            await txn.insert(
              table,
              local,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });

      final now = DateTime.now();
      lastSyncAt.value = now;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastSync, now.toIso8601String());
      syncStatus.value = SyncStatus.success;
    } catch (e) {
      syncStatus.value = SyncStatus.error;
      rethrow;
    }
  }

  /// Check if there is any data in Supabase for this device.
  /// Used during setup to offer restore.
  Future<bool> hasRemoteData() async {
    try {
      final deviceId = await _deviceId();
      final rows = await _client
          .from('keel_accounts')
          .select('id')
          .eq('device_id', deviceId)
          .limit(1);
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
