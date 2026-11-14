import 'package:sqflite/sqflite.dart';

import '../../core/constants/db_constants.dart';
import '../../core/utils/db_date_utils.dart';
import '../database/app_database.dart';
import '../models/budget_model.dart';

/// Akses data anggaran (batas pengeluaran bulanan).
class BudgetRepository {
  BudgetRepository({AppDatabase? database})
      : _appDatabase = database ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  Future<List<BudgetModel>> getAll(int userId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      DbTables.budgets,
      where: '${BudgetCols.userId} = ?',
      whereArgs: <Object?>[userId],
    );
    return rows.map(BudgetModel.fromMap).toList();
  }

  /// Menyimpan batas baru atau memperbarui yang sudah ada.
  Future<void> upsert({
    required int userId,
    int? categoryId,
    required double amount,
  }) async {
    final Database db = await _db;
    final String now = DbDateUtils.dateTimeToDb(DateTime.now());
    final List<Map<String, Object?>> existing = await db.query(
      DbTables.budgets,
      where: _where(categoryId),
      whereArgs: _args(userId, categoryId),
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert(DbTables.budgets, <String, Object?>{
        BudgetCols.userId: userId,
        BudgetCols.categoryId: categoryId,
        BudgetCols.amount: amount,
        BudgetCols.createdAt: now,
        BudgetCols.updatedAt: now,
      });
    } else {
      await db.update(
        DbTables.budgets,
        <String, Object?>{BudgetCols.amount: amount, BudgetCols.updatedAt: now},
        where: _where(categoryId),
        whereArgs: _args(userId, categoryId),
      );
    }
  }

  Future<void> delete({required int userId, int? categoryId}) async {
    final Database db = await _db;
    await db.delete(
      DbTables.budgets,
      where: _where(categoryId),
      whereArgs: _args(userId, categoryId),
    );
  }

  String _where(int? categoryId) => categoryId == null
      ? '${BudgetCols.userId} = ? AND ${BudgetCols.categoryId} IS NULL'
      : '${BudgetCols.userId} = ? AND ${BudgetCols.categoryId} = ?';

  List<Object?> _args(int userId, int? categoryId) =>
      categoryId == null ? <Object?>[userId] : <Object?>[userId, categoryId];
}
