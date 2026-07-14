import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../db/activity_dao.dart';

class ExportUtil {
  static Future<void> exportAsJson() async {
    final activities = await ActivityDao().getAll();
    final json = const JsonEncoder.withIndent('  ').convert(
      activities.map((a) => a.toMap()).toList(),
    );
    final file = await _writeTempFile('run_tracker_export.json', json);
    await Share.shareXFiles([XFile(file.path)], text: 'Dữ liệu Run Tracker (JSON)');
  }

  static Future<void> exportAsCsv() async {
    final activities = await ActivityDao().getAll();
    final buffer = StringBuffer()
      ..writeln('date,distance_km,duration_seconds,avg_pace_sec_per_km,best_pace_sec_per_km,calories,note,mood,location_tag');
    for (final a in activities) {
      final note = (a.note ?? '').replaceAll(',', ';').replaceAll('\n', ' ');
      final tag = (a.locationTag ?? '').replaceAll(',', ';');
      buffer.writeln(
        '${a.date},${a.distanceKm},${a.durationSeconds},${a.avgPaceSecPerKm},${a.bestPaceSecPerKm},${a.calories},$note,${a.mood ?? ''},$tag',
      );
    }
    final file = await _writeTempFile('run_tracker_export.csv', buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'Dữ liệu Run Tracker (CSV)');
  }

  static Future<File> _writeTempFile(String name, String content) async {
    final dir = await getTemporaryDirectory();
    await dir.create(recursive: true);
    final file = File('${dir.path}/$name');
    return file.writeAsString(content);
  }
}
