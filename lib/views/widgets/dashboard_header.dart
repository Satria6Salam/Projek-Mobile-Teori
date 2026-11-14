import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';

/// Kepala Dasbor: sapaan sesuai waktu, nama pengguna, tombol notifikasi,
/// dan avatar inisial yang membuka Pengaturan & Profil.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.name,
    required this.onSettingsTap,
    this.onNotificationTap,
    this.now,
  });

  final String name;
  final VoidCallback onSettingsTap;
  final VoidCallback? onNotificationTap;

  /// Untuk pengujian; default waktu saat ini.
  final DateTime? now;

  static String greetingFor(DateTime time) {
    final int h = time.hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String trimmed = name.trim();
    final String initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    final String greeting = greetingFor(now ?? DateTime.now());

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.coolGray,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      trimmed.isEmpty ? 'Pengguna' : trimmed,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const _WavingHand(),
                ],
              ),
            ],
          ),
        ),
        if (onNotificationTap != null) ...[
          Container(
            decoration: AppDecorations.card(radius: 14),
            child: IconButton(
              tooltip: 'Notifikasi',
              onPressed: onNotificationTap,
              icon: Icon(AppIcons.bell, size: 21, color: AppColors.forest),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Tooltip(
          message: 'Pengaturan & Profil',
          child: InkWell(
            onTap: onSettingsTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    AppColors.emeraldLight,
                    AppColors.emerald,
                    Color(0xFFFBBF24),
                    AppColors.emeraldLight,
                  ],
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.cardGradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: textTheme.titleLarge?.copyWith(color: AppColors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Emoji tangan yang melambai beberapa kali saat Dasbor dibuka.
class _WavingHand extends StatefulWidget {
  const _WavingHand();

  @override
  State<_WavingHand> createState() => _WavingHandState();
}

class _WavingHandState extends State<_WavingHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;
        // Tiga ayunan yang makin melemah.
        final double angle = math.sin(t * 6 * math.pi) * 0.4 * (1 - t);
        return Transform.rotate(
          angle: angle,
          alignment: const Alignment(0.3, 0.8),
          child: child,
        );
      },
      child: const Text('👋', style: TextStyle(fontSize: 22)),
    );
  }
}
