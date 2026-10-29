import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/thousands_separator_formatter.dart';
import '../../viewmodels/scan_viewmodel.dart';
import '../widgets/ai_result_badge.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/date_input_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/grouped_items_section.dart';
import '../widgets/item_editor_sheet.dart';
import '../widgets/message_banner.dart';
import '../widgets/raw_text_section.dart';
import '../widgets/receipt_image_card.dart';

/// Form Pratinjau & Validasi (UC-04): pengguna memeriksa dan menyunting hasil
/// OCR + AI (merchant, tanggal, total, serta nama, harga, dan kategori tiap barang)
/// sebelum data dikunci ke basis data.
class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late final TextEditingController _merchantController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final ScanDraft? draft = context.read<ScanViewModel>().draft;
    final double? amount = draft?.totalAmount;
    _merchantController =
        TextEditingController(text: draft?.merchantName ?? '');
    _amountController = TextEditingController(
      text: amount == null ? '' : AppFormatters.amountInput(amount),
    );
    _notesController = TextEditingController(text: draft?.notes ?? '');
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _useItemsTotal(ScanViewModel scan) {
    scan.useItemsTotal();
    final double? total = scan.draft?.totalAmount;
    _amountController.text =
        total == null ? '' : AppFormatters.amountInput(total);
  }

  Future<void> _save() async {
    final ScanViewModel scan = context.read<ScanViewModel>();
    FocusScope.of(context).unfocus();

    final bool ok = await scan.saveTransaction();
    if (!mounted || !ok) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil disimpan')),
    );
    context.go(AppRoutes.dashboard);
  }

  Future<void> _cancel() async {
    final ScanViewModel scan = context.read<ScanViewModel>();
    if (scan.isSaving) return;

    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Batalkan pencatatan?',
      message: 'Data hasil pemindaian belum disimpan dan akan dibuang.',
      confirmLabel: 'Ya, Batalkan',
      cancelLabel: 'Lanjut Mengedit',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    scan.cancel();
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final ScanViewModel scan = context.watch<ScanViewModel>();
    final ScanDraft? draft = scan.draft;

    if (draft == null) {
      // Setelah tersimpan, tampilkan loading singkat sampai navigasi selesai.
      if (scan.status == ScanStatus.saved) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Pratinjau Transaksi')),
        body: SafeArea(
          child: Center(
            child: EmptyState(
              icon: AppIcons.receipt,
              title: 'Tidak ada data pratinjau',
              message: 'Pindai struk terlebih dahulu untuk melihat hasilnya.',
              actionLabel: 'Kembali ke Dasbor',
              onAction: () => context.go(AppRoutes.dashboard),
            ),
          ),
        ),
      );
    }

    final Map<String, String> errors = scan.formErrors;
    final DateTime? date = draft.transactionDate;
    final String? saveError = scan.errorMessage;
    final int uncertain =
        draft.items.where((DraftItem i) => !i.isConfident).length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Pratinjau Transaksi')),
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeSlideIn(
                      child: ReceiptImageCard(imagePath: draft.imagePath)),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AiResultBadge(
                      probability: draft.classification.probability,
                      isConfident: uncertain == 0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  MessageBanner(
                    message: uncertain == 0
                        ? 'Periksa hasil bacaan di bawah. Anda dapat mengubah nama, harga, dan kategori setiap barang.'
                        : '$uncertain barang bertanda "Perlu dicek" karena AI kurang yakin dengan kategorinya.',
                    type: uncertain == 0
                        ? BannerType.success
                        : BannerType.warning,
                  ),
                  if (saveError != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    MessageBanner(message: saveError),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration:
                          AppDecorations.card(radius: AppRadius.cardLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            label: 'Nama Toko / Merchant',
                            hint: 'Contoh: Indomaret',
                            controller: _merchantController,
                            prefixIcon: AppIcons.store,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            errorText: errors[ScanViewModel.fieldMerchant],
                            onChanged: scan.updateMerchantName,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          DateInputField(
                            label: 'Tanggal Transaksi (hari, bulan, tahun)',
                            value: date,
                            errorText: errors[ScanViewModel.fieldDate],
                            onChanged: scan.updateTransactionDate,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          CustomTextField(
                            label: 'Total Struk',
                            hint: '0',
                            controller: _amountController,
                            prefixText: 'Rp ',
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [ThousandsSeparatorFormatter()],
                            errorText: errors[ScanViewModel.fieldAmount],
                            onChanged: scan.updateTotalAmountText,
                          ),
                          if (scan.hasTotalMismatch) ...[
                            const SizedBox(height: AppSpacing.sm),
                            MessageBanner(
                              message:
                                  'Jumlah harga barang ${AppFormatters.rupiah(scan.itemsTotal)} berbeda dari total struk. Bisa jadi ada pajak, diskon, atau biaya lain.',
                              type: BannerType.warning,
                              actionLabel: 'Samakan dengan jumlah barang',
                              onAction: () => _useItemsTotal(scan),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          CustomTextField(
                            label: 'Catatan (opsional)',
                            hint: 'Tambahkan catatan',
                            controller: _notesController,
                            maxLines: 2,
                            textInputAction: TextInputAction.newline,
                            keyboardType: TextInputType.multiline,
                            onChanged: scan.updateNotes,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GroupedItemsSection(
                    groups: scan.groupedItems,
                    itemCount: draft.items.length,
                    errorText: errors[ScanViewModel.fieldItems],
                    onEdit: (DraftItem item) =>
                        showItemEditorSheet(context, item: item),
                    onAdd: () => showItemEditorSheet(context),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  RawTextSection(rawText: draft.rawText),
                  const SizedBox(height: AppSpacing.lg),
                  CustomButton(
                    label: 'Simpan Transaksi',
                    icon: AppIcons.check,
                    isLoading: scan.isSaving,
                    onPressed: _save,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CustomButton(
                    label: 'Batal',
                    variant: CustomButtonVariant.secondary,
                    onPressed: scan.isSaving ? null : _cancel,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
