import '../core/utils/formatters.dart';
import '../data/repositories/transaction_repository.dart';
import 'budget_service.dart';
import 'notification_service.dart';
import 'recurring_service.dart';
import 'reminder_settings.dart';

/// Menyusun ulang jadwal notifikasi sesuai pengaturan, dan menjalankan
/// pekerjaan harian saat aplikasi dibuka (transaksi berulang, cek anggaran).
class ReminderCoordinator {
  ReminderCoordinator({
    required NotificationService notifications,
    required TransactionRepository transactions,
    required RecurringService recurring,
    required BudgetService budgets,
  })  : _notifications = notifications,
        _transactions = transactions,
        _recurring = recurring,
        _budgets = budgets;

  final NotificationService _notifications;
  final TransactionRepository _transactions;
  final RecurringService _recurring;
  final BudgetService _budgets;

  /// Dipanggil saat aplikasi dibuka dalam keadaan sudah login.
  Future<void> onAppOpened(int userId) async {
    await _notifications.initialize();
    await _recurring.generateDue(userId);
    await _budgets.checkAndNotify(userId);
    await apply(await ReminderSettings.load(), userId);
  }

  /// Menerapkan pengaturan ke jadwal notifikasi di perangkat.
  Future<void> apply(ReminderSettings settings, int userId) async {
    await _notifications.initialize();
    if (!settings.notificationsEnabled) {
      await _notifications.cancelScheduled();
      return;
    }

    if (settings.dailyReminder) {
      await _notifications.scheduleDailyReminder(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
      );
    } else {
      await _notifications.cancelDaily();
    }

    if (settings.weeklySummary) {
      await _notifications.scheduleWeeklySummary(
        body: await _weeklyBody(userId),
      );
    } else {
      await _notifications.cancelWeekly();
    }
  }

  /// Ringkasan tujuh hari terakhir. Isinya dihitung saat jadwal dibuat,
  /// jadi diperbarui setiap kali aplikasi dibuka.
  Future<String> _weeklyBody(int userId) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime start = today.subtract(const Duration(days: 6));
    final DateTime end = today.add(const Duration(days: 1));

    final double total =
        await _transactions.getTotalBetween(userId, start, end);
    final int count =
        (await _transactions.getBetween(userId, start, end)).length;
    if (count == 0) {
      return 'Belum ada catatan 7 hari terakhir. Yuk mulai catat!';
    }
    return '$count catatan, total ${AppFormatters.rupiah(total)} '
        'dalam 7 hari terakhir.';
  }
}
