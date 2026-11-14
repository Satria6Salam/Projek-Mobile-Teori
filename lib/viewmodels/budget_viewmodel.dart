import 'package:flutter/foundation.dart';

import '../core/utils/month_utils.dart';
import '../data/repositories/budget_repository.dart';
import '../services/budget_service.dart';
import 'auth_viewmodel.dart';
import 'safe_change_notifier.dart';

/// Layar Anggaran: batas bulanan total dan per kategori, serta sisa anggaran.
class BudgetViewModel extends ChangeNotifier with SafeChangeNotifier {
  BudgetViewModel({
    required AuthViewModel authViewModel,
    required BudgetRepository budgetRepository,
    required BudgetService budgetService,
  })  : _auth = authViewModel,
        _budgetRepository = budgetRepository,
        _budgetService = budgetService;

  final AuthViewModel _auth;
  final BudgetRepository _budgetRepository;
  final BudgetService _budgetService;

  DateTime _month = MonthUtils.startOf(DateTime.now());
  BudgetSnapshot? _snapshot;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  DateTime get month => _month;
  BudgetSnapshot? get snapshot => _snapshot;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Bulan berjalan adalah batas maksimal; bulan depan tidak perlu dilihat.
  bool get canGoForward {
    final DateTime now = DateTime.now();
    return _month.isBefore(DateTime(now.year, now.month));
  }

  Future<void> load() async {
    final int? userId = _auth.currentUser?.id;
    if (userId == null) return;
    _isLoading = true;
    _errorMessage = null;
    safeNotify();
    try {
      _snapshot = await _budgetService.snapshot(userId, _month);
    } catch (_) {
      _errorMessage = 'Gagal memuat anggaran. Silakan coba lagi.';
    }
    _isLoading = false;
    safeNotify();
  }

  Future<void> changeMonth(int delta) async {
    if (delta > 0 && !canGoForward) return;
    _month = DateTime(_month.year, _month.month + delta);
    await load();
  }

  /// Menyimpan batas. [categoryId] null berarti batas total.
  Future<bool> saveLimit({int? categoryId, required double amount}) async {
    final int? userId = _auth.currentUser?.id;
    if (userId == null || _isSaving) return false;
    if (amount <= 0) {
      _errorMessage = 'Batas harus lebih dari Rp 0.';
      _successMessage = null;
      safeNotify();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    safeNotify();
    try {
      await _budgetRepository.upsert(
        userId: userId,
        categoryId: categoryId,
        amount: amount,
      );
      _successMessage = 'Batas anggaran disimpan.';
      await _budgetService.checkAndNotify(userId);
      _isSaving = false;
      await load();
      return true;
    } catch (_) {
      _errorMessage = 'Gagal menyimpan batas. Silakan coba lagi.';
      _isSaving = false;
      safeNotify();
      return false;
    }
  }

  Future<void> removeLimit({int? categoryId}) async {
    final int? userId = _auth.currentUser?.id;
    if (userId == null) return;
    await _budgetRepository.delete(userId: userId, categoryId: categoryId);
    _successMessage = 'Batas anggaran dihapus.';
    await load();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    safeNotify();
  }
}
