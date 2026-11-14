import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import 'custom_button.dart';
import 'theme_illustrations.dart';

/// Tampilan kosong: ikon, judul, penjelasan, dan (opsional) tombol aksi.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.art,
  });

  /// Bila diisi, ilustrasi animasi ditampilkan menggantikan ikon.
  final ThemeArtKind? art;

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (art != null)
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.emeraldDeep.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ThemeArt(kind: art!, size: 92),
            )
          else
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.emeraldTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.emeraldDark),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(title,
              style: textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.coolGray),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 220,
              child:
                  CustomButton(label: actionLabel ?? '', onPressed: onAction),
            ),
          ],
        ],
      ),
    );
  }
}
