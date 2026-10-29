import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';

enum BannerType { error, success, warning }

/// Kotak pesan umpan balik: galat (merah), sukses (hijau), atau peringatan (kuning).
class MessageBanner extends StatelessWidget {
  const MessageBanner({
    super.key,
    required this.message,
    this.type = BannerType.error,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final BannerType type;
  final String? actionLabel;
  final VoidCallback? onAction;

  Color get _background {
    switch (type) {
      case BannerType.error:
        return AppColors.errorTint;
      case BannerType.success:
        return AppColors.emeraldTint;
      case BannerType.warning:
        return AppColors.warningTint;
    }
  }

  Color get _foreground {
    switch (type) {
      case BannerType.error:
        return AppColors.error;
      case BannerType.success:
        return AppColors.emeraldDeep;
      case BannerType.warning:
        return AppColors.warningDeep;
    }
  }

  IconData get _icon =>
      type == BannerType.success ? AppIcons.check : AppIcons.info;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 20, color: _foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: _foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onAction,
                    child: Text(
                      actionLabel ?? '',
                      style: textTheme.bodyMedium?.copyWith(
                        color: _foreground,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
