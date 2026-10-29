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
  });

  final TransactionModel transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String categoryName = transaction.categoryName ?? 'Lainnya';

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
                      Text(
                        '${AppFormatters.shortDate(transaction.transactionDate)}  •  $categoryName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppFormatters.rupiah(transaction.totalAmount),
                  style: AppTextStyles.amount(
                    size: 15,
                    color: AppColors.slateDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
