import 'package:flutter/foundation.dart';
import 'package:keel/core/database/app_database.dart';
import 'package:keel/core/sync/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SyncStatus { idle, syncing, success, error, disabled }

/// Describes the outcome of a sync operation in detail.
class SyncResult {
  final int pushed;
  final int pulled;
  final int conflicts; // rows where remote won (remote updated_at > local)
  final String? error;

  const SyncResult({
    this.pushed = 0,
    this.pulled = 0,
    this.conflicts = 0,
    this.error,
  });

  bool get hasError => error != null;
}

class SyncService {
  SyncService._();
  static final instance = SyncService._();

  static const _keyEnabled = 'cloudSyncEnabled';
  static const _keyLastSync = 'cloudLastSync';

  final syncStatus = ValueNotifier<SyncStatus>(SyncStatus.idle);
  final lastSyncAt = ValueNotifier<DateTime?>(null);
  final isEnabled = ValueNotifier<bool>(false);
  final lastResult = ValueNotifier<SyncResult?>(null);

  // Tables in dependency order — parents before children.
  // project_entries and settings handled separately (no standard id/updated_at).
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
  ];

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );

    final prefs = await SharedPreferences.getInstance();
    isEnabled.value = prefs.getBool(_keyEnabled) ?? false;
    final lastStr = prefs.getString(_keyLastSync);
    if (lastStr != null) lastSyncAt.value = DateTime.tryParse(lastStr);

    if (isEnabled.value) {
      syncStatus.value = SyncStatus.idle;
    } else {
      syncStatus.value = SyncStatus.disabled;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    isEnabled.value = enabled;
    syncStatus.value = enabled ? SyncStatus.idle : SyncStatus.disabled;

    if (enabled) {
      // Sign in anonymously so we have a user_id immediately.
      // If the user later adds email auth, the anonymous account is upgraded.
      await _ensureSignedIn();
    }
  }

  /// Ensures the user is signed in. Uses anonymous auth as the baseline.
  Future<void> _ensureSignedIn() async {
    if (_client.auth.currentUser != null) return;
    await _client.auth.signInAnonymously();
  }

  // ── Incremental sync ────────────────────────────────────────────────────────

  /// Push local changes to Supabase, pull remote changes back.
  /// Conflict resolution: last-write-wins on updated_at.
  /// Safe to call when offline — returns early with no state change.
  Future<SyncResult> sync() async {
    if (!isEnabled.value) {
      return const SyncResult(error: 'Cloud sync is not enabled.');
    }

    syncStatus.value = SyncStatus.syncing;

    try {
      await _ensureSignedIn();
      final userId = _userId;
      if (userId == null) {
        throw Exception('Could not obtain user identity from Supabase.');
      }

      final db = await AppDatabase.instance.database;
      final since = lastSyncAt.value;
      int pushed = 0;
      int pulled = 0;
      int conflicts = 0;

      for (final table in _tables) {
        final r = await _syncTable(
          db: db,
          table: table,
          userId: userId,
          since: since,
        );
        pushed += r.$1;
        pulled += r.$2;
        conflicts += r.$3;
      }

      // Sync settings separately (key-based, no id column)
      final sr = await _syncSettings(db: db, userId: userId, since: since);
      pushed += sr.$1;
      pulled += sr.$2;

      final now = DateTime.now().toUtc();
      lastSyncAt.value = now;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastSync, now.toIso8601String());

      final result = SyncResult(
          pushed: pushed, pulled: pulled, conflicts: conflicts);
      lastResult.value = result;
      syncStatus.value = SyncStatus.success;
      return result;
    } catch (e) {
      syncStatus.value = SyncStatus.error;
      final result = SyncResult(error: e.toString());
      lastResult.value = result;
      return result;
    }
  }

  /// Sync a single table bidirectionally.
  /// Returns (pushed, pulled, conflicts).
  Future<(int, int, int)> _syncTable({
    required Database db,
    required String table,
    required String userId,
    required DateTime? since,
  }) async {
    int pushed = 0;
    int pulled = 0;
    int conflicts = 0;

    // ── 1. Push local changes ──────────────────────────────────────────────
    final localRows = since == null
        ? await db.query(table)
        : await db.query(
            table,
            where: 'updated_at > ?',
            whereArgs: [since.toIso8601String()],
          );

    if (localRows.isNotEmpty) {
      final toUpsert = localRows.map((r) => {
            ...r,
            'user_id': userId,
            // Normalise booleans: SQLite stores 0/1, Postgres wants bool
            ...r.map((k, v) => MapEntry(k, v is int && (k.startsWith('is_') || k == 'is_locked' || k == 'is_template' || k == 'is_builtin' || k == 'is_salary_deducted') ? v == 1 : v)),
          }).toList();

      await _client.from('keel_$table').upsert(
            toUpsert,
            onConflict: 'id',
          );
      pushed += localRows.length;
    }

    // ── 2. Pull remote changes ─────────────────────────────────────────────
    var query = _client
        .from('keel_$table')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null);

    if (since != null) {
      query = query.gt('updated_at', since.toIso8601String());
    }

    final remoteRows = await query.limit(5000);

    for (final remote in remoteRows) {
      final id = remote['id'] as String?;
      if (id == null) continue;

      // Check if local row exists and compare updated_at
      final localMatches = await db.query(
        table,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      final local = localMatches.isEmpty ? null : localMatches.first;
      final remoteUpdated = DateTime.tryParse(
              remote['updated_at']?.toString() ?? '') ??
          DateTime(0);
      final localUpdated = local == null
          ? DateTime(0)
          : DateTime.tryParse(local['updated_at']?.toString() ?? '') ??
              DateTime(0);

      if (local == null) {
        // New row from remote — insert locally
        await db.insert(
          table,
          _toLocalRow(remote),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        pulled++;
      } else if (remoteUpdated.isAfter(localUpdated)) {
        // Remote is newer — remote wins
        await db.update(
          table,
          _toLocalRow(remote),
          where: 'id = ?',
          whereArgs: [id],
        );
        pulled++;
        conflicts++; // local had a version too — this was a real conflict
      }
      // else: local is newer or equal — local already pushed above, skip
    }

    // ── 3. Apply remote soft deletes locally ──────────────────────────────
    final deleted = await _client
        .from('keel_$table')
        .select('id')
        .eq('user_id', userId)
        .not('deleted_at', 'is', null);

    for (final row in deleted) {
      final id = row['id'] as String?;
      if (id == null) continue;
      await db.delete(table, where: 'id = ?', whereArgs: [id]);
    }

    return (pushed, pulled, conflicts);
  }

  /// Sync settings table (key-based primary key, no id column).
  Future<(int, int)> _syncSettings({
    required Database db,
    required String userId,
    required DateTime? since,
  }) async {
    int pushed = 0;
    int pulled = 0;

    // Push
    final localRows = since == null
        ? await db.query('settings')
        : await db.query(
            'settings',
            where: 'updated_at > ?',
            whereArgs: [since.toIso8601String()],
          );

    if (localRows.isNotEmpty) {
      final toUpsert = localRows
          .map((r) => {...r, 'user_id': userId})
          .toList();
      await _client.from('keel_settings').upsert(
            toUpsert,
            onConflict: 'user_id,key',
          );
      pushed += localRows.length;
    }

    // Pull
    var query = _client
        .from('keel_settings')
        .select()
        .eq('user_id', userId);
    if (since != null) {
      query = query.gt('updated_at', since.toIso8601String());
    }
    final remoteRows = await query;

    for (final remote in remoteRows) {
      final key = remote['key'] as String?;
      if (key == null) continue;
      final remoteUpdated =
          DateTime.tryParse(remote['updated_at']?.toString() ?? '') ??
              DateTime(0);
      final localMatches = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      final localUpdated = localMatches.isEmpty
          ? DateTime(0)
          : DateTime.tryParse(
                  localMatches.first['updated_at']?.toString() ?? '') ??
              DateTime(0);

      if (localMatches.isEmpty || remoteUpdated.isAfter(localUpdated)) {
        await db.insert(
          'settings',
          {'key': key, 'value': remote['value'], 'updated_at': remote['updated_at']},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        pulled++;
      }
    }

    return (pushed, pulled);
  }

  // ── Full restore (setup / first launch on new device) ──────────────────────

  /// Pull ALL remote data and replace local DB entirely.
  /// Used during setup when a backup is found.
  Future<SyncResult> restore() async {
    syncStatus.value = SyncStatus.syncing;
    try {
      await _ensureSignedIn();
      final userId = _userId;
      if (userId == null) throw Exception('Not signed in.');

      final db = await AppDatabase.instance.database;
      int pulled = 0;

      await db.transaction((txn) async {
        for (final table in _tables.reversed) {
          await txn.delete(table);
        }
        await txn.delete('settings');

        for (final table in _tables) {
          final rows = await _client
              .from('keel_$table')
              .select()
              .eq('user_id', userId)
              .isFilter('deleted_at', null)
              .limit(10000);

          for (final row in rows) {
            await txn.insert(
              table,
              _toLocalRow(row),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            pulled++;
          }
        }

        final settingsRows = await _client
            .from('keel_settings')
            .select()
            .eq('user_id', userId)
            .limit(1000);

        for (final row in settingsRows) {
          await txn.insert(
            'settings',
            {'key': row['key'], 'value': row['value'],
             'updated_at': row['updated_at']},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          pulled++;
        }
      });

      final now = DateTime.now().toUtc();
      lastSyncAt.value = now;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastSync, now.toIso8601String());

      final result = SyncResult(pulled: pulled);
      lastResult.value = result;
      syncStatus.value = SyncStatus.success;
      return result;
    } catch (e) {
      syncStatus.value = SyncStatus.error;
      final result = SyncResult(error: e.toString());
      lastResult.value = result;
      return result;
    }
  }

  // ── Mobile companion guard ──────────────────────────────────────────────────

  /// Returns true if Supabase is reachable and the user has remote data.
  /// The mobile app calls this on first launch to decide whether to show
  /// the "sync disabled" onboarding screen or proceed normally.
  Future<bool> hasRemoteData() async {
    if (!isEnabled.value) return false;
    try {
      await _ensureSignedIn();
      final userId = _userId;
      if (userId == null) return false;
      final rows = await _client
          .from('keel_accounts')
          .select('id')
          .eq('user_id', userId)
          .limit(1);
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Whether sync is available and the user is authenticated.
  /// Mobile app uses this to gate all sync-dependent features.
  bool get canSync =>
      isEnabled.value && _client.auth.currentUser != null;

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Strip Supabase-only columns and normalise types for local SQLite insert.
  Map<String, dynamic> _toLocalRow(Map<String, dynamic> remote) {
    final local = Map<String, dynamic>.from(remote)
      ..remove('user_id')
      ..remove('deleted_at');

    // Postgres booleans → SQLite integers
    for (final key in local.keys.toList()) {
      final v = local[key];
      if (v is bool) local[key] = v ? 1 : 0;
    }

    return local;
  }
}
