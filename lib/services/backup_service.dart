import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';
import '../services/session_service.dart';

/// Exports/imports every user-data table to a single JSON file, for backup
/// or moving to a new device. No backend involved — pure local file I/O.
///
/// Only the currently logged-in account's rows are exported/restored for
/// per-user tables; shared catalog tables (badges, training plan catalog)
/// are exported/restored in full since they aren't owned by any one account.
/// The `users` table itself is never included (backups carry run data, not
/// credentials) — restoring a backup always attaches the data to whichever
/// account is logged in at the time.
class BackupService {
  static const _perUserTables = [
    'user_profile',
    'activities',
    'goals',
    'user_badges',
    'streak_info',
    'active_plan',
    'user_level',
    'workout_templates',
    'daily_steps',
    'weekly_challenges',
  ];

  static const _sharedTables = [
    'badges',
    'training_plans',
    'training_plan_days',
  ];

  Future<File> exportToFile() async {
    final db = await DatabaseHelper.instance.database;
    final userId = SessionService.instance.requireUserId;
    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in _perUserTables) {
      tables[table] = await db.query(table, where: 'user_id = ?', whereArgs: [userId]);
    }
    for (final table in _sharedTables) {
      tables[table] = await db.query(table);
    }

    final json = const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': DatabaseHelper.schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': tables,
    });

    final dir = await getTemporaryDirectory();
    await dir.create(recursive: true);
    final file = File('${dir.path}/run_tracker_backup.json');
    return file.writeAsString(json);
  }

  Future<void> shareBackup() async {
    final file = await exportToFile();
    await Share.shareXFiles([XFile(file.path)], text: 'Run Tracker — sao lưu dữ liệu');
  }

  /// Replaces the current account's rows in every per-user table, and every
  /// row of the shared catalog tables, with the contents of [file].
  Future<void> restoreFromFile(File file) async {
    final content = await file.readAsString();
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    final tables = decoded['tables'] as Map<String, dynamic>;
    final db = await DatabaseHelper.instance.database;
    final userId = SessionService.instance.requireUserId;

    await db.transaction((txn) async {
      for (final table in _perUserTables) {
        final rows = (tables[table] as List?)?.cast<Map<String, dynamic>>() ?? const [];
        await txn.delete(table, where: 'user_id = ?', whereArgs: [userId]);
        for (final row in rows) {
          final map = Map<String, Object?>.from(row)..['user_id'] = userId;
          await txn.insert(table, map, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      for (final table in _sharedTables) {
        final rows = (tables[table] as List?)?.cast<Map<String, dynamic>>() ?? const [];
        await txn.delete(table);
        for (final row in rows) {
          await txn.insert(table, Map<String, Object?>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }
}
