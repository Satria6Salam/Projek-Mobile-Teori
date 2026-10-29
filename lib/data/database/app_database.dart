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
