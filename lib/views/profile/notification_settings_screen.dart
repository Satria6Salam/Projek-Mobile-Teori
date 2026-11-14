import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../services/reminder_settings.dart';
import '../../viewmodels/reminder_viewmodel.dart';
import '../widgets/message_banner.dart';
import '../widgets/theme_illustrations.dart';

/// Pengaturan notifikasi: pengingat harian dan jamnya, ringkasan mingguan,
/// dan peringatan anggaran. Setiap perubahan langsung diterapkan.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReminderViewModel>().load();
    });
  }

  Future<void> _apply(ReminderSettings next) =>
      context.read<ReminderViewModel>().update(next);

  Future<void> _pickTime(ReminderSettings current) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current.reminderHour,
        minute: current.reminderMinute,
      ),
      helpText: 'Jam pengingat',
    );
    if (picked == null) return;
    await _apply(current.copyWith(
      reminderHour: picked.hour,
      reminderMinute: picked.minute,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ReminderViewModel vm = context.watch<ReminderViewModel>();
    final ReminderSettings s = vm.settings;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String time = '${s.reminderHour.toString().padLeft(2, '0')}:'
        '${s.reminderMinute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const GradientHeader(
              title: 'Notifikasi',
              subtitle: 'Pengingat yang tidak mengganggu',
              kind: ThemeArtKind.bell,
            ),
            const SizedBox(height: 16),
            if (vm.successMessage != null) ...[
              MessageBanner(
                message: vm.successMessage!,
                type: BannerType.success,
              ),
              const SizedBox(height: 12),
            ],
            if (vm.errorMessage != null) ...[
              MessageBanner(message: vm.errorMessage!),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: AppDecorations.card(radius: AppRadius.cardLarge),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aktifkan notifikasi'),
                    subtitle:
                        const Text('Semua pengingat lokal di perangkat ini.'),
                    value: s.notificationsEnabled,
                    onChanged: vm.isLoading
                        ? null
                        : (bool v) =>
                            _apply(s.copyWith(notificationsEnabled: v)),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pengingat harian'),
                    subtitle: const Text('"Sudah catat struk hari ini?"'),
                    value: s.dailyReminder && s.notificationsEnabled,
                    onChanged: s.notificationsEnabled
                        ? (bool v) => _apply(s.copyWith(dailyReminder: v))
                        : null,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    enabled: s.notificationsEnabled && s.dailyReminder,
                    title: const Text('Jam pengingat'),
                    trailing: Text(
                      time,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.emeraldDark,
                      ),
                    ),
                    onTap: s.notificationsEnabled && s.dailyReminder
                        ? () => _pickTime(s)
                        : null,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ringkasan mingguan'),
                    subtitle: const Text(
                      'Setiap Minggu pukul 19.00. Isinya dihitung saat aplikasi dibuka.',
                    ),
                    value: s.weeklySummary && s.notificationsEnabled,
                    onChanged: s.notificationsEnabled
                        ? (bool v) => _apply(s.copyWith(weeklySummary: v))
                        : null,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Peringatan anggaran'),
                    subtitle: const Text(
                        'Saat pengeluaran mencapai 80% dan 100% batas.'),
                    value: s.budgetAlerts && s.notificationsEnabled,
                    onChanged: s.notificationsEnabled
                        ? (bool v) => _apply(s.copyWith(budgetAlerts: v))
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
