import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';

/// Teks mentah hasil OCR yang dapat dibuka/ditutup, untuk membantu pemeriksaan (QC).
class RawTextSection extends StatelessWidget {
  const RawTextSection({super.key, required this.rawText});

  final String rawText;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: AppDecorations.card(),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        leading: Icon(AppIcons.fileText, size: 20, color: AppColors.coolGray),
        title: Text('Teks hasil OCR', style: textTheme.titleMedium),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(
              rawText,
              style: textTheme.bodySmall?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
