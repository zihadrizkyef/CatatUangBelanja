import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../db/app_database.dart';
import '../models/transaction.dart';
import '../repositories/finance_repository.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Header sync indicator states (doc 7.2: "tersinkron / menunggu / offline").
enum SyncState { idle, syncing, offline, error }

/// Orchestrates doc 4.10's push-then-pull cycle: uploads local
/// wallets/categories/budgets (small, low-churn — pushed in full each time)
/// and only-pending transactions (tombstones included, for soft-delete
/// propagation), then pulls anything changed remotely since the last
/// successful sync and merges it into the local SQLite tables.
///
/// Scope note: RecurringTransaction and Settings sync are not wired up yet —
/// the app has no local RecurringTransaction feature to sync at all (Tahap 6
/// per the roadmap), and Settings sync would need to reconcile with
/// SecurityService's separate secure-storage-backed PIN state, deferred as
/// follow-up work rather than rushed here.
class SyncService extends ChangeNotifier {
  SyncService({
    required FinanceRepository repository,
    required AuthService authService,
    ApiClient? apiClient,
    AppDatabase? appDatabase,
    Connectivity? connectivity,
  })  : _repository = repository, // ignore: prefer_initializing_formals
        _authService = authService, // ignore: prefer_initializing_formals
        _apiClient = apiClient ?? ApiClient(),
        _appDatabase = appDatabase ?? AppDatabase.instance,
        _connectivity = connectivity ?? Connectivity() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        if (!results.contains(ConnectivityResult.none)) {
          syncNow();
        }
      },
      // No platform implementation under `flutter test` (no real device) —
      // fails closed to "just don't auto-sync" rather than crashing every
      // widget test that builds the provider tree.
      onError: (_) {},
    );
  }

  final FinanceRepository _repository;
  final AuthService _authService;
  final ApiClient _apiClient;
  final AppDatabase _appDatabase;
  final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  static const _cursorKey = 'last_sync_cursor';
  static const _boolColumnsByTable = {
    'wallets': ['is_archived'],
    'categories': ['is_system'],
    'transactions': ['is_deleted'],
  };
  static const _dateColumnsByTable = {
    'wallets': ['created_at'],
    'transactions': ['date_time', 'created_at', 'updated_at'],
    'budgets': ['current_period_started_at', 'created_at', 'updated_at'],
  };

  SyncState _state = SyncState.idle;
  SyncState get state => _state;
  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  Future<void> syncNow() async {
    if (_state == SyncState.syncing) return;
    if (!await _authService.isLoggedIn) return;

    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _state = SyncState.offline;
      notifyListeners();
      return;
    }

    _state = SyncState.syncing;
    notifyListeners();

    try {
      final token = await _authService.sessionToken;
      if (token == null) {
        _state = SyncState.idle;
        notifyListeners();
        return;
      }

      final pendingTransactions = _repository.allTransactionsIncludingDeleted
          .where((t) => t.syncStatus != SyncStatus.synced)
          .toList();

      await _apiClient.push(token, {
        'wallets': _repository.wallets.map((w) => _toWireFormat('wallets', w.toMap())).toList(),
        'categories': _repository.categories.map((c) => _toWireFormat('categories', c.toMap())).toList(),
        'budgets': _repository.budgets.map((b) => _toWireFormat('budgets', b.toMap())).toList(),
        'transactions': pendingTransactions.map((t) => _toWireFormat('transactions', t.toMap())).toList(),
      });
      await _markSynced(pendingTransactions.map((t) => t.id));

      final since = await _loadCursor();
      final pulled = await _apiClient.pull(token, since: since);
      await _applyPulled(pulled);
      await _saveCursor(pulled['server_time'] as String);

      await _repository.load();
      _state = SyncState.idle;
      _lastSyncedAt = DateTime.now();
    } catch (_) {
      _state = SyncState.error;
    }
    notifyListeners();
  }

  Future<void> _markSynced(Iterable<String> transactionIds) async {
    if (transactionIds.isEmpty) return;
    final db = await _appDatabase.database;
    final placeholders = List.filled(transactionIds.length, '?').join(', ');
    await db.update(
      'transactions',
      {'sync_status': 'synced'},
      where: 'id IN ($placeholders)',
      whereArgs: transactionIds.toList(),
    );
  }

  Future<void> _applyPulled(Map<String, Object?> pulled) async {
    for (final table in const ['wallets', 'categories', 'transactions', 'budgets']) {
      final rows = (pulled[table] as List?)?.cast<Map<String, Object?>>() ?? const [];
      if (rows.isEmpty) continue;
      final boolColumns = _boolColumnsByTable[table] ?? const [];
      await _appDatabase.upsertRows(table, [for (final row in rows) _boolsToInts(row, boolColumns)]);
    }
  }

  /// sqlite columns for booleans are INTEGER 0/1 (see e.g. [Wallet.toMap]),
  /// but a decoded JSON pull response carries real Dart `bool`s.
  Map<String, Object?> _boolsToInts(Map<String, Object?> row, List<String> boolColumns) {
    return {
      for (final entry in row.entries)
        entry.key: boolColumns.contains(entry.key) && entry.value is bool
            ? ((entry.value as bool) ? 1 : 0)
            : entry.value,
    };
  }

  /// Converts a [toMap] row — SQLite-oriented (booleans as 0/1 ints, dates
  /// as `DateTime.toIso8601String()`, which omits the UTC "Z" suffix for a
  /// local-time value) — into the backend's wire format (real JSON
  /// booleans, UTC ISO-8601 datetimes per doc 4.10's zod schemas). The
  /// inverse of [_boolsToInts], plus a date fixup [_applyPulled] doesn't
  /// need since pulled datetimes already arrive UTC-formatted.
  Map<String, Object?> _toWireFormat(String table, Map<String, Object?> row) {
    final boolColumns = _boolColumnsByTable[table] ?? const [];
    final dateColumns = _dateColumnsByTable[table] ?? const [];
    return {
      for (final entry in row.entries)
        entry.key: boolColumns.contains(entry.key) && entry.value is int
            ? (entry.value as int) == 1
            : dateColumns.contains(entry.key) && entry.value is String
                ? DateTime.parse(entry.value as String).toUtc().toIso8601String()
                : entry.value,
    };
  }

  Future<DateTime?> _loadCursor() async {
    final db = await _appDatabase.database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [_cursorKey]);
    if (rows.isEmpty) return null;
    return DateTime.parse(rows.first['value'] as String);
  }

  Future<void> _saveCursor(String serverTime) async {
    final db = await _appDatabase.database;
    await db.insert(
      'settings',
      {'key': _cursorKey, 'value': serverTime},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
