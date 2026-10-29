import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/thousands_separator_formatter.dart';
import '../../viewmodels/scan_viewmodel.dart';
import 'category_selector.dart';
import 'custom_button.dart';
import 'custom_textfield.dart';

/// Lembar bawah untuk menambah atau menyunting satu barang:
/// nama, jumlah, harga satuan, dan kategori.
Future<void> showItemEditorSheet(BuildContext context, {DraftItem? item}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) => _ItemEditor(item: item),
  );
}

class _ItemEditor extends StatefulWidget {
  const _ItemEditor({this.item});

  final DraftItem? item;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _qtyController;
  late final TextEditingController _priceController;
  int? _categoryId;
  bool _categoryTouched = false;
  final Map<String, String> _errors = <String, String>{};

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final DraftItem? item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _qtyController = TextEditingController(
      text: item == null
          ? '1'
          : (item.quantity == item.quantity.roundToDouble()
              ? item.quantity.round().toString()
              : item.quantity.toString()),
    );
    _priceController = TextEditingController(
      text: item == null ? '' : AppFormatters.amountInput(item.unitPrice),
    );
    _categoryId = item?.categoryId;
    _categoryTouched = item != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  double? get _quantity =>
      double.tryParse(_qtyController.text.trim().replaceAll(',', '.'));

  double? get _unitPrice =>
      ScanViewModel.parseAmountInput(_priceController.text);

  double get _total => (_quantity ?? 0) * (_unitPrice ?? 0);

  /// Saran kategori otomatis dari nama barang selama pengguna belum memilih manual.
  void _onNameChanged(String value) {
    if (_errors.remove('name') != null) setState(() {});
    if (_categoryTouched) return;
    final int? suggested =
        context.read<ScanViewModel>().suggestCategoryId(value);
    if (suggested != null && suggested != _categoryId) {
      setState(() => _categoryId = suggested);
    }
  }

  void _save() {
    final ScanViewModel scan = context.read<ScanViewModel>();
    final Map<String, String> errors = <String, String>{};

    final String name = _nameController.text.trim();
    if (RegExp(r'[A-Za-z]').allMatches(name).length < 2) {
      errors['name'] = 'Nama barang wajib diisi';
    }
    final double? qty = _quantity;
    if (qty == null || qty <= 0) errors['qty'] = 'Jumlah harus lebih dari 0';
    final double? price = _unitPrice;
    if (price == null || price <= 0) {
      errors['price'] = 'Harga harus lebih dari 0';
    }
    final int? category = _categoryId;
    if (category == null) errors['category'] = 'Pilih kategori';

    if (errors.isNotEmpty || qty == null || price == null || category == null) {
      setState(() {
        _errors
          ..clear()
          ..addAll(errors);
      });
      return;
    }

    final DraftItem? existing = widget.item;
    if (existing == null) {
      scan.addItem(
        name: name,
        quantity: qty,
        unitPrice: price,
        categoryId: category,
      );
    } else {
      scan.updateItem(
        existing.localId,
        name: name,
        quantity: qty,
        unitPrice: price,
        categoryId: category,
      );
    }
    Navigator.of(context).pop();
  }

  void _delete() {
    final DraftItem? existing = widget.item;
    if (existing == null) return;
    context.read<ScanViewModel>().removeItem(existing.localId);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ScanViewModel scan = context.watch<ScanViewModel>();

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing ? 'Ubah Barang' : 'Tambah Barang',
                        style: textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(AppIcons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  label: 'Nama Barang',
                  hint: 'Contoh: Indomie Goreng',
                  controller: _nameController,
                  prefixIcon: AppIcons.tag,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  errorText: _errors['name'],
                  onChanged: _onNameChanged,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        label: 'Jumlah',
                        controller: _qtyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        errorText: _errors['qty'],
                        onChanged: (_) => setState(() => _errors.remove('qty')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: CustomTextField(
                        label: 'Harga Satuan',
                        hint: '0',
                        controller: _priceController,
                        prefixText: 'Rp ',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [ThousandsSeparatorFormatter()],
                        errorText: _errors['price'],
                        onChanged: (_) =>
                            setState(() => _errors.remove('price')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total: ${AppFormatters.rupiah(_total)}',
                    style: AppTextStyles.amount(
                      size: 15,
                      color: AppColors.emeraldDeep,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                CategorySelector(
                  categories: scan.categories,
                  selectedId: _categoryId,
                  errorText: _errors['category'],
                  onSelected: (int id) => setState(() {
                    _categoryId = id;
                    _categoryTouched = true;
                    _errors.remove('category');
                  }),
                ),
                if (!_categoryTouched && _categoryId != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Kategori disarankan AI dari nama barang',
                    style: textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                CustomButton(
                  label: _isEditing ? 'Simpan Perubahan' : 'Tambah Barang',
                  icon: AppIcons.check,
                  onPressed: _save,
                ),
                if (_isEditing) ...[
                  const SizedBox(height: AppSpacing.sm),
                  CustomButton(
                    label: 'Hapus Barang',
                    icon: AppIcons.trash,
                    variant: CustomButtonVariant.danger,
                    onPressed: _delete,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
