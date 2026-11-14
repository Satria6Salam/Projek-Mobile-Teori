import 'package:flutter/foundation.dart';

import '../core/utils/month_utils.dart';
import '../data/models/category_model.dart';
import '../data/models/recurring_transaction_model.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/recurring_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../services/budget_service.dart';
import 'auth_viewmodel.dart';
import 'safe_change_notifier.dart';

/// Pencatatan manual (jajan tanpa struk, parkir) dan transaksi berulang
/// (langganan bulanan seperti internet atau Netflix).
class ManualEntryViewModel extends ChangeNotifier with SafeChangeNotifier {
  ManualEntryViewModel({
    required AuthViewModel authViewModel,
    required TransactionRepository transactionRepository,
    required CategoryRepository categoryRepository,
    required RecurringRepository recurringRepository,
    required BudgetService budgetService,
  })  : _auth = authViewModel,
        _transactions = transactionRepository,
        _categoryRepository = categoryRepository,
        _recurring = recurringRepository,
        _budgetService = budgetService;

  final AuthViewModel _auth;
  final TransactionRepository _transactions;
  final CategoryRepository _categoryRepository;
  final RecurringRepository _recurring;
  final BudgetService _budgetService;

  static const int maxAmount = 100000000;

  List<CategoryModel> _categories = <CategoryModel>[];
  List<RecurringTransactionModel> _recurringItems =
      <RecurringTransactionModel>[];
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  List<CategoryModel> get categories => _categories;
  List<RecurringTransactionModel> get recurringItems => _recurringItems;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> load() async {
    final int? userId = _auth.currentUser?.id;
    final List<CategoryModel> all = await _categoryRepository.getAll();
    _categories = all.where((CategoryModel c) => !c.isHidden).toList();
    _recurringItems = userId == null ? [] : await _recurring.getAll(userId);
    safeNotify();
  }

  /// Nama kategori untuk tampilan daftar berulang.
  String categoryNameOf(int id) {
    for (final CategoryModel c in _categories) {
      if (c.id == id) return c.name;
    }
    return 'Kategori';
  }

  /// Menyimpan transaksi. Bila [recurring] aktif, transaksi pertama dibuat
  /// sekarang dan bulan berikutnya dibuat otomatis oleh RecurringService.
  Future<bool> save({
    required String merchant,
    required String amountText,
    required DateTime date,
    required int? categoryId,
    required String notes,
    required bool recurring,
  }) async {
    final int? userId = _auth.currentUser?.id;
    if (userId == null || _isSaving) return false;

    final String name = merchant.trim();
    final double? amount = double.tryParse(amountText.replaceAll('.', ''));
    final DateTime now = DateTime.now();

    String? error;
    if (name.length < 2) {
      error = 'Isi nama tempat atau keterangan (minimal 2 karakter).';
    } else if (amount == null || amount <= 0 || amount > maxAmount) {
      error = 'Isi jumlah yang valid (Rp 1 sampai Rp 100.000.000).';
    } else if (categoryId == null) {
      error = 'Pilih kategori terlebih dahulu.';
    } else if (date.isAfter(now)) {
      error = 'Tanggal tidak boleh di masa depan.';
    }
    if (error != null) {
      _errorMessage = error;
      _successMessage = null;
      safeNotify();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    safeNotify();
    try {
      await _transactions.insert(
        TransactionModel(
          userId: userId,
          merchantName: name,
          transactionDate: date,
          totalAmount: amount!,
          categoryId: categoryId!,
          isManualEdit: true,
          notes: notes.trim().isEmpty ? null : notes.trim(),
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (recurring) {
        await _recurring.insert(
          RecurringTransactionModel(
            userId: userId,
            merchantName: name,
            totalAmount: amount!,
            categoryId: categoryId!,
            dayOfMonth: date.day,
            startMonth: MonthUtils.key(date),
            lastGenerated: MonthUtils.key(date),
            notes: notes.trim().isEmpty ? null : notes.trim(),
            createdAt: now,
          ),
        );
      }
      await _budgetService.checkAndNotify(userId);
      _successMessage = recurring
          ? 'Transaksi berulang disimpan.'
          : 'Transaksi manual disimpan.';
      _isSaving = false;
      await load();
      return true;
    } catch (_) {
      _errorMessage = 'Gagal menyimpan. Silakan coba lagi.';
      _isSaving = false;
      safeNotify();
      return false;
    }
  }

  Future<void> setRecurringActive(int id, bool isActive) async {
    await _recurring.setActive(id, isActive);
    await load();
  }

  Future<void> deleteRecurring(int id) async {
    await _recurring.delete(id);
    _successMessage = 'Transaksi berulang dihapus. Riwayat tetap tersimpan.';
    await load();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    safeNotify();
  }
}
