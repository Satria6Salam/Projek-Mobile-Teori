import 'package:sqflite/sqflite.dart';

import '../../core/constants/db_constants.dart';
import '../../core/utils/db_date_utils.dart';
import '../../core/utils/password_hasher.dart';
import '../database/app_database.dart';
import '../models/user_model.dart';
import 'repository_exception.dart';

/// Akses data akun pengguna (UC-01).
class UserRepository {
  UserRepository({AppDatabase? database})
      : _appDatabase = database ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  /// Mendaftarkan akun baru. Melempar [RepositoryException] jika email sudah dipakai.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final Database db = await _db;
    final String normalizedEmail = _normalizeEmail(email);

    final List<Map<String, Object?>> existing = await db.query(
      DbTables.users,
      columns: <String>[UserCols.id],
      where: '${UserCols.email} = ?',
      whereArgs: <Object?>[normalizedEmail],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw const RepositoryException('Email sudah terdaftar');
    }

    final DateTime now = DateTime.now();
    final UserModel user = UserModel(
      name: name.trim(),
      email: normalizedEmail,
      passwordHash: PasswordHasher.hash(password),
      createdAt: now,
      updatedAt: now,
    );
    final int id = await db.insert(
      DbTables.users,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return user.copyWith(id: id);
  }

  /// Memvalidasi kredensial. Mengembalikan null jika email/password salah.
  Future<UserModel?> authenticate({
    required String email,
    required String password,
  }) async {
    final UserModel? user = await getByEmail(email);
    if (user == null) return null;
    if (!PasswordHasher.verify(password, user.passwordHash)) return null;
    return user;
  }

  Future<UserModel?> getById(int id) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      DbTables.users,
      where: '${UserCols.id} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }

  Future<UserModel?> getByEmail(String email) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      DbTables.users,
      where: '${UserCols.email} = ?',
      whereArgs: <Object?>[_normalizeEmail(email)],
      limit: 1,
    );
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }

  Future<bool> updateName({required int userId, required String name}) async {
    final Database db = await _db;
    final int count = await db.update(
      DbTables.users,
      <String, Object?>{
        UserCols.name: name.trim(),
        UserCols.updatedAt: DbDateUtils.dateTimeToDb(DateTime.now()),
      },
      where: '${UserCols.id} = ?',
      whereArgs: <Object?>[userId],
    );
    return count > 0;
  }

  /// Menghapus akun beserta seluruh data miliknya (cascade).
  Future<bool> deleteUser(int userId) async {
    final Database db = await _db;
    final int count = await db.delete(
      DbTables.users,
      where: '${UserCols.id} = ?',
      whereArgs: <Object?>[userId],
    );
    return count > 0;
  }
}
