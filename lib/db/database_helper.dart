import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

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
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
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
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        target_km REAL NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE badges (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        condition_type TEXT NOT NULL,
        condition_value REAL NOT NULL,
        icon TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_badges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        badge_id INTEGER NOT NULL,
        unlocked_at TEXT NOT NULL,
        FOREIGN KEY (badge_id) REFERENCES badges (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE streak_info (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        current_streak INTEGER NOT NULL DEFAULT 0,
        best_streak INTEGER NOT NULL DEFAULT 0,
        last_run_date TEXT
      )
    ''');

    await db.insert('streak_info', {
      'id': 1,
      'current_streak': 0,
      'best_streak': 0,
      'last_run_date': null,
    });

    await _seedBadges(db);
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
