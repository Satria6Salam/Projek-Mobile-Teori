import 'package:flutter/foundation.dart';

import '../data/models/shopping_plan_model.dart';
import '../data/repositories/shopping_plan_repository.dart';
import 'auth_viewmodel.dart';
import 'safe_change_notifier.dart';

/// Layar Rencana Belanja: daftar barang yang akan dibeli dan rekapnya.
class ShoppingPlanViewModel extends ChangeNotifier with SafeChangeNotifier {
  ShoppingPlanViewModel({
    required AuthViewModel authViewModel,
    required ShoppingPlanRepository repository,
    DateTime Function()? clock,
  })  : _auth = authViewModel,
        _repository = repository,
        _clock = clock ?? DateTime.now;

  static const int maxNameLength = 60;

  final AuthViewModel _auth;
  final ShoppingPlanRepository _repository;
  final DateTime Function() _clock;

  List<ShoppingPlanModel> _all = <ShoppingPlanModel>[];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Barang yang masih harus dibeli (tampil di daftar rencana).
  List<ShoppingPlanModel> get pending =>
      _all.where((ShoppingPlanModel p) => !p.isBought).toList();

  /// Barang yang sudah dibeli, terbaru di atas (tampil di rekap).
  List<ShoppingPlanModel> get bought {
    final List<ShoppingPlanModel> list =
        _all.where((ShoppingPlanModel p) => p.isBought).toList();
    list.sort((ShoppingPlanModel a, ShoppingPlanModel b) =>
        (b.boughtAt ?? b.createdAt).compareTo(a.boughtAt ?? a.createdAt));
    return list;
  }

  int get totalCount => _all.length;

  /// Porsi barang rencana yang sudah dibeli (0..1).
  double get progress => _all.isEmpty ? 0 : bought.length / _all.length;

  /// Jumlah uang untuk barang rencana yang sudah dibeli (harga dari struk).
  double get spentOnPlan => bought.fold<double>(
        0,
        (double sum, ShoppingPlanModel p) => sum + (p.boughtPrice ?? 0),
      );

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  Future<void> load() async {
    final int? userId = _auth.currentUser?.id;
    if (userId == null) return;
    _isLoading = true;
    safeNotify();
    try {
      _all = await _repository.getAll(userId);
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Gagal memuat rencana belanja.';
    }
    _isLoading = false;
    safeNotify();
  }

  /// Memvalidasi nama barang; null berarti valid.
  static String? validateName(String raw) {
    final String name = raw.trim();
    if (name.isEmpty) return 'Nama barang wajib diisi.';
    if (!RegExp(r'[A-Za-z]').hasMatch(name)) {
      return 'Nama barang harus mengandung huruf.';
    }
    if (name.length > maxNameLength) {
      return 'Nama barang maksimal $maxNameLength karakter.';
    }
    return null;
  }

  Future<bool> add(String rawName, {double quantity = 1, String? note}) async {
    final int? userId = _auth.currentUser?.id;
    if (userId == null) return false;
    final String? invalid = validateName(rawName);
    if (invalid != null) {
      _errorMessage = invalid;
      _successMessage = null;
      safeNotify();
      return false;
    }
    final String name = rawName.trim();
    final bool duplicate = pending.any(
      (ShoppingPlanModel p) => p.name.toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      _errorMessage = '"$name" sudah ada di rencana.';
      _successMessage = null;
      safeNotify();
      return false;
    }
    final String trimmedNote = note?.trim() ?? '';
    return _run(
      () => _repository.insert(ShoppingPlanModel(
        userId: userId,
        name: name,
        quantity: quantity < 1 ? 1 : quantity,
        note: trimmedNote.isEmpty ? null : trimmedNote,
        createdAt: _clock(),
      )),
      success: '"$name" ditambahkan ke rencana.',
    );
  }

  /// Menandai sudah dibeli secara manual (tanpa struk), atau sebaliknya.
  Future<bool> setBought(ShoppingPlanModel plan, bool bought) {
    final ShoppingPlanModel updated =
        bought ? plan.markBought(at: _clock()) : plan.markPending();
    return _run(
      () => _repository.update(updated),
      success: bought
          ? '"${plan.name}" ditandai sudah dibeli.'
          : '"${plan.name}" dikembalikan ke rencana.',
    );
  }

  Future<bool> delete(ShoppingPlanModel plan) {
    final int? id = plan.id;
    if (id == null) return Future<bool>.value(false);
    return _run(
      () => _repository.delete(id),
      success: '"${plan.name}" dihapus dari rencana.',
    );
  }

  /// Menghapus semua barang yang sudah dibeli dari rekap.
  Future<bool> clearBought() async {
    final int? userId = _auth.currentUser?.id;
    if (userId == null) return false;
    return _run(
      () => _repository.deleteBought(userId),
      success: 'Riwayat barang yang sudah dibeli dibersihkan.',
    );
  }

  Future<bool> _run(Future<Object?> Function() action,
      {required String success}) async {
    try {
      await action();
      _successMessage = success;
      _errorMessage = null;
      await load();
      return true;
    } catch (_) {
      _errorMessage = 'Gagal menyimpan perubahan. Silakan coba lagi.';
      _successMessage = null;
      safeNotify();
      return false;
    }
  }
}
