import 'database_helper.dart';
import 'models.dart';

class LevelInfo {
  final int level;
  final String name;
  final double xpIntoLevel;
  final double xpForNextLevel;

  const LevelInfo({
    required this.level,
    required this.name,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
  });

  double get progress => xpForNextLevel <= 0 ? 1 : (xpIntoLevel / xpForNextLevel).clamp(0, 1);
}

class UserLevelDao {
  static const _levelNames = [
    'Người mới',
    'Người tập sự',
    'Chạy đều đặn',
    'Runner tự tin',
    'Runner nghiêm túc',
    'Vận động viên',
    'Chuyên gia bền bỉ',
    'Huyền thoại đường chạy',
  ];

  /// XP required cumulatively to reach each level (index 0 = level 1 start).
  static double _xpForLevel(int level) => 100.0 * level * level;

  static String nameForLevel(int level) {
    final idx = (level - 1).clamp(0, _levelNames.length - 1);
    return _levelNames[idx];
  }

  static int levelForXp(double totalXp) {
    var level = 1;
    while (totalXp >= _xpForLevel(level)) {
      level++;
    }
    return level;
  }

  static LevelInfo levelInfoForXp(double totalXp) {
    final level = levelForXp(totalXp);
    final currentFloor = level == 1 ? 0.0 : _xpForLevel(level - 1);
    final nextCeiling = _xpForLevel(level);
    return LevelInfo(
      level: level,
      name: nameForLevel(level),
      xpIntoLevel: totalXp - currentFloor,
      xpForNextLevel: nextCeiling - currentFloor,
    );
  }

  Future<UserLevel> getUserLevel() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('user_level', where: 'id = 1');
    if (rows.isEmpty) return const UserLevel();
    return UserLevel.fromMap(rows.first);
  }

  /// Adds [xp] to the running total and persists the recomputed level.
  /// Returns the updated [UserLevel] and whether this call caused a level-up.
  Future<(UserLevel, bool)> addXp(double xp) async {
    final db = await DatabaseHelper.instance.database;
    final current = await getUserLevel();
    final newTotal = current.totalXp + xp;
    final newLevel = levelForXp(newTotal);
    final leveledUp = newLevel > current.currentLevel;

    final updated = UserLevel(totalXp: newTotal, currentLevel: newLevel);
    await db.update('user_level', updated.toMap(), where: 'id = 1');
    return (updated, leveledUp);
  }
}
