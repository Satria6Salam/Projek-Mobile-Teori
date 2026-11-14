import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/month_utils.dart';
import '../data/models/budget_model.dart';
import '../data/models/category_model.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/transaction_repository.dart';
import 'notification_service.dart';
import 'reminder_settings.dart';

/// Satu baris anggaran: pengeluaran bulan ini dan batasnya (jika ada).
class BudgetRow {
  const BudgetRow({
    this.categoryId,
    required this.name,
    required this.spent,
    this.limit,
  });

  /// Null untuk baris batas total.
  final int? categoryId;
  final String name;
  final double spent;
  final double? limit;

  bool get hasLimit => limit != null && limit! > 0;

  /// Pemakaian 0 hingga >1 (di atas 1 berarti melewati batas).
  double get ratio => hasLimit ? spent / limit! : 0;
}

/// Ringkasan anggaran satu bulan.
class BudgetSnapshot {
  const BudgetSnapshot({
    required this.month,
    required this.totalSpent,
    this.totalLimit,
    required this.rows,
  });

  final DateTime month;
  final double totalSpent;
  final double? totalLimit;

  /// Baris batas total (jika ada) disusul baris per kategori.
  final List<BudgetRow> rows;

  bool get hasTotalLimit => totalLimit != null && totalLimit! > 0;
  double get totalRatio => hasTotalLimit ? totalSpent / totalLimit! : 0;
}

/// Menghitung pemakaian anggaran dan mengirim peringatan 80% dan 100%.
class BudgetService {
  BudgetService({
    required BudgetRepository budgets,
    required TransactionRepository transactions,
    required CategoryRepository categories,
    required NotificationService notifications,
  })  : _budgets = budgets,
        _transactions = transactions,
        _categories = categories,
        _notifications = notifications;

  final BudgetRepository _budgets;
  final TransactionRepository _transactions;
  final CategoryRepository _categories;
  final NotificationService _notifications;

  static const List<double> _alertThresholds = <double>[0.8, 1.0];

  Future<BudgetSnapshot> snapshot(int userId, DateTime month) async {
    final DateTime start = MonthUtils.startOf(month);
    final DateTime end = MonthUtils.endExclusive(month);

    final List<BudgetModel> budgets = await _budgets.getAll(userId);
    final double totalSpent =
        await _transactions.getTotalBetween(userId, start, end);
    final spentByCategory =
        await _transactions.getCategorySummaryBetween(userId, start, end);
    final List<CategoryModel> categories = (await _categories.getAll())
        .where((CategoryModel c) => !c.isHidden)
        .toList();

    final Map<int, double> limits = <int, double>{
      for (final BudgetModel b in budgets)
        if (b.categoryId != null) b.categoryId!: b.amount,
    };
    double? totalLimit;
    for (final BudgetModel b in budgets) {
      if (b.categoryId == null) totalLimit = b.amount;
    }

    final Map<int, double> spent = <int, double>{
      for (final summary in spentByCategory)
        summary.categoryId: summary.totalAmount,
    };

    final List<BudgetRow> rows = <BudgetRow>[
      for (final CategoryModel category in categories)
        if (category.id != null)
          BudgetRow(
            categoryId: category.id,
            name: category.name,
            spent: spent[category.id] ?? 0,
            limit: limits[category.id],
          ),
    ];

    return BudgetSnapshot(
      month: month,
      totalSpent: totalSpent,
      totalLimit: totalLimit,
      rows: rows,
    );
  }

  /// Mengirim peringatan bila pemakaian mencapai 80% atau 100%. Setiap ambang
  /// hanya diberitahukan sekali per bulan dan per kategori.
  Future<void> checkAndNotify(int userId, {DateTime? now}) async {
    final ReminderSettings settings = await ReminderSettings.load();
    if (!settings.notificationsEnabled || !settings.budgetAlerts) return;

    final DateTime month = now ?? DateTime.now();
    final BudgetSnapshot data = await snapshot(userId, month);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String monthKey = MonthUtils.key(month);

    if (data.hasTotalLimit) {
      await _alertIfNeeded(
        prefs: prefs,
        monthKey: monthKey,
        scope: 'total',
        name: 'Total pengeluaran',
        ratio: data.totalRatio,
        notificationBase: 0,
      );
    }
    for (final BudgetRow row in data.rows) {
      if (!row.hasLimit) continue;
      await _alertIfNeeded(
        prefs: prefs,
        monthKey: monthKey,
        scope: 'cat${row.categoryId}',
        name: row.name,
        ratio: row.ratio,
        notificationBase: (row.categoryId ?? 0) * 10,
      );
    }
  }

  Future<void> _alertIfNeeded({
    required SharedPreferences prefs,
    required String monthKey,
    required String scope,
    required String name,
    required double ratio,
    required int notificationBase,
  }) async {
    for (final double threshold in _alertThresholds) {
      if (ratio < threshold) continue;
      final String key =
          'budget_alert_${monthKey}_${scope}_${threshold.toString()}';
      if (prefs.getBool(key) == true) continue;

      final bool exceeded = threshold >= 1.0;
      await _notifications.showNow(
        id: NotificationService.budgetAlertBaseId +
            notificationBase +
            (exceeded ? 1 : 0),
        title: exceeded ? 'Anggaran terlampaui' : 'Anggaran hampir habis',
        body: exceeded
            ? '$name sudah melewati batas bulan ini.'
            : '$name sudah mencapai ${(threshold * 100).round()}% dari batas bulan ini.',
      );
      await prefs.setBool(key, true);
    }
  }
}
