import 'package:sqflite/sqflite.dart';

import '../../core/constants/db_constants.dart';
import '../database/app_database.dart';
import '../models/recurring_transaction_model.dart';

/// Akses data transaksi berulang.
class RecurringRepository {
  RecurringRepository({AppDatabase? database})
      : _appDatabase = database ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  Future<List<RecurringTransactionModel>> getAll(int userId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      DbTables.recurringTransactions,
      where: '${RecurringCols.userId} = ?',
      whereArgs: <Object?>[userId],
      orderBy: '${RecurringCols.dayOfMonth} ASC',
    );
    return rows.map(RecurringTransactionModel.fromMap).toList();
  }

  Future<RecurringTransactionModel> insert(
    RecurringTransactionModel model,
  ) async {
    final Database db = await _db;
    final int id = await db.insert(
      DbTables.recurringTransactions,
      model.toMap(),
    );
    return RecurringTransactionModel(
      id: id,
      userId: model.userId,
      merchantName: model.merchantName,
      totalAmount: model.totalAmount,
      categoryId: model.categoryId,
      dayOfMonth: model.dayOfMonth,
      startMonth: model.startMonth,
      lastGenerated: model.lastGenerated,
      isActive: model.isActive,
      notes: model.notes,
      createdAt: model.createdAt,
    );
  }

  Future<void> setActive(int id, bool isActive) async {
    final Database db = await _db;
    await db.update(
      DbTables.recurringTransactions,
      <String, Object?>{RecurringCols.isActive: isActive ? 1 : 0},
      where: '${RecurringCols.id} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> setLastGenerated(int id, String monthKey) async {
    final Database db = await _db;
    await db.update(
      DbTables.recurringTransactions,
      <String, Object?>{RecurringCols.lastGenerated: monthKey},
      where: '${RecurringCols.id} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> delete(int id) async {
    final Database db = await _db;
    await db.delete(
      DbTables.recurringTransactions,
      where: '${RecurringCols.id} = ?',
      whereArgs: <Object?>[id],
    );
  }
}
