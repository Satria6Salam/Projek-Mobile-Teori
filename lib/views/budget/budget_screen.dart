import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/category_style.dart';
import '../../core/utils/formatters.dart';
import '../../services/budget_service.dart';
import '../../viewmodels/budget_viewmodel.dart';
import '../widgets/animated_values.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/message_banner.dart';
import '../widgets/theme_illustrations.dart';

/// Anggaran bulanan: batas total dan per kategori, bilah progres, dan sisa.
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BudgetViewModel>().load();
    });
  }

  Future<void> _editLimit({
    int? categoryId,
    required String title,
    double? current,
  }) async {
    final BudgetViewModel vm = context.read<BudgetViewModel>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => _LimitSheet(
        title: title,
        current: current,
        onSave: (double amount) =>
            vm.saveLimit(categoryId: categoryId, amount: amount),
        onRemove: current == null
            ? null
            : () async {
                final bool ok = await showConfirmDialog(
                  sheetContext,
                  title: 'Hapus batas?',
                  message: 'Batas anggaran ini akan dihapus.',
                  confirmLabel: 'Hapus',
                  isDestructive: true,
                );
                if (ok) await vm.removeLimit(categoryId: categoryId);
                return ok;
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BudgetViewModel vm = context.watch<BudgetViewModel>();
    final BudgetSnapshot? data = vm.snapshot;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Anggaran')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: vm.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const GradientHeader(
                title: 'Anggaran',
                subtitle: 'Pantau batas pengeluaran tiap bulan',
                kind: ThemeArtKind.wallet,
              ),
              const SizedBox(height: 16),
              _MonthBar(
                label: AppFormatters.monthYear(vm.month),
                canGoForward: vm.canGoForward,
                onPrevious: () => vm.changeMonth(-1),
                onNext: () => vm.changeMonth(1),
              ),
              const SizedBox(height: 12),
              if (vm.successMessage != null) ...[
                MessageBanner(
                  message: vm.successMessage!,
                  type: BannerType.success,
                ),
                const SizedBox(height: 12),
              ],
              if (vm.errorMessage != null) ...[
                MessageBanner(message: vm.errorMessage!),
                const SizedBox(height: 12),
              ],
              if (data == null && vm.isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (data != null) ...[
                _TotalCard(
                  snapshot: data,
                  onEdit: () => _editLimit(
                    title: 'Batas total bulanan',
                    current: data.totalLimit,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Per kategori', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                  decoration: AppDecorations.card(),
                  child: Column(
                    children: [
                      for (final BudgetRow row in data.rows)
                        _CategoryRow(
                          row: row,
                          onTap: () => _editLimit(
                            categoryId: row.categoryId,
                            title: 'Batas ${row.name}',
                            current: row.limit,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Peringatan muncul di 80% dan 100% batas. '
                  'Atur batas di ketukan kategori.',
                  style:
                      textTheme.bodySmall?.copyWith(color: AppColors.coolGray),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.label,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: Icon(AppIcons.chevronLeft),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          onPressed: canGoForward ? onNext : null,
          icon: Icon(AppIcons.chevronRight),
        ),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.snapshot, required this.onEdit});

  final BudgetSnapshot snapshot;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasLimit = snapshot.hasTotalLimit;
    final double ratio = snapshot.totalRatio;
    final double remaining = (snapshot.totalLimit ?? 0) - snapshot.totalSpent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(radius: AppRadius.cardLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Total pengeluaran', style: textTheme.bodyMedium),
              ),
              TextButton(
                onPressed: onEdit,
                child: Text(hasLimit ? 'Ubah batas' : 'Atur batas'),
              ),
            ],
          ),
          CountUpText(
            value: snapshot.totalSpent,
            style: textTheme.headlineSmall,
          ),
          if (hasLimit) ...[
            const SizedBox(height: 12),
            _ProgressBar(ratio: ratio),
            const SizedBox(height: 8),
            Text(
              remaining >= 0
                  ? 'Sisa ${AppFormatters.rupiah(remaining)} dari '
                      '${AppFormatters.rupiah(snapshot.totalLimit!)}'
                  : 'Melewati batas ${AppFormatters.rupiah(-remaining)}',
              style: textTheme.bodySmall?.copyWith(
                color: remaining >= 0 ? AppColors.coolGray : AppColors.error,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Belum ada batas total. Atur agar sisa anggaran terlihat.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.coolGray),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.row, required this.onTap});

  final BudgetRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CategoryStyle style = CategoryStyle.of(row.name);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(style.icon, size: 18, color: style.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(row.name, style: textTheme.bodyLarge),
                ),
                Text(
                  row.hasLimit
                      ? '${AppFormatters.rupiah(row.spent)} / '
                          '${AppFormatters.rupiah(row.limit!)}'
                      : AppFormatters.rupiah(row.spent),
                  style: textTheme.bodySmall,
                ),
              ],
            ),
            if (row.hasLimit) ...[
              const SizedBox(height: 8),
              _ProgressBar(ratio: row.ratio, height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.ratio, this.height = 10});

  final double ratio;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AnimatedBar(ratio: ratio, height: height);
  }
}

/// Lembar isian batas. Mengembalikan false pada onRemove bila dibatalkan.
class _LimitSheet extends StatefulWidget {
  const _LimitSheet({
    required this.title,
    required this.onSave,
    this.current,
    this.onRemove,
  });

  final String title;
  final double? current;
  final Future<bool> Function(double amount) onSave;
  final Future<bool> Function()? onRemove;

  @override
  State<_LimitSheet> createState() => _LimitSheetState();
}

class _LimitSheetState extends State<_LimitSheet> {
  late final TextEditingController _controller;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.current == null
          ? ''
          : AppFormatters.amountInput(widget.current!),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final double? value =
        double.tryParse(_controller.text.replaceAll('.', '').trim());
    if (value == null) return;
    setState(() => _busy = true);
    final bool ok = await widget.onSave(value);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    final Future<bool> Function()? remove = widget.onRemove;
    if (remove == null) return;
    setState(() => _busy = true);
    final bool removed = await remove();
    if (!mounted) return;
    setState(() => _busy = false);
    if (removed) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Batas (Rp)',
            controller: _controller,
            prefixText: 'Rp ',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: 'Simpan',
            icon: AppIcons.check,
            isLoading: _busy,
            onPressed: _save,
          ),
          if (widget.onRemove != null) ...[
            const SizedBox(height: 8),
            CustomButton(
              label: 'Hapus batas',
              variant: CustomButtonVariant.danger,
              onPressed: _busy ? null : _remove,
            ),
          ],
        ],
      ),
    );
  }
}
