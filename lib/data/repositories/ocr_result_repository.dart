import 'package:sqflite/sqflite.dart';

import '../../core/constants/db_constants.dart';
import '../database/app_database.dart';
import '../models/ocr_result_model.dart';

/// Akses data hasil OCR (UC-02).
class OcrResultRepository {
  OcrResultRepository({AppDatabase? database})
      : _appDatabase = database ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  Future<OcrResultModel> insert(OcrResultModel result) async {
    final Database db = await _db;
    final int id = await db.insert(DbTables.ocrResults, result.toMap());
    return result.copyWith(id: id);
  }

  Future<OcrResultModel?> getById(int id) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      DbTables.ocrResults,
      where: '${OcrCols.id} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : OcrResultModel.fromMap(rows.first);
  }

  Future<List<OcrResultModel>> getByUser(int userId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      DbTables.ocrResults,
      where: '${OcrCols.userId} = ?',
      whereArgs: <Object?>[userId],
      orderBy: '${OcrCols.createdAt} DESC',
    );
    return rows.map(OcrResultModel.fromMap).toList();
  }

  /// Menghapus hasil OCR beserta hasil parsing, klasifikasi, dan fitur TF-IDF (cascade).
  Future<bool> delete(int id) async {
    final Database db = await _db;
    final int count = await db.delete(
      DbTables.ocrResults,
      where: '${OcrCols.id} = ?',
      whereArgs: <Object?>[id],
    );
    return count > 0;
  }
}
