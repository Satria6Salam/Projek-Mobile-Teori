import 'package:sqflite/sqflite.dart';

import '../../core/constants/db_constants.dart';
import '../database/app_database.dart';
import '../models/shopping_plan_model.dart';

/// Akses data rencana belanja.
class ShoppingPlanRepository {
  ShoppingPlanRepository({AppDatabase? database})
      : _appDatabase = database ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  /// Semua barang rencana milik pengguna, yang terbaru di atas.
  Future<List<ShoppingPlanModel>> getAll(int userId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      DbTables.shoppingPlans,
      where: '${PlanCols.userId} = ?',
      whereArgs: <Object?>[userId],
      orderBy: '${PlanCols.createdAt} DESC, ${PlanCols.id} DESC',
    );
    return rows.map(ShoppingPlanModel.fromMap).toList();
  }

  /// Barang yang belum dibeli (dipakai saat mencocokkan struk).
  Future<List<ShoppingPlanModel>> getPending(int userId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      DbTables.shoppingPlans,
      where: '${PlanCols.userId} = ? AND ${PlanCols.status} = ?',
      whereArgs: <Object?>[userId, PlanStatus.pending],
      orderBy: '${PlanCols.createdAt} ASC, ${PlanCols.id} ASC',
    );
    return rows.map(ShoppingPlanModel.fromMap).toList();
  }

  Future<int> insert(ShoppingPlanModel plan) async {
    final Database db = await _db;
    return db.insert(DbTables.shoppingPlans, plan.toMap());
  }

  Future<void> update(ShoppingPlanModel plan) async {
    final Database db = await _db;
    await db.update(
      DbTables.shoppingPlans,
      plan.toMap(),
      where: '${PlanCols.id} = ?',
      whereArgs: <Object?>[plan.id],
    );
  }

  /// Menyimpan beberapa perubahan sekaligus (satu transaksi basis data).
  Future<void> updateAll(List<ShoppingPlanModel> plans) async {
    if (plans.isEmpty) return;
    final Database db = await _db;
    await db.transaction((Transaction txn) async {
      for (final ShoppingPlanModel plan in plans) {
        await txn.update(
          DbTables.shoppingPlans,
          plan.toMap(),
          where: '${PlanCols.id} = ?',
          whereArgs: <Object?>[plan.id],
        );
      }
    });
  }

  Future<void> delete(int planId) async {
    final Database db = await _db;
    await db.delete(
      DbTables.shoppingPlans,
      where: '${PlanCols.id} = ?',
      whereArgs: <Object?>[planId],
    );
  }

  /// Menghapus seluruh barang yang sudah dibeli dari rekap.
  Future<int> deleteBought(int userId) async {
    final Database db = await _db;
    return db.delete(
      DbTables.shoppingPlans,
      where: '${PlanCols.userId} = ? AND ${PlanCols.status} = ?',
      whereArgs: <Object?>[userId, PlanStatus.bought],
    );
  }
}
