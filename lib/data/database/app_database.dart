import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/db_constants.dart';
import '../../core/utils/db_date_utils.dart';
import 'database_schema.dart';

/// Pengelola koneksi SQLite (singleton).
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Future<Database>? _opening;

  /// Mengembalikan koneksi database; dibuka satu kali saja walau dipanggil bersamaan.
  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = p.join(directory.path, DbConstants.databaseName);

    return openDatabase(
      path,
      version: DbConstants.databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Mengaktifkan penegakan foreign key (nonaktif secara default di SQLite).
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Migrasi skema; data pengguna lama tetap aman.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      for (final String statement in DatabaseSchema.upgradeToV2) {
        await db.execute(statement);
      }
    }
    if (oldVersion < 4) {
      // Versi 4: menambahkan kategori baru (kategori yang sudah ada dilewati).
      final String now = DbDateUtils.dateTimeToDb(DateTime.now());
      for (final Map<String, String> category
          in DatabaseSchema.defaultCategories) {
        await db.insert(
          DbTables.categories,
          <String, Object?>{
            CategoryCols.name: category['name'],
            CategoryCols.description: category['description'],
            CategoryCols.createdAt: now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
    if (oldVersion < 3) {
      // Versi 3: menambahkan kategori Elektronik (dilewati bila sudah ada).
      await db.insert(
        DbTables.categories,
        <String, Object?>{
          CategoryCols.name: 'Elektronik',
          CategoryCols.description:
              'Perangkat, komponen, dan aksesori elektronik',
          CategoryCols.createdAt: DbDateUtils.dateTimeToDb(DateTime.now()),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    if (oldVersion < 5) {
      await _upgradeToV5(db);
    }
    if (oldVersion < 6) {
      for (final String statement in DatabaseSchema.upgradeToV6) {
        await db.execute(statement);
      }
    }
  }

  /// Versi 5: kolom kustomisasi kategori serta tabel anggaran dan transaksi berulang.
  Future<void> _upgradeToV5(Database db) async {
    for (final String statement in DatabaseSchema.upgradeToV5) {
      await db.execute(statement);
    }
  }

  /// Lokasi file database pada perangkat (dipakai untuk cadangan).
  Future<String> get databasePath async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, DbConstants.databaseName);
  }

  /// Memeriksa file cadangan: harus basis data SmartReceipt dengan versi
  /// yang bisa dibaca aplikasi ini.
  Future<bool> isCompatibleBackup(File file) async {
    Database? candidate;
    try {
      candidate = await openDatabase(file.path, readOnly: true);
      final int version = await candidate.getVersion();
      if (version < 1 || version > DbConstants.databaseVersion) return false;
      final List<Map<String, Object?>> rows = await candidate.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name IN ('users', 'transactions')",
      );
      return rows.length == 2;
    } catch (_) {
      return false;
    } finally {
      await candidate?.close();
    }
  }

  /// Mengganti isi database dengan file cadangan. Koneksi lama ditutup dulu
  /// dan dibuka kembali pada akses berikutnya.
  Future<void> replaceWith(File source) async {
    final Database db = await database;
    await db.close();
    _opening = null;
    await source.copy(await databasePath);
  }

  Future<void> _onCreate(Database db, int version) async {
    final Batch batch = db.batch();
    for (final String statement in DatabaseSchema.createStatements) {
      batch.execute(statement);
    }
    for (final String statement in DatabaseSchema.createIndexes) {
      batch.execute(statement);
    }
    await batch.commit(noResult: true);

    // Data awal kategori pengeluaran.
    final String now = DbDateUtils.dateTimeToDb(DateTime.now());
    for (final Map<String, String> category
        in DatabaseSchema.defaultCategories) {
      await db.insert(DbTables.categories, <String, Object?>{
        CategoryCols.name: category['name'],
        CategoryCols.description: category['description'],
        CategoryCols.createdAt: now,
      });
    }
  }

  Future<void> close() async {
    final Future<Database>? opening = _opening;
    if (opening == null) return;
    final Database db = await opening;
    await db.close();
    _opening = null;
  }
}
