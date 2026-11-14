import 'package:flutter/foundation.dart';

import '../services/reminder_coordinator.dart';
import '../services/reminder_settings.dart';
import '../services/notification_service.dart';
import 'auth_viewmodel.dart';
import 'safe_change_notifier.dart';

/// Pengaturan notifikasi: izin Android 13, jam pengingat, dan ringkasan.
class ReminderViewModel extends ChangeNotifier with SafeChangeNotifier {
  ReminderViewModel({
    required AuthViewModel authViewModel,
    required NotificationService notifications,
    required ReminderCoordinator coordinator,
  })  : _auth = authViewModel,
        _notifications = notifications,
        _coordinator = coordinator;

  final AuthViewModel _auth;
  final NotificationService _notifications;
  final ReminderCoordinator _coordinator;

  ReminderSettings _settings = const ReminderSettings();
  bool _isLoading = true;
  String? _errorMessage;
  String? _successMessage;

  ReminderSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> load() async {
    _settings = await ReminderSettings.load();
    _isLoading = false;
    safeNotify();
  }

  /// Menyimpan pengaturan dan menerapkannya ke jadwal notifikasi.
  Future<void> update(ReminderSettings next) async {
    if (next.notificationsEnabled && !_settings.notificationsEnabled) {
      final bool granted = await _notifications.requestPermission();
      if (!granted) {
        _errorMessage =
            'Izin notifikasi ditolak. Aktifkan lewat pengaturan aplikasi di perangkat.';
        _successMessage = null;
        safeNotify();
        return;
      }
    }
    _settings = next;
    await _settings.save();
    final int? userId = _auth.currentUser?.id;
    if (userId != null) {
      await _coordinator.apply(_settings, userId);
    }
    _errorMessage = null;
    _successMessage = 'Pengaturan notifikasi disimpan.';
    safeNotify();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    safeNotify();
  }
}
