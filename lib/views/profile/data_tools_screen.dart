import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/month_utils.dart';
import '../../viewmodels/data_tools_viewmodel.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/custom_button.dart';
import '../widgets/message_banner.dart';
import '../widgets/theme_illustrations.dart';

/// Ekspor laporan bulanan (CSV), cadangan basis data, dan pemulihan.
class DataToolsScreen extends StatefulWidget {
  const DataToolsScreen({super.key});

  @override
  State<DataToolsScreen> createState() => _DataToolsScreenState();
}

class _DataToolsScreenState extends State<DataToolsScreen> {
  DateTime _month = MonthUtils.startOf(DateTime.now());

  bool get _canGoForward {
    final DateTime now = DateTime.now();
    return _month.isBefore(DateTime(now.year, now.month));
  }

  Future<void> _restore() async {
    final DataToolsViewModel vm = context.read<DataToolsViewModel>();
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Pulihkan dari cadangan?',
      message: 'Seluruh data sekarang akan diganti dengan isi cadangan. '
          'Setelah itu Anda perlu login kembali.',
      confirmLabel: 'Pulihkan',
      isDestructive: true,
    );
    if (!confirmed) return;

    final String? path = await vm.pickBackup();
    if (path == null) return;
    await vm.restoreFrom(path);
  }

  @override
  Widget build(BuildContext context) {
    final DataToolsViewModel vm = context.watch<DataToolsViewModel>();
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ekspor & Cadangan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const GradientHeader(
              title: 'Ekspor & Cadangan',
              subtitle: 'Simpan laporan dan data dengan aman',
              kind: ThemeArtKind.backup,
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
            _Section(
              title: 'Laporan bulanan (CSV)',
              description:
                  'Berisi tanggal, merchant, kategori, total, dan sumber '
                  '(struk atau manual). Bisa dibuka di Excel atau Google Sheets.',
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(() {
                          _month = DateTime(_month.year, _month.month - 1);
                        }),
                        icon: Icon(AppIcons.chevronLeft),
                      ),
                      Expanded(
                        child: Text(
                          AppFormatters.monthYear(_month),
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: _canGoForward
                            ? () => setState(() {
                                  _month =
                                      DateTime(_month.year, _month.month + 1);
                                })
                            : null,
                        icon: Icon(AppIcons.chevronRight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CustomButton(
                    label: 'Bagikan laporan',
                    icon: AppIcons.fileText,
                    isLoading: vm.isBusy,
                    onPressed: () => vm.exportMonth(_month),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Cadangan database',
              description:
                  'Menyalin seluruh data ke berkas .db lalu membagikannya '
                  '(misalnya ke Google Drive atau email).',
              child: CustomButton(
                label: 'Buat & bagikan cadangan',
                icon: AppIcons.folderOpen,
                isLoading: vm.isBusy,
                onPressed: () => vm.createBackup(),
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Pulihkan dari cadangan',
              description: 'Mengganti seluruh data dengan berkas cadangan. '
                  'Data sekarang tidak bisa dikembalikan setelah dipulihkan.',
              child: CustomButton(
                label: 'Pulihkan',
                icon: AppIcons.refresh,
                variant: CustomButtonVariant.danger,
                isLoading: vm.isBusy,
                onPressed: _restore,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(radius: AppRadius.cardLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            description,
            style: textTheme.bodySmall?.copyWith(color: AppColors.coolGray),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
