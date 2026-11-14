import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/recurring_transaction_model.dart';
import '../../viewmodels/manual_entry_viewmodel.dart';
import '../widgets/category_selector.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/date_input_field.dart';
import '../widgets/theme_illustrations.dart';
import '../widgets/message_banner.dart';

/// Catat transaksi tanpa struk (parkir, jajan), atau jadikan berulang
/// tiap bulan (internet, Netflix). Daftar berulang ada di bagian bawah.
class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final TextEditingController _merchant = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  DateTime? _date = DateTime.now();
  int? _categoryId;
  bool _recurring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ManualEntryViewModel>().load();
    });
  }

  @override
  void dispose() {
    _merchant.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final ManualEntryViewModel vm = context.read<ManualEntryViewModel>();
    final bool ok = await vm.save(
      merchant: _merchant.text,
      amountText: _amount.text,
      date: _date ?? DateTime.now(),
      categoryId: _categoryId,
      notes: _notes.text,
      recurring: _recurring,
    );
    if (ok && mounted) {
      _merchant.clear();
      _amount.clear();
      _notes.clear();
      setState(() {
        _recurring = false;
        _date = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ManualEntryViewModel vm = context.watch<ManualEntryViewModel>();
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Catat Manual')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const GradientHeader(
              title: 'Catat Manual',
              subtitle: 'Parkir, jajan, atau langganan bulanan',
              kind: ThemeArtKind.receipt,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppDecorations.card(radius: AppRadius.cardLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  CustomTextField(
                    label: 'Nama tempat / keterangan',
                    hint: 'Contoh: Parkir Mall',
                    controller: _merchant,
                    prefixIcon: AppIcons.store,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Jumlah',
                    controller: _amount,
                    prefixText: 'Rp ',
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  const SizedBox(height: 12),
                  DateInputField(
                    label: 'Tanggal',
                    value: _date,
                    onChanged: (DateTime? value) =>
                        setState(() => _date = value),
                  ),
                  const SizedBox(height: 16),
                  CategorySelector(
                    categories: vm.categories,
                    selectedId: _categoryId,
                    onSelected: (int id) => setState(() => _categoryId = id),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Catatan (opsional)',
                    controller: _notes,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Berulang tiap bulan'),
                    subtitle: const Text(
                      'Dibuat otomatis pada tanggal yang sama setiap bulan.',
                    ),
                    value: _recurring,
                    onChanged: (bool value) =>
                        setState(() => _recurring = value),
                  ),
                  const SizedBox(height: 8),
                  CustomButton(
                    label: 'Simpan',
                    icon: AppIcons.check,
                    isLoading: vm.isSaving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Transaksi berulang', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            if (vm.recurringItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Belum ada. Aktifkan "Berulang tiap bulan" saat mencatat.',
                  style:
                      textTheme.bodySmall?.copyWith(color: AppColors.coolGray),
                ),
              )
            else
              Container(
                decoration: AppDecorations.card(),
                child: Column(
                  children: [
                    for (final RecurringTransactionModel item
                        in vm.recurringItems)
                      _RecurringTile(
                        item: item,
                        categoryName: vm.categoryNameOf(item.categoryId),
                        onToggle: (bool value) => vm.setRecurringActive(
                          item.id!,
                          value,
                        ),
                        onDelete: () async {
                          final bool ok = await showConfirmDialog(
                            context,
                            title: 'Hapus transaksi berulang?',
                            message:
                                'Pembuatan otomatis berhenti. Transaksi yang sudah ada tetap tersimpan.',
                            confirmLabel: 'Hapus',
                            isDestructive: true,
                          );
                          if (ok) await vm.deleteRecurring(item.id!);
                        },
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecurringTile extends StatelessWidget {
  const _RecurringTile({
    required this.item,
    required this.categoryName,
    required this.onToggle,
    required this.onDelete,
  });

  final RecurringTransactionModel item;
  final String categoryName;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.merchantName, style: textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  '${AppFormatters.rupiah(item.totalAmount)} • tiap tanggal '
                  '${item.dayOfMonth} • $categoryName',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(value: item.isActive, onChanged: onToggle),
          IconButton(
            tooltip: 'Hapus',
            onPressed: onDelete,
            icon: Icon(AppIcons.trash, color: AppColors.coolGray),
          ),
        ],
      ),
    );
  }
}
