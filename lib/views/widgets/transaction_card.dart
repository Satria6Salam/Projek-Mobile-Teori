import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import 'category_badge.dart';

/// Kartu satu transaksi pada daftar riwayat.
class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onTap,
    this.amount,
    this.extraCategories = 0,
  });

  final TransactionModel transaction;
  final VoidCallback onTap;

  /// Jumlah yang ditampilkan (mis. jumlah pada kategori yang difilter).
  /// Null berarti memakai total transaksi.
  final double? amount;

  /// Jumlah kategori lain pada struk yang sama (untuk lencana "+N").
  final int extraCategories;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String categoryName = transaction.categoryName ?? 'Lainnya';
    final double shown = amount ?? transaction.totalAmount;
    final bool partial =
        amount != null && (amount! - transaction.totalAmount).abs() > 1;

    return Container(
      decoration: AppDecorations.card(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CategoryIconBox(categoryName: categoryName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.merchantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${AppFormatters.shortDate(transaction.transactionDate)}  •  $categoryName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall,
                            ),
                          ),
                          if (extraCategories > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldTint,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '+$extraCategories',
                                style: textTheme.labelMedium?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.emeraldDeep,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.rupiah(shown),
                      style: AppTextStyles.amount(
                        size: 15,
                        color: AppColors.slateDark,
                      ),
                    ),
                    if (partial)
                      Text(
                        'dari ${AppFormatters.rupiah(transaction.totalAmount)}',
                        style: textTheme.labelMedium?.copyWith(fontSize: 10),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
