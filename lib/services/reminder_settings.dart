import 'package:shared_preferences/shared_preferences.dart';

/// Pengaturan notifikasi dan pengingat. Disimpan di perangkat (shared_preferences).
class ReminderSettings {
  const ReminderSettings({
    this.notificationsEnabled = true,
    this.dailyReminder = true,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.weeklySummary = true,
    this.budgetAlerts = true,
  });

  final bool notificationsEnabled;
  final bool dailyReminder;
  final int reminderHour;
  final int reminderMinute;
  final bool weeklySummary;
  final bool budgetAlerts;

  static const String _keyEnabled = 'notif_enabled';
  static const String _keyDaily = 'notif_daily';
  static const String _keyHour = 'notif_hour';
  static const String _keyMinute = 'notif_minute';
  static const String _keyWeekly = 'notif_weekly';
  static const String _keyBudget = 'notif_budget';

  /// Membaca pengaturan; nilai default dipakai bila belum pernah disimpan.
  static Future<ReminderSettings> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    const ReminderSettings defaults = ReminderSettings();
    return ReminderSettings(
      notificationsEnabled:
          prefs.getBool(_keyEnabled) ?? defaults.notificationsEnabled,
      dailyReminder: prefs.getBool(_keyDaily) ?? defaults.dailyReminder,
      reminderHour: prefs.getInt(_keyHour) ?? defaults.reminderHour,
      reminderMinute: prefs.getInt(_keyMinute) ?? defaults.reminderMinute,
      weeklySummary: prefs.getBool(_keyWeekly) ?? defaults.weeklySummary,
      budgetAlerts: prefs.getBool(_keyBudget) ?? defaults.budgetAlerts,
    );
  }

  Future<void> save() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, notificationsEnabled);
    await prefs.setBool(_keyDaily, dailyReminder);
    await prefs.setInt(_keyHour, reminderHour);
    await prefs.setInt(_keyMinute, reminderMinute);
    await prefs.setBool(_keyWeekly, weeklySummary);
    await prefs.setBool(_keyBudget, budgetAlerts);
  }

  ReminderSettings copyWith({
    bool? notificationsEnabled,
    bool? dailyReminder,
    int? reminderHour,
    int? reminderMinute,
    bool? weeklySummary,
    bool? budgetAlerts,
  }) {
    return ReminderSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
    );
  }
}
