import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../services/image_format_service.dart';
import '../../viewmodels/scan_viewmodel.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/message_banner.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/processing_overlay.dart';
import '../widgets/scan_animation.dart';

/// Pemindai Struk (UC-02): pilih sumber gambar (Kamera, Galeri, atau File),
/// lalu proses OCR, parsing, dan klasifikasi. Setelah siap, pengguna dibawa ke Pratinjau.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ScanViewModel scan = context.read<ScanViewModel>();
      scan.reset();
      scan.loadCategories();
    });
  }

  Future<void> _pick(ScanSource source) async {
    final ScanViewModel scan = context.read<ScanViewModel>();
    await scan.pickAndProcess(source);
    if (!mounted) return;
    if (scan.status == ScanStatus.ready) {
      context.pushReplacement(AppRoutes.preview);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ScanViewModel scan = context.watch<ScanViewModel>();
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool busy = scan.isBusy;
    final String? error =
        scan.status == ScanStatus.error ? scan.errorMessage : null;

    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Scan Struk')),
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeSlideIn(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFECFDF5), Color(0xFFF0FDFA)],
                          ),
                          borderRadius:
                              BorderRadius.circular(AppRadius.cardLarge),
                        ),
                        child: Column(
                          children: [
                            const ScanAnimation(),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Pindai struk belanja Anda',
                              style: textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Teks dibaca otomatis di perangkat Anda tanpa internet, lalu setiap barang dikelompokkan ke kategorinya.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.coolGray,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      MessageBanner(
                        message: error,
                        actionLabel: 'Tutup',
                        onAction: scan.reset,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: _SourceCard(
                        icon: AppIcons.camera,
                        title: 'Kamera',
                        subtitle: 'Ambil foto struk secara langsung',
                        enabled: !busy,
                        onTap: () => _pick(ScanSource.camera),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 160),
                      child: _SourceCard(
                        icon: AppIcons.image,
                        title: 'Galeri',
                        subtitle: 'Pilih foto struk yang sudah tersimpan',
                        enabled: !busy,
                        onTap: () => _pick(ScanSource.gallery),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 240),
                      child: _SourceCard(
                        icon: AppIcons.folderOpen,
                        title: 'File',
                        subtitle: 'Unggah dari penyimpanan perangkat',
                        enabled: !busy,
                        onTap: () => _pick(ScanSource.file),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 300),
                      child: const _FormatsCard(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 360),
                      child: const _TipsCard(),
                    ),
                  ],
                ),
              ),
            ),
            if (scan.isProcessing)
              ProcessingOverlay(
                message: scan.progressMessage ?? 'Memproses...',
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return PressableScale(
      enabled: enabled,
      child: Container(
        decoration: AppDecorations.card(radius: AppRadius.cardLarge),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.cardLarge),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Icon(icon, color: AppColors.white),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(subtitle, style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Icon(AppIcons.chevronRight, color: AppColors.coolGray),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormatsCard extends StatelessWidget {
  const _FormatsCard();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(radius: AppRadius.cardLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Format file yang didukung', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final String ext in ImageFormatService.supportedExtensions)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    ext.toUpperCase(),
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.emeraldDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Ukuran maksimal 25 MB per file.', style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  static const List<String> _tips = <String>[
    'Pastikan pencahayaan cukup dan tidak ada bayangan',
    'Letakkan struk pada permukaan rata dan tidak terlipat',
    'Seluruh struk harus masuk ke dalam bingkai foto',
    'Tahan kamera agar gambar tajam dan tidak buram',
  ];

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.emeraldTint,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tips foto yang baik',
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.emeraldDeep,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final String tip in _tips)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      AppIcons.check,
                      size: 16,
                      color: AppColors.emeraldDeep,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.emeraldDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
