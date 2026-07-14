import 'database_helper.dart';
import 'models.dart';

class BadgeDao {
  Future<List<RunBadge>> getAllBadges() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('badges', orderBy: 'id ASC');
    return rows.map(RunBadge.fromMap).toList();
  }

  Future<List<UserBadge>> getUnlockedBadges() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('user_badges', orderBy: 'unlocked_at DESC');
    return rows.map(UserBadge.fromMap).toList();
  }

  Future<Set<int>> getUnlockedBadgeIds() async {
    final unlocked = await getUnlockedBadges();
    return unlocked.map((e) => e.badgeId).toSet();
  }

  /// Checks all badge conditions against the given progress values and
  /// unlocks any badge not already unlocked whose condition is now met.
  /// Returns the list of badges newly unlocked in this call.
  Future<List<RunBadge>> checkAndUnlockBadges({
    required double totalKm,
    required int currentStreak,
    required double lastRunKm,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final allBadges = await getAllBadges();
    final unlockedIds = await getUnlockedBadgeIds();
    final newlyUnlocked = <RunBadge>[];
    final now = DateTime.now().toIso8601String();

    for (final badge in allBadges) {
      if (unlockedIds.contains(badge.id)) continue;

      double currentValue;
      switch (badge.conditionType) {
        case 'total_km':
          currentValue = totalKm;
          break;
        case 'streak_days':
          currentValue = currentStreak.toDouble();
          break;
        case 'single_run_km':
          currentValue = lastRunKm;
          break;
        default:
          currentValue = 0;
      }

      if (currentValue >= badge.conditionValue) {
        await db.insert('user_badges', {
          'badge_id': badge.id,
          'unlocked_at': now,
        });
        newlyUnlocked.add(badge);
      }
    }

    return newlyUnlocked;
  }

  /// Groups badges sharing the same [RunBadge.conditionType] into a single
  /// "family" (e.g. all total_km badges are tiers of one achievement), sorted
  /// by ascending condition value so tiers render bronze -> silver -> gold.
  Future<Map<String, List<RunBadge>>> getBadgeFamilies() async {
    final all = await getAllBadges();
    final families = <String, List<RunBadge>>{};
    for (final badge in all) {
      families.putIfAbsent(badge.conditionType, () => []).add(badge);
    }
    for (final family in families.values) {
      family.sort((a, b) => a.conditionValue.compareTo(b.conditionValue));
    }
    return families;
  }
}
