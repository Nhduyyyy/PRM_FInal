import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';

/// Exports/imports every user-data table to a single JSON file, for backup
/// or moving to a new device. No backend involved — pure local file I/O.
class BackupService {
  static const _tables = [
    'user_profile',
    'activities',
    'goals',
    'badges',
    'user_badges',
    'streak_info',
    'training_plans',
    'training_plan_days',
    'active_plan',
    'user_level',
    'workout_templates',
    'daily_steps',
    'weekly_challenges',
  ];

  Future<File> exportToFile() async {
    final db = await DatabaseHelper.instance.database;
    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in _tables) {
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

  /// Replaces every row in every known table with the contents of [file].
  Future<void> restoreFromFile(File file) async {
    final content = await file.readAsString();
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    final tables = decoded['tables'] as Map<String, dynamic>;
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      for (final table in _tables) {
        final rows = (tables[table] as List?)?.cast<Map<String, dynamic>>() ?? const [];
        await txn.delete(table);
        for (final row in rows) {
          await txn.insert(
            table,
            Map<String, Object?>.from(row),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }
}
