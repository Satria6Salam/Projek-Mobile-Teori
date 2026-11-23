import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/shopping_plan_model.dart';
import '../../viewmodels/shopping_plan_viewmodel.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/empty_state.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/message_banner.dart';
import '../widgets/segmented_tabs.dart';
import '../widgets/theme_illustrations.dart';

/// Rencana Belanja: catat barang yang akan dibeli. Setelah belanja, scan
/// struknya; barang yang ada di struk otomatis pindah ke "sudah dibeli",
/// sedangkan yang tidak dibeli tetap di daftar rencana.
class ShoppingPlanScreen extends StatefulWidget {
  const ShoppingPlanScreen({super.key});

  @override
  State<ShoppingPlanScreen> createState() => _ShoppingPlanScreenState();
}

class _ShoppingPlanScreenState extends State<ShoppingPlanScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  int _quantity = 1;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ShoppingPlanViewModel vm = context.read<ShoppingPlanViewModel>();
      vm.clearMessages();
      vm.load();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final ShoppingPlanViewModel vm = context.read<ShoppingPlanViewModel>();
    final bool ok =
        await vm.add(_nameController.text, quantity: _quantity.toDouble());
    if (!mounted || !ok) return;
    _nameController.clear();
    setState(() => _quantity = 1);
    _nameFocus.requestFocus();
  }

  Future<void> _clearBought() async {
    final ShoppingPlanViewModel vm = context.read<ShoppingPlanViewModel>();
    final bool ok = await showConfirmDialog(
      context,
      title: 'Bersihkan riwayat?',
      message:
          'Semua barang yang sudah dibeli akan dihapus dari rekap. Barang yang '
          'belum dibeli tetap ada di rencana.',
      confirmLabel: 'Bersihkan',
      isDestructive: true,
    );
    if (ok) await vm.clearBought();
  }

  @override
  Widget build(BuildContext context) {
    final ShoppingPlanViewModel vm = context.watch<ShoppingPlanViewModel>();
    final List<ShoppingPlanModel> pending = vm.pending;
    final List<ShoppingPlanModel> bought = vm.bought;

    return Scaffold(
      appBar: AppBar(title: const Text('Rencana Belanja')),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: RefreshIndicator(
            onRefresh: vm.load,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                GradientHeader(
                  title: 'Rencana Belanja',
                  subtitle: 'Catat dulu, lalu scan struk setelah belanja',
                  kind: ThemeArtKind.cart,
                  trailing: _HeaderPill(
                    text: '${pending.length} belum · ${bought.length} sudah',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedTabs(
                  labels: const <String>['Rencana', 'Rekap'],
                  selectedIndex: _tab,
                  onChanged: (int i) => setState(() => _tab = i),
                ),
                const SizedBox(height: AppSpacing.md),
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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_tab),
                    child: _tab == 0
                        ? _planTab(vm, pending)
                        : _recapTab(vm, pending, bought),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ rencana

  Widget _planTab(ShoppingPlanViewModel vm, List<ShoppingPlanModel> pending) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: AppDecorations.card(radius: AppRadius.cardLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tambah barang', style: textTheme.titleMedium),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Nama barang',
                hint: 'mis. Telur ayam, Gula pasir',
                controller: _nameController,
                prefixIcon: AppIcons.shoppingCart,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _add(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Jumlah', style: textTheme.bodyMedium),
                  const Spacer(),
                  _Stepper(
                    value: _quantity,
                    onChanged: (int v) => setState(() => _quantity = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'Tambah ke Rencana',
                icon: AppIcons.plus,
                onPressed: _add,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _HintCard(onScan: () => context.push(AppRoutes.scan)),
        const SizedBox(height: AppSpacing.md),
        if (pending.isEmpty && !vm.isLoading)
          const EmptyState(
            art: ThemeArtKind.cart,
            icon: Icons.shopping_cart_outlined,
            title: 'Belum ada rencana belanja',
            message: 'Tambahkan barang yang ingin dibeli. Setelah belanja, '
                'scan struknya dan barang yang terbeli akan dicoret otomatis.',
          )
        else ...[
          Text(
            'Akan dibeli (${pending.length})',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < pending.length; i++)
            FadeSlideIn(
              delay: Duration(milliseconds: 40 * i),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PendingTile(
                  plan: pending[i],
                  onBought: () => vm.setBought(pending[i], true),
                  onDelete: () => vm.delete(pending[i]),
                ),
              ),
            ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------- rekap

  Widget _recapTab(
    ShoppingPlanViewModel vm,
    List<ShoppingPlanModel> pending,
    List<ShoppingPlanModel> bought,
  ) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    if (vm.totalCount == 0 && !vm.isLoading) {
      return const EmptyState(
        art: ThemeArtKind.cart,
        icon: Icons.shopping_cart_outlined,
        title: 'Rekap masih kosong',
        message: 'Rekap muncul setelah Anda menambahkan barang ke rencana.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RecapSummary(
          boughtCount: bought.length,
          pendingCount: pending.length,
          progress: vm.progress,
          spent: vm.spentOnPlan,
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionTitle(
          icon: AppIcons.circleCheck,
          color: AppColors.emerald,
          title: 'Sudah dibeli',
          count: bought.length,
        ),
        const SizedBox(height: 8),
        if (bought.isEmpty)
          _Muted('Belum ada barang rencana yang terbeli.')
        else
          for (final ShoppingPlanModel plan in bought)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BoughtTile(
                plan: plan,
                onUndo: () => vm.setBought(plan, false),
              ),
            ),
        const SizedBox(height: AppSpacing.md),
        _SectionTitle(
          icon: AppIcons.circle,
          color: AppColors.warningDeep,
          title: 'Belum dibeli',
          count: pending.length,
        ),
        const SizedBox(height: 8),
        if (pending.isEmpty)
          _Muted('Semua barang rencana sudah dibeli.')
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: AppDecorations.card(),
            child: Column(
              children: [
                for (final ShoppingPlanModel plan in pending)
                  ListTile(
                    dense: true,
                    leading: Icon(
                      AppIcons.circle,
                      size: 18,
                      color: AppColors.warningDeep,
                    ),
                    title: Text(plan.name, style: textTheme.bodyLarge),
                    trailing: Text(
                      _qtyLabel(plan.quantity),
                      style: textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        if (bought.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          CustomButton(
            label: 'Bersihkan Riwayat Sudah Dibeli',
            icon: AppIcons.trash,
            variant: CustomButtonVariant.secondary,
            onPressed: _clearBought,
          ),
        ],
      ],
    );
  }
}

String _qtyLabel(double qty) {
  final String n =
      qty == qty.roundToDouble() ? qty.round().toString() : qty.toString();
  return '$n buah';
}

// ------------------------------------------------------------- widgets

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, VoidCallback? onTap) {
      return Material(
        color: onTap == null ? AppColors.border : AppColors.mint,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 16, color: AppColors.emeraldDeep),
          ),
        ),
      );
    }

    return Row(
      children: [
        button(AppIcons.minus, value > 1 ? () => onChanged(value - 1) : null),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        button(AppIcons.plus, value < 99 ? () => onChanged(value + 1) : null),
      ],
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(AppIcons.sparkles, color: AppColors.emeraldDeep, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sudah belanja? Scan struknya. Barang yang ada di struk '
              'otomatis dicoret dari rencana.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.emeraldDeep,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onScan, child: const Text('Scan')),
        ],
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({
    required this.plan,
    required this.onBought,
    required this.onDelete,
  });

  final ShoppingPlanModel plan;
  final VoidCallback onBought;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Dismissible(
      key: ValueKey<int?>(plan.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.errorTint,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Icon(AppIcons.trash, color: AppColors.error),
      ),
      child: Container(
        decoration: AppDecorations.card(),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
          leading: IconButton(
            tooltip: 'Tandai sudah dibeli',
            onPressed: onBought,
            icon: Icon(AppIcons.circle, color: AppColors.coolGray),
          ),
          title: Text(plan.name, style: textTheme.titleMedium),
          subtitle: Text(
            'Dicatat ${AppFormatters.shortDate(plan.createdAt)}',
            style: textTheme.bodySmall,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.emeraldTint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _qtyLabel(plan.quantity),
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.emeraldDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoughtTile extends StatelessWidget {
  const _BoughtTile({required this.plan, required this.onUndo});

  final ShoppingPlanModel plan;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final DateTime? at = plan.boughtAt;
    final String source = plan.boughtName == null
        ? 'Ditandai manual'
        : 'Di struk: ${plan.boughtName}';
    return Container(
      decoration: AppDecorations.card(),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
        leading: Icon(AppIcons.circleCheck, color: AppColors.emerald),
        title: Text(
          plan.name,
          style: textTheme.titleMedium?.copyWith(
            decoration: TextDecoration.lineThrough,
            decorationColor: AppColors.coolGray,
          ),
        ),
        subtitle: Text(
          at == null ? source : '$source · ${AppFormatters.shortDate(at)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (plan.boughtPrice != null)
              Text(
                AppFormatters.rupiah(plan.boughtPrice!),
                style: AppTextStyles.amount(size: 14),
              ),
            IconButton(
              tooltip: 'Kembalikan ke rencana',
              onPressed: onUndo,
              icon: Icon(AppIcons.undo, size: 18, color: AppColors.coolGray),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecapSummary extends StatelessWidget {
  const _RecapSummary({
    required this.boughtCount,
    required this.pendingCount,
    required this.progress,
    required this.spent,
  });

  final int boughtCount;
  final int pendingCount;
  final double progress;
  final double spent;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int total = boughtCount + pendingCount;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(radius: AppRadius.cardLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$boughtCount dari $total barang sudah dibeli',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double value, Widget? child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  color: AppColors.emerald,
                  backgroundColor: AppColors.border,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Sudah dibeli',
                  value: '$boughtCount',
                  color: AppColors.emerald,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Belum dibeli',
                  value: '$pendingCount',
                  color: AppColors.warningDeep,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Belanja rencana',
                  value: AppFormatters.rupiah(spent),
                  color: AppColors.slateDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.color,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final Color color;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          '$title ($count)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppColors.coolGray),
      ),
    );
  }
}
