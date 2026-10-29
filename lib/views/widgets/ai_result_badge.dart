import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/utils/formatters.dart';

/// Lencana hasil AI: hijau transparan bila yakin, kuning bila perlu dicek.
class AiResultBadge extends StatelessWidget {
  const AiResultBadge({
    super.key,
    required this.probability,
    required this.isConfident,
  });

  /// Nilai 0.0 - 1.0.
  final double probability;
  final bool isConfident;

  @override
  Widget build(BuildContext context) {
    final Color background =
        isConfident ? AppColors.emeraldTint : AppColors.warningTint;
    final Color foreground =
        isConfident ? AppColors.emeraldDeep : AppColors.warningDeep;
    final String text = isConfident
        ? 'Dibaca AI  •  Keyakinan ${AppFormatters.percent(probability)}'
        : 'Perlu dicek  •  Keyakinan ${AppFormatters.percent(probability)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.sparkles, size: 16, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
