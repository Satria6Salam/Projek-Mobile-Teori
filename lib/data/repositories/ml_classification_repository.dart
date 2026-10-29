import 'package:sqflite/sqflite.dart';

import '../../core/constants/db_constants.dart';
import '../database/app_database.dart';
import '../models/ml_classification_model.dart';
import '../models/tfidf_feature_model.dart';

/// Akses data hasil klasifikasi TF-IDF + Naive Bayes beserta detail bobot term.
class MlClassificationRepository {
  MlClassificationRepository({AppDatabase? database})
      : _appDatabase = database ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  /// Menyimpan klasifikasi dan fitur TF-IDF-nya secara atomik.
  Future<MlClassificationModel> insert(
    MlClassificationModel classification,
    List<TfidfFeatureModel> features,
  ) async {
    final Database db = await _db;
    return db.transaction((Transaction txn) async {
      final int id = await txn.insert(
        DbTables.mlClassifications,
        classification.toMap(),
      );
      for (final TfidfFeatureModel feature in features) {
        await txn.insert(
          DbTables.tfidfFeatures,
          feature.copyWith(classificationId: id).toMap(),
        );
      }
      return classification.copyWith(id: id);
    });
  }

  Future<MlClassificationModel?> getById(int id) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      DbTables.mlClassifications,
      where: '${ClassCols.id} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : MlClassificationModel.fromMap(rows.first);
  }

  Future<MlClassificationModel?> getByParsedId(int parsedId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      DbTables.mlClassifications,
      where: '${ClassCols.parsedId} = ?',
      whereArgs: <Object?>[parsedId],
      limit: 1,
    );
    return rows.isEmpty ? null : MlClassificationModel.fromMap(rows.first);
  }

  Future<List<TfidfFeatureModel>> getFeatures(int classificationId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      DbTables.tfidfFeatures,
      where: '${TfidfCols.classificationId} = ?',
      whereArgs: <Object?>[classificationId],
      orderBy: '${TfidfCols.weight} DESC',
    );
    return rows.map(TfidfFeatureModel.fromMap).toList();
  }

  /// Menghapus klasifikasi beserta fitur TF-IDF-nya (cascade).
  Future<bool> delete(int id) async {
    final Database db = await _db;
    final int count = await db.delete(
      DbTables.mlClassifications,
      where: '${ClassCols.id} = ?',
      whereArgs: <Object?>[id],
    );
    return count > 0;
  }
}
