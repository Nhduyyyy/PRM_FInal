import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../db/activity_dao.dart';
import '../db/profile_dao.dart';
import 'weekly_challenge_service.dart';

/// Pushes this week's distance + current streak to the Android home screen
/// widget (see android/.../RunTrackerWidgetProvider.kt). Android-only for
/// now — an iOS WidgetKit extension requires a separate Xcode target that
/// can't be added via source-file edits alone, so iOS just no-ops here.
class HomeWidgetService {
  static const _androidProviderName = 'RunTrackerWidgetProvider';
  static final DateFormat _fmt = DateFormat('yyyy-MM-dd');

  static Future<void> refresh() async {
    final weekStart = WeeklyChallengeService.mondayOf(DateTime.now());
    final weekKm = await ActivityDao().getDistanceInRange(
      _fmt.format(weekStart),
      _fmt.format(DateTime.now()),
    );
    final streak = await ProfileDao().getStreakInfo();

    try {
      await HomeWidget.saveWidgetData<String>('week_km', weekKm.toStringAsFixed(1));
      await HomeWidget.saveWidgetData<String>('streak', '${streak.currentStreak}');
      await HomeWidget.updateWidget(androidName: _androidProviderName);
    } catch (_) {
      // home_widget has no macOS/web/Linux/Windows implementation — this is
      // an Android-only feature, so unsupported platforms just no-op here.
    }
  }
}
