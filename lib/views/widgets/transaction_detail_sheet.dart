import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_item_model.dart';
import '../../data/models/transaction_model.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import 'category_badge.dart';
import 'confirm_dialog.dart';
import 'custom_button.dart';

/// Menampilkan rincian transaksi pada lembar bawah: data struk, barang yang
/// dibeli per kategori, dan tombol hapus.
Future<void> showTransactionDetailSheet(
  BuildContext context,
  TransactionModel transaction,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) =>
        _TransactionDetailSheet(transaction: transaction),
  );
}

class _TransactionDetailSheet extends StatefulWidget {
  const _TransactionDetailSheet({required this.transaction});

  final TransactionModel transaction;

  @override
  State<_TransactionDetailSheet> createState() =>
      _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<_TransactionDetailSheet> {
  bool _isDeleting = false;
  late final Future<List<TransactionItemModel>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    final int? id = widget.transaction.id;
    _itemsFuture = id == null
        ? Future<List<TransactionItemModel>>.value(<TransactionItemModel>[])
        : context.read<DashboardViewModel>().loadItems(id);
  }

  Future<void> _delete() async {
    final DashboardViewModel dashboard = context.read<DashboardViewModel>();
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final int? id = widget.transaction.id;
    if (id == null) return;

    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Hapus Transaksi?',
      message:
          'Transaksi dari ${widget.transaction.merchantName} akan dihapus permanen beserta foto struknya.',
      confirmLabel: 'Hapus',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    final bool ok = await dashboard.deleteTransaction(id);
    if (mounted) navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Transaksi berhasil dihapus'
              : (dashboard.errorMessage ?? 'Gagal menghapus transaksi'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TransactionModel t = widget.transaction;
    final String categoryName = t.categoryName ?? 'Lainnya';
    final String? notes = t.notes;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.cardLarge),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  CategoryIconBox(categoryName: categoryName, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.merchantName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.rupiah(t.totalAmount),
                          style: AppTextStyles.amount(size: 22),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailRow(
                label: 'Tanggal',
                child: Text(
                  AppFormatters.longDate(t.transactionDate),
                  style: textTheme.bodyMedium,
                ),
              ),
              _DetailRow(
                label: 'Kategori utama',
                child: CategoryBadge(categoryName: categoryName),
              ),
              _DetailRow(
                label: 'Pencatatan',
                child: Text(
                  t.isManualEdit ? 'Disunting manual' : 'Otomatis oleh AI',
                  style: textTheme.bodyMedium,
                ),
              ),
              if (notes != null && notes.isNotEmpty)
                _DetailRow(
                  label: 'Catatan',
                  child: Text(notes, style: textTheme.bodyMedium),
                ),
              const SizedBox(height: AppSpacing.md),
              Text('Barang yang Dibeli', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              FutureBuilder<List<TransactionItemModel>>(
                future: _itemsFuture,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<List<TransactionItemModel>> snapshot,
                ) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final List<TransactionItemModel> items =
                      snapshot.data ?? <TransactionItemModel>[];
                  if (items.isEmpty) {
                    return Text(
                      'Rincian barang tidak tersedia untuk transaksi ini.',
                      style: textTheme.bodySmall,
                    );
                  }
                  return _ItemsByCategory(items: items);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              CustomButton(
                label: 'Hapus Transaksi',
                icon: AppIcons.trash,
                variant: CustomButtonVariant.danger,
                isLoading: _isDeleting,
                onPressed: _delete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemsByCategory extends StatelessWidget {
  const _ItemsByCategory({required this.items});

  final List<TransactionItemModel> items;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final Map<String, List<TransactionItemModel>> grouped =
        <String, List<TransactionItemModel>>{};
    for (final TransactionItemModel item in items) {
      grouped
          .putIfAbsent(
              item.categoryName ?? 'Lainnya', () => <TransactionItemModel>[])
          .add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final MapEntry<String, List<TransactionItemModel>> entry
            in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Row(
              children: [
                CategoryBadge(categoryName: entry.key),
                const Spacer(),
                Text(
                  AppFormatters.rupiah(
                    entry.value.fold<double>(
                      0,
                      (double s, TransactionItemModel i) => s + i.totalPrice,
                    ),
                  ),
                  style: AppTextStyles.amount(size: 14),
                ),
              ],
            ),
          ),
          for (final TransactionItemModel item in entry.value)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: textTheme.bodyMedium),
                        if (item.quantity != 1)
                          Text(
                            '${item.quantity == item.quantity.roundToDouble() ? item.quantity.round() : item.quantity} × ${AppFormatters.rupiah(item.unitPrice)}',
                            style: textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppFormatters.rupiah(item.totalPrice),
                    style: AppTextStyles.amount(
                      size: 13,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: child)),
        ],
      ),
    );
  }
}
