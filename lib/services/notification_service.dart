import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Notifikasi lokal (tanpa internet): pengingat harian, ringkasan mingguan,
/// dan peringatan anggaran.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const int dailyReminderId = 1;
  static const int weeklySummaryId = 2;

  /// ID peringatan anggaran = [budgetAlertBaseId] + offset (lihat BudgetService).
  static const int budgetAlertBaseId = 1000;

  static const String _channelId = 'smartreceipt_main';
  static const String _channelName = 'SmartReceipt';
  static const String _channelDescription =
      'Pengingat pencatatan, ringkasan mingguan, dan peringatan anggaran';

  static final NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  bool _ready = false;

  /// Menyiapkan plugin dan zona waktu perangkat. Aman dipanggil berulang.
  Future<void> initialize() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final String zoneName =
          (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(zoneName));
    } catch (_) {
      // Bila zona tidak terbaca, jadwal memakai UTC (tidak menghentikan aplikasi).
      debugPrint('[SmartReceipt] Zona waktu perangkat tidak terbaca.');
    }
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _ready = true;
  }

  /// Meminta izin notifikasi (wajib untuk Android 13 ke atas).
  Future<bool> requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final bool? granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  /// Pengingat harian pada jam yang ditentukan pengguna.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(dailyReminderId);
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime when =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      dailyReminderId,
      'SmartReceipt',
      'Sudah catat struk hari ini?',
      when,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Ringkasan mingguan setiap Minggu sore. [body] dihitung saat jadwal dibuat.
  Future<void> scheduleWeeklySummary({required String body}) async {
    await _plugin.cancel(weeklySummaryId);
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final int daysToSunday = (DateTime.sunday - now.weekday + 7) % 7;
    tz.TZDateTime when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysToSunday,
      19,
    );
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 7));
    }
    await _plugin.zonedSchedule(
      weeklySummaryId,
      'Ringkasan minggu ini',
      body,
      when,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Peringatan langsung (dipakai untuk anggaran).
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) {
    return _plugin.show(id, title, body, _details);
  }

  Future<void> cancelDaily() => _plugin.cancel(dailyReminderId);

  Future<void> cancelWeekly() => _plugin.cancel(weeklySummaryId);

  Future<void> cancelScheduled() async {
    await cancelDaily();
    await cancelWeekly();
  }
}
