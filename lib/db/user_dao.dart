import '../utils/password_util.dart';
import 'database_helper.dart';

class UserDao {
  Future<bool> usernameExists(String username) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('users', where: 'username = ?', whereArgs: [username]);
    return rows.isNotEmpty;
  }

  /// Creates a new user account and returns the new user's id.
  Future<int> createUser(String username, String password) async {
    final db = await DatabaseHelper.instance.database;
    final salt = PasswordUtil.generateSalt();
    final hash = PasswordUtil.hash(password, salt);
    return db.insert('users', {
      'username': username,
      'password_hash': hash,
      'salt': salt,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Verifies credentials and returns the user id on success, null otherwise.
  Future<int?> verifyPassword(String username, String password) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    final salt = row['salt'] as String;
    final hash = row['password_hash'] as String;
    if (!PasswordUtil.verify(password, salt, hash)) return null;
    return row['id'] as int;
  }
}
