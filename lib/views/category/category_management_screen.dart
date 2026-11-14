import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/category_palette.dart';
import '../../core/theme/category_style.dart';
import '../../data/models/category_model.dart';
import '../../viewmodels/category_management_viewmodel.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/theme_illustrations.dart';
import '../widgets/message_banner.dart';

/// Kelola kategori: tambah, ubah nama, ganti ikon dan warna, sembunyikan.
/// Koreksi kategori pada struk akan melatih model untuk kategori ini.
class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CategoryManagementViewModel>().load();
    });
  }

  Future<void> _openEditor({CategoryModel? category}) async {
    final CategoryManagementViewModel vm =
        context.read<CategoryManagementViewModel>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => _CategoryEditorSheet(
        category: category,
        onSave: ({
          required String name,
          required String iconKey,
          required int colorValue,
        }) async {
          final bool ok = category == null
              ? await vm.add(
                  name: name,
                  iconKey: iconKey,
                  colorValue: colorValue,
                )
              : await vm.update(
                  category,
                  name: name,
                  iconKey: iconKey,
                  colorValue: colorValue,
                );
          return ok;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CategoryManagementViewModel vm =
        context.watch<CategoryManagementViewModel>();
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
        actions: [
          IconButton(
            tooltip: 'Tambah kategori',
            onPressed: () => _openEditor(),
            icon: Icon(AppIcons.plus),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const GradientHeader(
              title: 'Kelola Kategori',
              subtitle: 'Sesuaikan kategori dengan kebiasaanmu',
              kind: ThemeArtKind.tags,
            ),
            const SizedBox(height: 16),
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
            Text(
              'Kategori yang disembunyikan tidak muncul saat memilih kategori '
              'barang. Data lama tetap utuh.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.coolGray),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: AppDecorations.card(),
              child: Column(
                children: [
                  for (final CategoryModel category in vm.categories)
                    _CategoryTile(
                      category: category,
                      onEdit: () => _openEditor(category: category),
                      onToggleHidden: (bool visible) => vm.setHidden(
                        category,
                        !visible,
                      ),
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onToggleHidden,
  });

  final CategoryModel category;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleHidden;

  @override
  Widget build(BuildContext context) {
    final CategoryStyle style = CategoryStyle.of(category.name);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Icon(style.icon, size: 18, color: style.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category.name,
              style: textTheme.bodyLarge?.copyWith(
                color: category.isHidden ? AppColors.coolGray : null,
              ),
            ),
          ),
          Tooltip(
            message: category.isHidden ? 'Tampilkan' : 'Sembunyikan',
            child: Switch(
              value: !category.isHidden,
              onChanged: onToggleHidden,
            ),
          ),
          IconButton(
            tooltip: 'Ubah',
            onPressed: onEdit,
            icon: Icon(AppIcons.pencil, color: AppColors.coolGray),
          ),
        ],
      ),
    );
  }
}

typedef _SaveCallback = Future<bool> Function({
  required String name,
  required String iconKey,
  required int colorValue,
});

class _CategoryEditorSheet extends StatefulWidget {
  const _CategoryEditorSheet({required this.onSave, this.category});

  final CategoryModel? category;
  final _SaveCallback onSave;

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  late final TextEditingController _name;
  late String _iconKey;
  late int _colorValue;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final CategoryModel? c = widget.category;
    _name = TextEditingController(text: c?.name ?? '');
    _iconKey = c?.iconKey ?? CategoryPalette.icons.keys.first;
    _colorValue = c?.colorValue ?? CategoryPalette.colors.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final bool ok = await widget.onSave(
      name: _name.text,
      iconKey: _iconKey,
      colorValue: _colorValue,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isNew = widget.category == null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isNew ? 'Kategori baru' : 'Ubah kategori',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Nama kategori',
              controller: _name,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            Text('Ikon', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final MapEntry<String, IconData> entry
                    in CategoryPalette.icons.entries)
                  ChoiceChip(
                    label: Icon(entry.value, size: 18),
                    selected: _iconKey == entry.key,
                    onSelected: (_) => setState(() => _iconKey = entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Warna', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final int color in CategoryPalette.colors)
                  GestureDetector(
                    onTap: () => setState(() => _colorValue = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(0xFF000000 | color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _colorValue == color
                              ? AppColors.slateDark
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Simpan',
              icon: AppIcons.check,
              isLoading: _busy,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
