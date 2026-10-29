import 'package:sqflite/sqflite.dart';

import '../../core/constants/db_constants.dart';
import '../database/app_database.dart';
import '../models/parsed_receipt_model.dart';
import 'repository_exception.dart';

/// Akses data hasil Smart Parsing (UC-03).
class ParsedReceiptRepository {
  ParsedReceiptRepository({AppDatabase? database})
      : _appDatabase = database ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  Future<ParsedReceiptModel> insert(ParsedReceiptModel parsed) async {
    final Database db = await _db;
    final int id = await db.insert(DbTables.parsedReceipts, parsed.toMap());
    return parsed.copyWith(id: id);
  }

  Future<ParsedReceiptModel?> getById(int id) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      DbTables.parsedReceipts,
      where: '${ParsedCols.id} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : ParsedReceiptModel.fromMap(rows.first);
  }

  Future<ParsedReceiptModel?> getByOcrId(int ocrId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      DbTables.parsedReceipts,
      where: '${ParsedCols.ocrId} = ?',
      whereArgs: <Object?>[ocrId],
      limit: 1,
    );
    return rows.isEmpty ? null : ParsedReceiptModel.fromMap(rows.first);
  }

  Future<bool> update(ParsedReceiptModel parsed) async {
    final int? id = parsed.id;
    if (id == null) {
      throw const RepositoryException('ID hasil parsing tidak ditemukan');
    }
    final Database db = await _db;
    final Map<String, Object?> values =
        Map<String, Object?>.of(parsed.toMap())..remove(ParsedCols.id);
    final int count = await db.update(
      DbTables.parsedReceipts,
      values,
      where: '${ParsedCols.id} = ?',
      whereArgs: <Object?>[id],
    );
    return count > 0;
  }

  Future<bool> delete(int id) async {
    final Database db = await _db;
    final int count = await db.delete(
      DbTables.parsedReceipts,
      where: '${ParsedCols.id} = ?',
      whereArgs: <Object?>[id],
    );
    return count > 0;
  }
}
