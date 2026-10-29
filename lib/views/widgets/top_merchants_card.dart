import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../services/insight_service.dart';

/// Daftar toko/merchant dengan pengeluaran terbesar bulan ini.
class TopMerchantsCard extends StatelessWidget {
  const TopMerchantsCard({super.key, required this.merchants});

  final List<MerchantStat> merchants;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double maxTotal = merchants.isEmpty ? 0 : merchants.first.total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(radius: AppRadius.cardLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Toko Favorit', style: textTheme.titleLarge),
          const SizedBox(height: 2),
          Text('Berdasarkan total pengeluaran', style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          for (int i = 0; i < merchants.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _MerchantRow(
              rank: i + 1,
              stat: merchants[i],
              fraction: maxTotal > 0 ? merchants[i].total / maxTotal : 0,
            ),
          ],
        ],
      ),
    );
  }
}

class _MerchantRow extends StatelessWidget {
  const _MerchantRow({
    required this.rank,
    required this.stat,
    required this.fraction,
  });

  final int rank;
  final MerchantStat stat;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank == 1 ? AppColors.emerald : AppColors.emeraldTint,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                style: textTheme.labelLarge?.copyWith(
                  color: rank == 1 ? AppColors.white : AppColors.emeraldDeep,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium,
                  ),
                  Text('${stat.visits}x kunjungan', style: textTheme.bodySmall),
                ],
              ),
            ),
            Text(
              AppFormatters.rupiah(stat.total),
              style: AppTextStyles.amount(size: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: fraction.clamp(0.0, 1.0).toDouble()),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double value, Widget? child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 5,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emerald),
              ),
            );
          },
        ),
      ],
    );
  }
}
