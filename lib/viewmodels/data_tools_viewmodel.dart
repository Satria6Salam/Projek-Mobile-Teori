import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/database/app_database.dart';
import '../services/export_service.dart';
import 'auth_viewmodel.dart';
import 'safe_change_notifier.dart';

/// Ekspor laporan CSV, cadangan, dan pemulihan basis data.
class DataToolsViewModel extends ChangeNotifier with SafeChangeNotifier {
  DataToolsViewModel({
    required AuthViewModel authViewModel,
    required ExportService exportService,
    AppDatabase? database,
  })  : _auth = authViewModel,
        _export = exportService,
        _database = database ?? AppDatabase.instance;

  final AuthViewModel _auth;
  final ExportService _export;
  final AppDatabase _database;

  bool _isBusy = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> exportMonth(DateTime month) async {
    final int? userId = _auth.currentUser?.id;
    if (userId == null || _isBusy) return;
    await _guard(() async {
      final File file = await _export.exportMonthCsv(userId, month);
      await _export.share(file, subject: 'Laporan SmartReceipt');
    }, errorText: 'Gagal membuat laporan.');
  }

  Future<void> createBackup() async {
    if (_isBusy) return;
    await _guard(() async {
      final File file = await _export.createBackup();
      await _export.share(file, subject: 'Cadangan SmartReceipt');
    }, errorText: 'Gagal membuat cadangan.');
  }

  /// Memilih berkas cadangan. Null bila dibatalkan atau gagal.
  Future<String?> pickBackup() async {
    try {
      return await _export.pickBackupFile();
    } catch (_) {
      _errorMessage = 'Tidak dapat membuka pemilih berkas.';
      safeNotify();
      return null;
    }
  }

  /// Memulihkan dari berkas cadangan. Data sekarang diganti seluruhnya, lalu
  /// pengguna keluar agar sesi cocok dengan data yang baru.
  Future<bool> restoreFrom(String path) async {
    if (_isBusy) return false;
    final File file = File(path);
    _isBusy = true;
    _errorMessage = null;
    _successMessage = null;
    safeNotify();
    try {
      if (!await _database.isCompatibleBackup(file)) {
        _errorMessage = 'Berkas ini bukan cadangan SmartReceipt yang valid.';
        return false;
      }
      await _database.replaceWith(file);
      await _auth.logout();
      return true;
    } catch (_) {
      _errorMessage = 'Gagal memulihkan data. Data lama tetap aman.';
      return false;
    } finally {
      _isBusy = false;
      safeNotify();
    }
  }

  Future<void> _guard(
    Future<void> Function() action, {
    required String errorText,
  }) async {
    _isBusy = true;
    _errorMessage = null;
    _successMessage = null;
    safeNotify();
    try {
      await action();
    } catch (_) {
      _errorMessage = errorText;
    } finally {
      _isBusy = false;
      safeNotify();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    safeNotify();
  }
}
