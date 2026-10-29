import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';

/// Kepala Dasbor: avatar inisial, sapaan, dan tombol menuju Pengaturan & Profil.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.name,
    required this.onSettingsTap,
  });

  final String name;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String trimmed = name.trim();
    final String initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: textTheme.titleLarge?.copyWith(color: AppColors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selamat datang kembali', style: textTheme.bodySmall),
              Text(
                'Halo, ${trimmed.isEmpty ? 'Pengguna' : trimmed}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge,
              ),
            ],
          ),
        ),
        Container(
          decoration: AppDecorations.card(radius: AppRadius.control),
          child: IconButton(
            tooltip: 'Pengaturan & Profil',
            onPressed: onSettingsTap,
            icon: Icon(AppIcons.settings, size: 22),
          ),
        ),
      ],
    );
  }
}
