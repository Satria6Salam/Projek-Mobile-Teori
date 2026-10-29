import 'package:sqflite/sqflite.dart';

import '../../core/constants/db_constants.dart';
import '../database/app_database.dart';
import '../models/category_model.dart';
import 'repository_exception.dart';

/// Akses data kategori pengeluaran.
class CategoryRepository {
  CategoryRepository({AppDatabase? database})
      : _appDatabase = database ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  Future<List<CategoryModel>> getAll() async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      DbTables.categories,
      orderBy: '${CategoryCols.id} ASC',
    );
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<CategoryModel?> getById(int id) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      DbTables.categories,
      where: '${CategoryCols.id} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : CategoryModel.fromMap(rows.first);
  }

  Future<CategoryModel?> getByName(String name) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      DbTables.categories,
      where: '${CategoryCols.name} = ? COLLATE NOCASE',
      whereArgs: <Object?>[name.trim()],
      limit: 1,
    );
    return rows.isEmpty ? null : CategoryModel.fromMap(rows.first);
  }

  Future<CategoryModel> insert(CategoryModel category) async {
    final Database db = await _db;
    final CategoryModel? duplicate = await getByName(category.name);
    if (duplicate != null) {
      throw const RepositoryException('Nama kategori sudah ada');
    }
    final int id = await db.insert(DbTables.categories, category.toMap());
    return category.copyWith(id: id);
  }

  Future<bool> update(CategoryModel category) async {
    final int? id = category.id;
    if (id == null) {
      throw const RepositoryException('ID kategori tidak ditemukan');
    }
    final Database db = await _db;
    final Map<String, Object?> values = Map<String, Object?>.of(category.toMap())
      ..remove(CategoryCols.id);
    final int count = await db.update(
      DbTables.categories,
      values,
      where: '${CategoryCols.id} = ?',
      whereArgs: <Object?>[id],
    );
    return count > 0;
  }

  /// Gagal jika kategori masih dipakai oleh transaksi (foreign key RESTRICT).
  Future<bool> delete(int id) async {
    final Database db = await _db;
    try {
      final int count = await db.delete(
        DbTables.categories,
        where: '${CategoryCols.id} = ?',
        whereArgs: <Object?>[id],
      );
      return count > 0;
    } on DatabaseException {
      throw const RepositoryException(
        'Kategori masih dipakai oleh transaksi dan tidak dapat dihapus',
      );
    }
  }
}
