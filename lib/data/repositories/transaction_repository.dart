import 'package:sqflite/sqflite.dart';

import '../../core/constants/db_constants.dart';
import '../../core/utils/db_date_utils.dart';
import '../database/app_database.dart';
import '../models/category_summary_model.dart';
import '../models/ml_classification_model.dart';
import '../models/ocr_result_model.dart';
import '../models/parsed_receipt_model.dart';
import '../models/tfidf_feature_model.dart';
import '../models/transaction_item_model.dart';
import '../models/transaction_model.dart';
import 'repository_exception.dart';

/// Akses data transaksi final serta ringkasan untuk Dasbor Keuangan (UC-04).
class TransactionRepository {
  TransactionRepository({AppDatabase? database})
      : _appDatabase = database ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  static const String _joinedSelect = '''
SELECT t.*, c.${CategoryCols.name} AS ${CategoryCols.name}
FROM ${DbTables.transactions} t
INNER JOIN ${DbTables.categories} c ON c.${CategoryCols.id} = t.${TransCols.categoryId}
''';

  /// Batas awal (inklusif) dan akhir (eksklusif) sebuah rentang dalam format yyyy-MM-dd.
  (String, String) _range(DateTime start, DateTime endExclusive) {
    return (
      DbDateUtils.dateToDb(start),
      DbDateUtils.dateToDb(endExclusive),
    );
  }

  /// Menyimpan seluruh hasil pemindaian (OCR, parsing, klasifikasi, fitur TF-IDF)
  /// beserta transaksi final dalam SATU transaksi database.
  /// Dipanggil hanya saat pengguna menekan "Simpan"; jika dibatalkan, tidak ada data tersimpan.
  Future<TransactionModel> saveScanTransaction({
    required OcrResultModel ocr,
    required ParsedReceiptModel parsed,
    required MlClassificationModel classification,
    required List<TfidfFeatureModel> features,
    required TransactionModel transaction,
    List<TransactionItemModel> items = const <TransactionItemModel>[],
  }) async {
    final Database db = await _db;
    return db.transaction((Transaction txn) async {
      final int ocrId = await txn.insert(DbTables.ocrResults, ocr.toMap());

      final int parsedId = await txn.insert(
        DbTables.parsedReceipts,
        parsed.copyWith(ocrId: ocrId).toMap(),
      );

      final int classificationId = await txn.insert(
        DbTables.mlClassifications,
        classification.copyWith(parsedId: parsedId).toMap(),
      );

      for (final TfidfFeatureModel feature in features) {
        await txn.insert(
          DbTables.tfidfFeatures,
          feature.copyWith(classificationId: classificationId).toMap(),
        );
      }

      final TransactionModel complete = transaction.copyWith(
        ocrId: ocrId,
        parsedId: parsedId,
        classificationId: classificationId,
      );
      final int transactionId = await txn.insert(
        DbTables.transactions,
        complete.toMap(),
      );
      for (final TransactionItemModel item in items) {
        await txn.insert(
          DbTables.transactionItems,
          item.copyWith(transactionId: transactionId).toMap(),
        );
      }
      return complete.copyWith(id: transactionId);
    });
  }

  /// Menyimpan transaksi tanpa jejak OCR/AI (misalnya input manual).
  Future<TransactionModel> insert(TransactionModel transaction) async {
    final Database db = await _db;
    final int id = await db.insert(DbTables.transactions, transaction.toMap());
    return transaction.copyWith(id: id);
  }

  Future<TransactionModel?> getById(int id) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '$_joinedSelect WHERE t.${TransCols.id} = ? LIMIT 1',
      <Object?>[id],
    );
    return rows.isEmpty ? null : TransactionModel.fromMap(rows.first);
  }

  /// Riwayat transaksi terbaru lebih dulu.
  Future<List<TransactionModel>> getByUser(
    int userId, {
    int? limit,
    int? offset,
  }) async {
    final Database db = await _db;
    final StringBuffer sql = StringBuffer(_joinedSelect)
      ..write('WHERE t.${TransCols.userId} = ? ')
      ..write(
        'ORDER BY t.${TransCols.transactionDate} DESC, t.${TransCols.id} DESC',
      );
    final List<Object?> args = <Object?>[userId];
    if (limit != null) {
      sql.write(' LIMIT ?');
      args.add(limit);
      if (offset != null) {
        sql.write(' OFFSET ?');
        args.add(offset);
      }
    }
    final List<Map<String, Object?>> rows =
        await db.rawQuery(sql.toString(), args);
    return rows.map(TransactionModel.fromMap).toList();
  }

  /// Transaksi pada rentang [start, endExclusive), terbaru lebih dulu.
  Future<List<TransactionModel>> getBetween(
    int userId,
    DateTime start,
    DateTime endExclusive,
  ) async {
    final Database db = await _db;
    final (String from, String to) = _range(start, endExclusive);
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '$_joinedSelect '
      'WHERE t.${TransCols.userId} = ? '
      'AND t.${TransCols.transactionDate} >= ? '
      'AND t.${TransCols.transactionDate} < ? '
      'ORDER BY t.${TransCols.transactionDate} DESC, t.${TransCols.id} DESC',
      <Object?>[userId, from, to],
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<List<TransactionModel>> getByMonth(
    int userId,
    int year,
    int month,
  ) {
    return getBetween(userId, DateTime(year, month), DateTime(year, month + 1));
  }

  Future<bool> update(TransactionModel transaction) async {
    final int? id = transaction.id;
    if (id == null) {
      throw const RepositoryException('ID transaksi tidak ditemukan');
    }
    final Database db = await _db;
    final Map<String, Object?> values = Map<String, Object?>.of(
      transaction.copyWith(updatedAt: DateTime.now()).toMap(),
    )..remove(TransCols.id);
    final int count = await db.update(
      DbTables.transactions,
      values,
      where: '${TransCols.id} = ?',
      whereArgs: <Object?>[id],
    );
    return count > 0;
  }

  /// Menghapus transaksi beserta jejak OCR/parsing/klasifikasi/TF-IDF miliknya.
  Future<bool> delete(int id) async {
    final Database db = await _db;
    return db.transaction((Transaction txn) async {
      final List<Map<String, Object?>> rows = await txn.query(
        DbTables.transactions,
        columns: <String>[TransCols.ocrId],
        where: '${TransCols.id} = ?',
        whereArgs: <Object?>[id],
        limit: 1,
      );
      if (rows.isEmpty) return false;
      final int? ocrId = rows.first[TransCols.ocrId] as int?;

      await txn.delete(
        DbTables.transactions,
        where: '${TransCols.id} = ?',
        whereArgs: <Object?>[id],
      );
      if (ocrId != null) {
        // Cascade ke parsed_receipts, ml_classifications, dan tfidf_features.
        await txn.delete(
          DbTables.ocrResults,
          where: '${OcrCols.id} = ?',
          whereArgs: <Object?>[ocrId],
        );
      }
      return true;
    });
  }

  /// Total pengeluaran pada rentang [start, endExclusive).
  Future<double> getTotalBetween(
    int userId,
    DateTime start,
    DateTime endExclusive,
  ) async {
    final Database db = await _db;
    final (String from, String to) = _range(start, endExclusive);
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COALESCE(SUM(${TransCols.totalAmount}), 0) AS total '
      'FROM ${DbTables.transactions} '
      'WHERE ${TransCols.userId} = ? '
      'AND ${TransCols.transactionDate} >= ? '
      'AND ${TransCols.transactionDate} < ?',
      <Object?>[userId, from, to],
    );
    if (rows.isEmpty) return 0.0;
    return (rows.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Total pengeluaran pada bulan tertentu.
  Future<double> getMonthlyTotal(int userId, int year, int month) {
    return getTotalBetween(
        userId, DateTime(year, month), DateTime(year, month + 1));
  }

  /// Total pengeluaran per bulan (indeks 0 = Januari) pada satu tahun.
  Future<List<double>> getMonthlyTotals(int userId, int year) async {
    final Database db = await _db;
    final (String from, String to) = _range(DateTime(year), DateTime(year + 1));
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT substr(${TransCols.transactionDate}, 6, 2) AS month_key, '
      'SUM(${TransCols.totalAmount}) AS total '
      'FROM ${DbTables.transactions} '
      'WHERE ${TransCols.userId} = ? '
      'AND ${TransCols.transactionDate} >= ? '
      'AND ${TransCols.transactionDate} < ? '
      'GROUP BY month_key',
      <Object?>[userId, from, to],
    );
    final List<double> result = List<double>.filled(12, 0);
    for (final Map<String, Object?> row in rows) {
      final int? month = int.tryParse(row['month_key'] as String? ?? '');
      if (month != null && month >= 1 && month <= 12) {
        result[month - 1] = (row['total'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return result;
  }

  /// Total pengeluaran per tahun (urut dari tahun terlama).
  Future<Map<int, double>> getYearlyTotals(int userId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT substr(${TransCols.transactionDate}, 1, 4) AS year_key, '
      'SUM(${TransCols.totalAmount}) AS total '
      'FROM ${DbTables.transactions} '
      'WHERE ${TransCols.userId} = ? '
      'GROUP BY year_key ORDER BY year_key ASC',
      <Object?>[userId],
    );
    final Map<int, double> result = <int, double>{};
    for (final Map<String, Object?> row in rows) {
      final int? year = int.tryParse(row['year_key'] as String? ?? '');
      if (year != null) {
        result[year] = (row['total'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return result;
  }

  /// Total pengeluaran per kategori pada rentang waktu (terbesar lebih dulu).
  /// Dihitung dari rincian barang; transaksi lama tanpa rincian memakai
  /// kategori transaksinya.
  Future<List<CategorySummaryModel>> getCategorySummaryBetween(
    int userId,
    DateTime start,
    DateTime endExclusive,
  ) async {
    final Database db = await _db;
    final (String from, String to) = _range(start, endExclusive);
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT c.${CategoryCols.id} AS category_id, '
      'c.${CategoryCols.name} AS category_name, '
      'SUM(x.amount) AS total_amount, '
      'COUNT(DISTINCT x.tid) AS transaction_count '
      'FROM ('
      'SELECT i.${ItemCols.categoryId} AS cid, i.${ItemCols.totalPrice} AS amount, '
      'i.${ItemCols.transactionId} AS tid '
      'FROM ${DbTables.transactionItems} i '
      'INNER JOIN ${DbTables.transactions} t ON t.${TransCols.id} = i.${ItemCols.transactionId} '
      'WHERE t.${TransCols.userId} = ? '
      'AND t.${TransCols.transactionDate} >= ? '
      'AND t.${TransCols.transactionDate} < ? '
      'UNION ALL '
      'SELECT t.${TransCols.categoryId} AS cid, t.${TransCols.totalAmount} AS amount, '
      't.${TransCols.id} AS tid '
      'FROM ${DbTables.transactions} t '
      'WHERE t.${TransCols.userId} = ? '
      'AND t.${TransCols.transactionDate} >= ? '
      'AND t.${TransCols.transactionDate} < ? '
      'AND NOT EXISTS (SELECT 1 FROM ${DbTables.transactionItems} i2 '
      'WHERE i2.${ItemCols.transactionId} = t.${TransCols.id})'
      ') x '
      'INNER JOIN ${DbTables.categories} c ON c.${CategoryCols.id} = x.cid '
      'GROUP BY c.${CategoryCols.id}, c.${CategoryCols.name} '
      'ORDER BY total_amount DESC',
      <Object?>[userId, from, to, userId, from, to],
    );
    return rows.map(CategorySummaryModel.fromMap).toList();
  }

  /// Total pengeluaran per kategori pada bulan tertentu.
  Future<List<CategorySummaryModel>> getCategorySummary(
    int userId,
    int year,
    int month,
  ) {
    return getCategorySummaryBetween(
      userId,
      DateTime(year, month),
      DateTime(year, month + 1),
    );
  }

  /// Rincian barang sebuah transaksi (urut sesuai input).
  Future<List<TransactionItemModel>> getItems(int transactionId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT i.*, c.${CategoryCols.name} AS ${CategoryCols.name} '
      'FROM ${DbTables.transactionItems} i '
      'INNER JOIN ${DbTables.categories} c ON c.${CategoryCols.id} = i.${ItemCols.categoryId} '
      'WHERE i.${ItemCols.transactionId} = ? '
      'ORDER BY i.${ItemCols.id} ASC',
      <Object?>[transactionId],
    );
    return rows.map(TransactionItemModel.fromMap).toList();
  }

  /// Barang yang sudah divalidasi pengguna; dipakai melatih ulang model AI.
  Future<List<LabeledItem>> getTrainingSamples(int userId,
      {int limit = 2000}) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT i.${ItemCols.name} AS item_name, c.${CategoryCols.name} AS category_name '
      'FROM ${DbTables.transactionItems} i '
      'INNER JOIN ${DbTables.transactions} t ON t.${TransCols.id} = i.${ItemCols.transactionId} '
      'INNER JOIN ${DbTables.categories} c ON c.${CategoryCols.id} = i.${ItemCols.categoryId} '
      'WHERE t.${TransCols.userId} = ? '
      'ORDER BY i.${ItemCols.id} DESC LIMIT ?',
      <Object?>[userId, limit],
    );
    return rows
        .map(
          (Map<String, Object?> r) => LabeledItem(
            name: r['item_name'] as String? ?? '',
            categoryName: r['category_name'] as String? ?? '',
          ),
        )
        .where((LabeledItem l) => l.name.trim().isNotEmpty)
        .toList();
  }
}
