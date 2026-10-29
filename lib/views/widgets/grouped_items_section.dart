import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../viewmodels/scan_viewmodel.dart';
import 'category_badge.dart';
import 'fade_slide_in.dart';

/// Daftar barang pada struk yang dikelompokkan per kategori, lengkap dengan
/// subtotal tiap kategori. Ketuk sebuah barang untuk menyuntingnya.
class GroupedItemsSection extends StatelessWidget {
  const GroupedItemsSection({
    super.key,
    required this.groups,
    required this.itemCount,
    required this.onEdit,
    required this.onAdd,
    this.errorText,
  });

  final List<ItemGroup> groups;
  final int itemCount;
  final ValueChanged<DraftItem> onEdit;
  final VoidCallback onAdd;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Barang yang Dibeli', style: textTheme.titleLarge),
                  Text(
                    '$itemCount barang  •  ${groups.length} kategori',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: Icon(AppIcons.plus, size: 18),
              label: const Text('Tambah'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (errorText != null) ...[
          Text(
            errorText ?? '',
            style: textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (groups.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: AppDecorations.card(radius: AppRadius.cardLarge),
            child: Column(
              children: [
                Icon(AppIcons.receipt, size: 30, color: AppColors.coolGray),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Belum ada barang. Tekan Tambah untuk mengisi.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.coolGray,
                  ),
                ),
              ],
            ),
          )
        else
          for (int i = 0; i < groups.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            FadeSlideIn(
              delay: Duration(milliseconds: 60 * i),
              child: _GroupCard(group: groups[i], onEdit: onEdit),
            ),
          ],
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.onEdit});

  final ItemGroup group;
  final ValueChanged<DraftItem> onEdit;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: AppDecorations.card(radius: AppRadius.cardLarge),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CategoryIconBox(categoryName: group.categoryName, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.categoryName, style: textTheme.titleMedium),
                      Text(
                        '${group.items.length} barang',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  AppFormatters.rupiah(group.subtotal),
                  style: AppTextStyles.amount(size: 15),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final DraftItem item in group.items)
            _ItemRow(item: item, onTap: () => onEdit(item)),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onTap});

  final DraftItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool multiple = item.quantity != 1;
    final String qty = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.round().toString()
        : item.quantity.toString();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (multiple || !item.isConfident) ...[
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (multiple)
                          Text(
                            '$qty × ${AppFormatters.rupiah(item.unitPrice)}',
                            style: textTheme.bodySmall,
                          ),
                        if (!item.isConfident)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningTint,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Perlu dicek',
                              style: textTheme.labelMedium?.copyWith(
                                color: AppColors.warningDeep,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppFormatters.rupiah(item.totalPrice),
              style: AppTextStyles.amount(size: 14, weight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Icon(AppIcons.pencil, size: 16, color: AppColors.coolGray),
          ],
        ),
      ),
    );
  }
}
