import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/dashboard_period.dart';
import '../data/models/category_summary_model.dart';
import '../data/models/transaction_item_model.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/ocr_result_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../services/image_storage_service.dart';
import '../services/insight_service.dart';
import 'auth_viewmodel.dart';
import 'safe_change_notifier.dart';

/// Mengambil ringkasan, rekap kategori, tren bulanan/tahunan, dan analisis perilaku
/// pengeluaran untuk Dasbor. Periode dapat berupa hari, bulan, atau tahun.
/// Otomatis memuat ulang saat pengguna berganti, dan mengosongkan data saat logout.
class DashboardViewModel extends ChangeNotifier with SafeChangeNotifier {
  DashboardViewModel({
    required AuthViewModel authViewModel,
    required TransactionRepository transactionRepository,
    required OcrResultRepository ocrResultRepository,
    required ImageStorageService imageStorageService,
    InsightService insightService = const InsightService(),
    DashboardPeriod? initialPeriod,
    DateTime? initialMonth,
    DateTime Function()? clock,
  })  : _auth = authViewModel,
        _transactionRepository = transactionRepository,
        _ocrResultRepository = ocrResultRepository,
        _imageStorageService = imageStorageService,
        _insightService = insightService,
        _clock = clock ?? DateTime.now {
    final DateTime base = initialMonth ?? _clock();
    _period = initialPeriod ?? DashboardPeriod.month(base.year, base.month);

    _auth.addListener(_onAuthChanged);
    if (_auth.isLoggedIn) {
      unawaited(loadDashboard());
    }
  }

  final AuthViewModel _auth;
  final TransactionRepository _transactionRepository;
  final OcrResultRepository _ocrResultRepository;
  final ImageStorageService _imageStorageService;
  final InsightService _insightService;
  final DateTime Function() _clock;

  late DashboardPeriod _period;
  bool _isLoading = false;
  String? _errorMessage;
  double _total = 0;
  List<CategorySummaryModel> _categorySummaries = <CategorySummaryModel>[];
  List<TransactionModel> _transactions = <TransactionModel>[];
  SpendingAnalytics _analytics = const SpendingAnalytics();
  TrendAnalytics _trends = const TrendAnalytics();

  int _loadToken = 0;
  int? _loadedUserId;

  /// Periode yang sedang dilihat (hari, bulan, atau tahun).
  DashboardPeriod get period => _period;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Total pengeluaran pada periode terpilih.
  double get total => _total;

  /// Nama lama (kompatibilitas).
  double get monthlyTotal => _total;

  /// Rekap pengeluaran per kategori (dari rincian barang), terbesar lebih dulu.
  List<CategorySummaryModel> get categorySummaries => _categorySummaries;

  /// Riwayat transaksi pada periode terpilih (terbaru lebih dulu).
  List<TransactionModel> get transactions => _transactions;
  int get transactionCount => _transactions.length;
  bool get isEmpty => !_isLoading && _transactions.isEmpty;

  /// Hasil analisis perilaku periode terpilih.
  SpendingAnalytics get analytics => _analytics;

  /// Tren bulanan (pada tahun periode terpilih) dan tren tahunan.
  TrendAnalytics get trends => _trends;

  /// Tahun yang memiliki data, terbaru lebih dulu (untuk pilihan cepat).
  List<int> get availableYears {
    final List<int> years =
        _trends.yearlyTotals.map((YearlyPoint p) => p.year).toList();
    years.sort((int a, int b) => b.compareTo(a));
    return years;
  }

  /// Kategori dengan pengeluaran terbesar (null bila belum ada data).
  CategorySummaryModel? get topCategory =>
      _categorySummaries.isEmpty ? null : _categorySummaries.first;

  /// Jumlah seluruh kategori (dasar perhitungan persentase).
  double get categoriesTotal => _categorySummaries.fold<double>(
        0,
        (double sum, CategorySummaryModel s) => sum + s.totalAmount,
      );

  /// Periode berikutnya hanya boleh dilihat bila sudah dimulai.
  bool get canGoNext => _period.canGoNext(_clock());

  /// Porsi (0.0 - 1.0) sebuah kategori terhadap seluruh rekap kategori.
  double percentageOf(CategorySummaryModel summary) {
    final double sum = categoriesTotal;
    if (sum <= 0) return 0;
    return summary.totalAmount / sum;
  }

  // ----------------------------------------------------------------- muat

  Future<void> loadDashboard() async {
    final int? userId = _auth.currentUser?.id;
    if (userId == null) {
      _resetData();
      _loadedUserId = null;
      safeNotify();
      return;
    }

    final int token = ++_loadToken;
    _loadedUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    safeNotify();

    try {
      final DashboardPeriod period = _period;
      final DashboardPeriod previous = period.previous;
      final int year = period.anchor.year;

      final double total = await _transactionRepository.getTotalBetween(
        userId,
        period.start,
        period.endExclusive,
      );
      final List<CategorySummaryModel> summaries =
          await _transactionRepository.getCategorySummaryBetween(
        userId,
        period.start,
        period.endExclusive,
      );
      final List<TransactionModel> items = await _transactionRepository
          .getBetween(userId, period.start, period.endExclusive);
      final List<TransactionModel> previousItems = await _transactionRepository
          .getBetween(userId, previous.start, previous.endExclusive);

      final SpendingAnalytics analytics = _insightService.analyzePeriod(
        period: period,
        now: _clock(),
        transactions: items,
        summaries: summaries,
        total: total,
        previousTransactions: previousItems,
      );

      final List<double> monthly =
          await _transactionRepository.getMonthlyTotals(userId, year);
      final List<double> previousMonthly =
          await _transactionRepository.getMonthlyTotals(userId, year - 1);
      final Map<int, double> yearly =
          await _transactionRepository.getYearlyTotals(userId);
      final TrendAnalytics trends = _insightService.analyzeTrends(
        year: year,
        now: _clock(),
        monthlyTotals: monthly,
        previousYearMonthlyTotals: previousMonthly,
        yearlyTotals: yearly,
      );

      // Abaikan hasil yang sudah usang (periode/pengguna berubah saat memuat).
      if (token != _loadToken) return;
      _total = total;
      _categorySummaries = summaries;
      _transactions = items;
      _analytics = analytics;
      _trends = trends;
    } catch (_) {
      if (token != _loadToken) return;
      _errorMessage = 'Gagal memuat data keuangan. Silakan coba lagi.';
    }

    _isLoading = false;
    safeNotify();
  }

  Future<void> refresh() => loadDashboard();

  /// Rincian barang sebuah transaksi (kosong bila transaksi lama tanpa rincian).
  Future<List<TransactionItemModel>> loadItems(int transactionId) async {
    try {
      return await _transactionRepository.getItems(transactionId);
    } catch (_) {
      return <TransactionItemModel>[];
    }
  }

  // ------------------------------------------------------ pilih periode

  /// Menampilkan periode tertentu. Mengembalikan false bila periode belum terjadi.
  Future<bool> setPeriod(DashboardPeriod period) async {
    final DateTime now = _clock();
    final DateTime today = DateTime(now.year, now.month, now.day);
    if (period.start.isAfter(today)) return false;
    if (period == _period) return true;
    _period = period;
    await loadDashboard();
    return true;
  }

  Future<bool> showDay(DateTime date) => setPeriod(DashboardPeriod.day(date));

  Future<bool> showMonth(int year, int month) =>
      setPeriod(DashboardPeriod.month(year, month));

  Future<bool> showYear(int year) => setPeriod(DashboardPeriod.year(year));

  Future<void> goToPrevious() => setPeriod(_period.previous);

  Future<void> goToNext() async {
    if (!canGoNext) return;
    await setPeriod(_period.next);
  }

  // ---------------------------------------------------------------- hapus

  /// Menghapus transaksi beserta foto struknya. Mengembalikan true bila berhasil.
  Future<bool> deleteTransaction(int transactionId) async {
    final int? userId = _auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final TransactionModel? transaction =
          await _transactionRepository.getById(transactionId);
      if (transaction == null || transaction.userId != userId) return false;

      String? imagePath;
      final int? ocrId = transaction.ocrId;
      if (ocrId != null) {
        imagePath = (await _ocrResultRepository.getById(ocrId))?.imagePath;
      }

      final bool deleted = await _transactionRepository.delete(transactionId);
      if (!deleted) return false;

      if (imagePath != null) {
        await _imageStorageService.deleteImage(imagePath);
      }
      await loadDashboard();
      return true;
    } catch (_) {
      _errorMessage = 'Gagal menghapus transaksi. Silakan coba lagi.';
      safeNotify();
      return false;
    }
  }

  // ----------------------------------------------------------------- auth

  void _onAuthChanged() {
    final int? userId = _auth.currentUser?.id;
    if (userId == _loadedUserId) return;

    if (userId == null) {
      _loadToken++;
      _loadedUserId = null;
      _resetData();
      safeNotify();
    } else {
      unawaited(loadDashboard());
    }
  }

  void _resetData() {
    _total = 0;
    _categorySummaries = <CategorySummaryModel>[];
    _transactions = <TransactionModel>[];
    _analytics = const SpendingAnalytics();
    _trends = const TrendAnalytics();
    _isLoading = false;
    _errorMessage = null;
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
