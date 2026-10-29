import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../core/utils/formatters.dart';

/// Pemilih bulan: panah kiri/kanan dengan label bulan di tengah.
class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.month,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Bulan sebelumnya',
            onPressed: onPrevious,
            icon: Icon(AppIcons.chevronLeft),
          ),
          Expanded(
            child: Text(
              AppFormatters.monthYear(month),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: 'Bulan berikutnya',
            onPressed: canGoNext ? onNext : null,
            icon: Icon(
              AppIcons.chevronRight,
              color: canGoNext ? AppColors.slateDark : AppColors.border,
            ),
          ),
        ],
      ),
    );
  }
}
