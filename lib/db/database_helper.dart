import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../utils/password_util.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const int schemaVersion = 3;

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'run_tracker.db');
    return openDatabase(
      path,
      version: schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        name TEXT NOT NULL,
        weight_kg REAL NOT NULL,
        height_cm REAL NOT NULL,
        unit TEXT NOT NULL DEFAULT 'km',
        theme_mode TEXT NOT NULL DEFAULT 'system',
        daily_reminder_enabled INTEGER NOT NULL DEFAULT 0,
        daily_reminder_time TEXT NOT NULL DEFAULT '18:00',
        goal_reminder_enabled INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        distance_km REAL NOT NULL,
        duration_seconds INTEGER NOT NULL,
        avg_pace_sec_per_km INTEGER NOT NULL,
        best_pace_sec_per_km INTEGER NOT NULL,
        calories INTEGER NOT NULL,
        route_polyline TEXT NOT NULL,
        note TEXT,
        mood TEXT,
        photo_path TEXT,
        location_tag TEXT,
        created_at TEXT NOT NULL,
        activity_type TEXT NOT NULL DEFAULT 'run',
        workout_mode TEXT NOT NULL DEFAULT 'free',
        interval_config TEXT,
        plan_day_id INTEGER,
        audio_note_path TEXT,
        elevation_gain_m REAL NOT NULL DEFAULT 0,
        xp_earned REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        target_km REAL NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE badges (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        condition_type TEXT NOT NULL,
        condition_value REAL NOT NULL,
        icon TEXT NOT NULL,
        tier TEXT NOT NULL DEFAULT 'single'
      )
    ''');

    await db.execute('''
      CREATE TABLE user_badges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        badge_id INTEGER NOT NULL,
        unlocked_at TEXT NOT NULL,
        FOREIGN KEY (badge_id) REFERENCES badges (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE streak_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        current_streak INTEGER NOT NULL DEFAULT 0,
        best_streak INTEGER NOT NULL DEFAULT 0,
        last_run_date TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE training_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        total_weeks INTEGER NOT NULL,
        level TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE training_plan_days (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        week_number INTEGER NOT NULL,
        day_number INTEGER NOT NULL,
        day_type TEXT NOT NULL,
        target_distance_km REAL,
        target_duration_seconds INTEGER,
        description TEXT,
        FOREIGN KEY (plan_id) REFERENCES training_plans (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE active_plan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        plan_id INTEGER,
        start_date TEXT,
        FOREIGN KEY (plan_id) REFERENCES training_plans (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE user_level (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        total_xp REAL NOT NULL DEFAULT 0,
        current_level INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        config_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_steps (
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        baseline_steps INTEGER NOT NULL,
        last_steps INTEGER NOT NULL,
        PRIMARY KEY (user_id, date),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE weekly_challenges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        week_start_date TEXT NOT NULL,
        target_km REAL NOT NULL,
        achieved INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await _seedBadges(db);
    await _seedBadgeTiers(db);
    await _seedCouchTo5kPlan(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE activities ADD COLUMN activity_type TEXT NOT NULL DEFAULT 'run'");
      await db.execute("ALTER TABLE activities ADD COLUMN workout_mode TEXT NOT NULL DEFAULT 'free'");
      await db.execute('ALTER TABLE activities ADD COLUMN interval_config TEXT');
      await db.execute('ALTER TABLE activities ADD COLUMN plan_day_id INTEGER');
      await db.execute('ALTER TABLE activities ADD COLUMN audio_note_path TEXT');
      await db.execute('ALTER TABLE activities ADD COLUMN elevation_gain_m REAL NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE activities ADD COLUMN xp_earned REAL NOT NULL DEFAULT 0');
      await db.execute("ALTER TABLE badges ADD COLUMN tier TEXT NOT NULL DEFAULT 'single'");

      await _createV2Tables(db);
      await _seedV2Data(db);
    }

    if (oldVersion < 3) {
      await _migrateToMultiUser(db);
    }
  }

  /// Schema v2 -> v3: introduces the `users` table and scopes every
  /// per-user table by `user_id`. Existing (pre-auth) data is preserved by
  /// attaching it to an auto-created "legacy" account (username `legacy`,
  /// password `legacy123`), which always becomes user id 1 since it is the
  /// first row inserted into the brand new `users` table.
  Future<void> _migrateToMultiUser(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    final legacySalt = PasswordUtil.generateSalt();
    await db.insert('users', {
      'username': 'legacy',
      'password_hash': PasswordUtil.hash('legacy123', legacySalt),
      'salt': legacySalt,
      'created_at': DateTime.now().toIso8601String(),
    });
    const legacyUserId = 1;

    // Tables without a CHECK/PK conflict: a plain ADD COLUMN is enough.
    await db.execute('ALTER TABLE activities ADD COLUMN user_id INTEGER NOT NULL DEFAULT $legacyUserId');
    await db.execute('ALTER TABLE goals ADD COLUMN user_id INTEGER NOT NULL DEFAULT $legacyUserId');
    await db.execute('ALTER TABLE user_badges ADD COLUMN user_id INTEGER NOT NULL DEFAULT $legacyUserId');
    await db.execute('ALTER TABLE workout_templates ADD COLUMN user_id INTEGER NOT NULL DEFAULT $legacyUserId');
    await db.execute('ALTER TABLE weekly_challenges ADD COLUMN user_id INTEGER NOT NULL DEFAULT $legacyUserId');

    // Singleton CHECK(id = 1) tables: SQLite can't alter a CHECK constraint
    // in place, so rebuild each table (rename -> create -> copy -> drop).
    await db.execute('ALTER TABLE user_profile RENAME TO user_profile_old');
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        name TEXT NOT NULL,
        weight_kg REAL NOT NULL,
        height_cm REAL NOT NULL,
        unit TEXT NOT NULL DEFAULT 'km',
        theme_mode TEXT NOT NULL DEFAULT 'system',
        daily_reminder_enabled INTEGER NOT NULL DEFAULT 0,
        daily_reminder_time TEXT NOT NULL DEFAULT '18:00',
        goal_reminder_enabled INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      INSERT INTO user_profile (user_id, name, weight_kg, height_cm, unit, theme_mode, daily_reminder_enabled, daily_reminder_time, goal_reminder_enabled)
      SELECT $legacyUserId, name, weight_kg, height_cm, unit, theme_mode, daily_reminder_enabled, daily_reminder_time, goal_reminder_enabled FROM user_profile_old
    ''');
    await db.execute('DROP TABLE user_profile_old');

    await db.execute('ALTER TABLE streak_info RENAME TO streak_info_old');
    await db.execute('''
      CREATE TABLE streak_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        current_streak INTEGER NOT NULL DEFAULT 0,
        best_streak INTEGER NOT NULL DEFAULT 0,
        last_run_date TEXT
      )
    ''');
    await db.execute('''
      INSERT INTO streak_info (user_id, current_streak, best_streak, last_run_date)
      SELECT $legacyUserId, current_streak, best_streak, last_run_date FROM streak_info_old
    ''');
    await db.execute('DROP TABLE streak_info_old');

    await db.execute('ALTER TABLE active_plan RENAME TO active_plan_old');
    await db.execute('''
      CREATE TABLE active_plan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        plan_id INTEGER,
        start_date TEXT,
        FOREIGN KEY (plan_id) REFERENCES training_plans (id)
      )
    ''');
    await db.execute('''
      INSERT INTO active_plan (user_id, plan_id, start_date)
      SELECT $legacyUserId, plan_id, start_date FROM active_plan_old
    ''');
    await db.execute('DROP TABLE active_plan_old');

    await db.execute('ALTER TABLE user_level RENAME TO user_level_old');
    await db.execute('''
      CREATE TABLE user_level (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        total_xp REAL NOT NULL DEFAULT 0,
        current_level INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      INSERT INTO user_level (user_id, total_xp, current_level)
      SELECT $legacyUserId, total_xp, current_level FROM user_level_old
    ''');
    await db.execute('DROP TABLE user_level_old');

    // daily_steps: PK changes from `date` to `(user_id, date)`, also needs a rebuild.
    await db.execute('ALTER TABLE daily_steps RENAME TO daily_steps_old');
    await db.execute('''
      CREATE TABLE daily_steps (
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        baseline_steps INTEGER NOT NULL,
        last_steps INTEGER NOT NULL,
        PRIMARY KEY (user_id, date)
      )
    ''');
    await db.execute('''
      INSERT INTO daily_steps (user_id, date, baseline_steps, last_steps)
      SELECT $legacyUserId, date, baseline_steps, last_steps FROM daily_steps_old
    ''');
    await db.execute('DROP TABLE daily_steps_old');
  }

  /// Tables introduced in schema v2 (Pillars A-D expansion).
  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE training_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        total_weeks INTEGER NOT NULL,
        level TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE training_plan_days (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        week_number INTEGER NOT NULL,
        day_number INTEGER NOT NULL,
        day_type TEXT NOT NULL,
        target_distance_km REAL,
        target_duration_seconds INTEGER,
        description TEXT,
        FOREIGN KEY (plan_id) REFERENCES training_plans (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE active_plan (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        plan_id INTEGER,
        start_date TEXT,
        FOREIGN KEY (plan_id) REFERENCES training_plans (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE user_level (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        total_xp REAL NOT NULL DEFAULT 0,
        current_level INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        config_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_steps (
        date TEXT PRIMARY KEY,
        baseline_steps INTEGER NOT NULL,
        last_steps INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE weekly_challenges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        week_start_date TEXT NOT NULL,
        target_km REAL NOT NULL,
        achieved INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _seedV2Data(Database db) async {
    await _seedBadgeTiers(db);

    await db.insert('user_level', {'id': 1, 'total_xp': 0.0, 'current_level': 1});
    await db.insert('active_plan', {'id': 1, 'plan_id': null, 'start_date': null});

    await _seedCouchTo5kPlan(db);
  }

  Future<void> _seedBadgeTiers(Database db) async {
    await db.update('badges', {'tier': 'bronze'}, where: 'id = 4');
    await db.update('badges', {'tier': 'silver'}, where: 'id = 5');
    await db.update('badges', {'tier': 'gold'}, where: 'id = 6');
  }

  /// Seeds the default "Từ 0 đến 5K trong 8 tuần" beginner training plan.
  Future<void> _seedCouchTo5kPlan(Database db) async {
    final planId = await db.insert('training_plans', {
      'name': 'Từ 0 đến 5K trong 8 tuần',
      'description': 'Lộ trình luyện tập dành cho người mới bắt đầu, tăng dần cường độ qua 8 tuần.',
      'total_weeks': 8,
      'level': 'beginner',
    });

    final days = <Map<String, Object?>>[];
    for (var week = 1; week <= 8; week++) {
      final easyKm = 1.0 + week * 0.3;
      final longKm = 2.0 + week * 0.5;
      for (var day = 1; day <= 7; day++) {
        String dayType;
        double? targetKm;
        int? targetDuration;
        String description;

        if (day == 6) {
          dayType = 'interval';
          targetDuration = (15 + week) * 60;
          description = 'Interval: xen kẽ chạy nhanh và đi bộ trong ${15 + week} phút.';
        } else if (day == 7) {
          dayType = 'long_run';
          targetKm = double.parse(longKm.toStringAsFixed(1));
          description = 'Chạy dài ${targetKm.toStringAsFixed(1)}km, giữ pace thoải mái.';
        } else if (day == 2 || day == 4) {
          dayType = 'easy_run';
          targetKm = double.parse(easyKm.toStringAsFixed(1));
          description = 'Chạy nhẹ ${targetKm.toStringAsFixed(1)}km.';
        } else {
          dayType = 'rest';
          description = 'Ngày nghỉ, hồi phục cơ thể.';
        }

        days.add({
          'plan_id': planId,
          'week_number': week,
          'day_number': day,
          'day_type': dayType,
          'target_distance_km': targetKm,
          'target_duration_seconds': targetDuration,
          'description': description,
        });
      }
    }

    final batch = db.batch();
    for (final day in days) {
      batch.insert('training_plan_days', day);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedBadges(Database db) async {
    final badges = <Map<String, Object?>>[
      {
        'id': 1,
        'name': 'Km đầu tiên',
        'description': 'Hoàn thành buổi chạy đầu tiên',
        'condition_type': 'total_km',
        'condition_value': 1.0,
        'icon': 'flag',
      },
      {
        'id': 2,
        'name': 'Chiến binh 5K',
        'description': 'Chạy một buổi dài 5km',
        'condition_type': 'single_run_km',
        'condition_value': 5.0,
        'icon': 'directions_run',
      },
      {
        'id': 3,
        'name': 'Chiến binh 10K',
        'description': 'Chạy một buổi dài 10km',
        'condition_type': 'single_run_km',
        'condition_value': 10.0,
        'icon': 'directions_run',
      },
      {
        'id': 4,
        'name': 'Tổng 10km',
        'description': 'Chạy tổng cộng 10km',
        'condition_type': 'total_km',
        'condition_value': 10.0,
        'icon': 'timeline',
      },
      {
        'id': 5,
        'name': 'Tổng 50km',
        'description': 'Chạy tổng cộng 50km',
        'condition_type': 'total_km',
        'condition_value': 50.0,
        'icon': 'timeline',
      },
      {
        'id': 6,
        'name': 'Tổng 100km',
        'description': 'Chạy tổng cộng 100km',
        'condition_type': 'total_km',
        'condition_value': 100.0,
        'icon': 'emoji_events',
      },
      {
        'id': 7,
        'name': 'Chuỗi 3 ngày',
        'description': 'Giữ streak chạy bộ 3 ngày liên tục',
        'condition_type': 'streak_days',
        'condition_value': 3.0,
        'icon': 'local_fire_department',
      },
      {
        'id': 8,
        'name': 'Chuỗi 7 ngày',
        'description': 'Giữ streak chạy bộ 7 ngày liên tục',
        'condition_type': 'streak_days',
        'condition_value': 7.0,
        'icon': 'local_fire_department',
      },
      {
        'id': 9,
        'name': 'Chuỗi 30 ngày',
        'description': 'Giữ streak chạy bộ 30 ngày liên tục',
        'condition_type': 'streak_days',
        'condition_value': 30.0,
        'icon': 'whatshot',
      },
    ];

    final batch = db.batch();
    for (final badge in badges) {
      batch.insert('badges', badge);
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
