import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/utils/month_utils.dart';
import '../data/database/app_database.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/transaction_repository.dart';

/// Ekspor laporan bulanan (CSV), cadangan basis data, dan pemulihan.
class ExportService {
  ExportService({
    required TransactionRepository transactions,
    AppDatabase? database,
  })  : _transactions = transactions,
        _database = database ?? AppDatabase.instance;

  final TransactionRepository _transactions;
  final AppDatabase _database;

  static const List<String> _header = <String>[
    'Tanggal',
    'Merchant',
    'Kategori',
    'Total (Rp)',
    'Sumber',
    'Catatan',
  ];

  /// Membuat berkas CSV untuk satu bulan. Berkas dibuat dengan BOM UTF-8
  /// agar Excel menampilkan huruf Indonesia dengan benar.
  Future<File> exportMonthCsv(int userId, DateTime month) async {
    final List<TransactionModel> items = await _transactions.getBetween(
      userId,
      MonthUtils.startOf(month),
      MonthUtils.endExclusive(month),
    );
    final List<TransactionModel> sorted = List<TransactionModel>.of(items)
      ..sort((TransactionModel a, TransactionModel b) =>
          a.transactionDate.compareTo(b.transactionDate));

    final StringBuffer buffer = StringBuffer()..writeln(_line(_header));
    double total = 0;
    for (final TransactionModel item in sorted) {
      total += item.totalAmount;
      buffer.writeln(_line(<String>[
        _dateOnly(item.transactionDate),
        item.merchantName,
        item.categoryName ?? '',
        item.totalAmount.toStringAsFixed(0),
        item.isManualEdit ? 'Manual' : 'Struk',
        item.notes ?? '',
      ]));
    }
    buffer.writeln(_line(<String>[
      'TOTAL',
      '',
      '',
      total.toStringAsFixed(0),
      '',
      '',
    ]));

    final String key = MonthUtils.key(month);
    final File file = File(p.join(await _tempDir(), 'laporan_$key.csv'));
    await file.writeAsString('﻿${buffer.toString()}', encoding: utf8);
    return file;
  }

  /// Menyalin basis data ke folder sementara untuk dibagikan.
  Future<File> createBackup() async {
    final DateTime now = DateTime.now();
    final String stamp =
        '${now.year}${_two(now.month)}${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}';
    final File source = File(await _database.databasePath);
    return source
        .copy(p.join(await _tempDir(), 'smartreceipt_backup_$stamp.db'));
  }

  /// Memilih berkas cadangan dari penyimpanan. Null bila dibatalkan.
  Future<String?> pickBackupFile() async {
    final PlatformFile? file = await FilePicker.pickFile(type: FileType.any);
    return file?.path;
  }

  Future<void> share(File file, {required String subject}) {
    return SharePlus.instance
        .share(ShareParams(files: <XFile>[XFile(file.path)], subject: subject))
        .then((_) {});
  }

  static String _line(List<String> cells) =>
      cells.map((String c) => '"${c.replaceAll('"', '""')}"').join(',');

  static String _dateOnly(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  static String _two(int value) => value.toString().padLeft(2, '0');

  Future<String> _tempDir() async {
    final Directory dir = await getTemporaryDirectory();
    return dir.path;
  }
}
