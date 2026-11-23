import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/message_banner.dart';
import '../widgets/theme_illustrations.dart';

/// Pengaturan & Profil: akun pengguna, informasi aplikasi, dan logout.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final ProfileViewModel profile = context.read<ProfileViewModel>();
    _nameController = TextEditingController(text: profile.name);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileViewModel>().clearMessages();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    FocusScope.of(context).unfocus();
    await context.read<ProfileViewModel>().updateName(_nameController.text);
  }

  Future<void> _confirmLogout() async {
    final ProfileViewModel profile = context.read<ProfileViewModel>();
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Keluar dari akun?',
      message: 'Anda perlu login kembali untuk mengakses data transaksi.',
      confirmLabel: 'Logout',
      isDestructive: true,
    );
    if (!confirmed) return;
    await profile.logout();
  }

  @override
  Widget build(BuildContext context) {
    final ProfileViewModel profile = context.watch<ProfileViewModel>();
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String name = profile.name.trim();
    final String initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final String? error = profile.errorMessage;
    final String? success = profile.successMessage;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan & Profil')),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kartu profil
                FadeSlideIn(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emeraldDeep.withValues(alpha: 0.3),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned(
                          right: -40,
                          top: -40,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.white.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.white,
                                  border: Border.all(
                                    color: AppColors.emeraldLight,
                                    width: 3,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  initial,
                                  style: textTheme.headlineMedium?.copyWith(
                                    color: AppColors.emeraldDeep,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.isEmpty ? 'Pengguna' : name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.titleLarge?.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      profile.email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.white
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.white
                                            .withValues(alpha: 0.16),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            AppIcons.shieldCheck,
                                            size: 14,
                                            color: AppColors.white,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Data aman di perangkat',
                                            style:
                                                textTheme.labelMedium?.copyWith(
                                              color: AppColors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const ThemeArt(
                                kind: ThemeArtKind.profile,
                                size: 72,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Ubah nama
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: AppDecorations.card(radius: AppRadius.cardLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Akun', style: textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      if (success != null) ...[
                        MessageBanner(
                          message: success,
                          type: BannerType.success,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (error != null) ...[
                        MessageBanner(message: error),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      CustomTextField(
                        label: 'Nama Lengkap',
                        controller: _nameController,
                        prefixIcon: AppIcons.user,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveName(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CustomButton(
                        label: 'Simpan Perubahan',
                        icon: AppIcons.check,
                        isLoading: profile.isSaving,
                        onPressed: _saveName,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Informasi aplikasi
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: AppDecorations.card(radius: AppRadius.cardLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Informasi Aplikasi', style: textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.md),
                      _InfoRow(
                        icon: AppIcons.wifiOff,
                        label: 'Mode pemrosesan',
                        value: 'On-device, tanpa internet',
                      ),
                      _InfoRow(
                        icon: AppIcons.scanLine,
                        label: 'Mesin OCR',
                        value: 'Google ML Kit Text Recognition',
                      ),
                      _InfoRow(
                        icon: AppIcons.cpu,
                        label: 'Klasifikasi kategori',
                        value: 'TF-IDF & Multinomial Naive Bayes',
                      ),
                      _InfoRow(
                        icon: AppIcons.info,
                        label: 'Versi aplikasi',
                        value: '1.0.0',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Fitur lanjutan (UAS).
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: AppDecorations.card(radius: AppRadius.cardLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fitur Lanjutan', style: textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      _FeatureTile(
                        icon: AppIcons.piggyBank,
                        color: const Color(0xFF16855A),
                        title: 'Anggaran',
                        subtitle: 'Batas bulanan total dan per kategori',
                        onTap: () => context.push(AppRoutes.budget),
                      ),
                      _FeatureTile(
                        icon: AppIcons.shoppingCart,
                        color: const Color(0xFF0EA5E9),
                        title: 'Rencana Belanja',
                        subtitle: 'Catat dulu, coret otomatis saat scan struk',
                        onTap: () => context.push(AppRoutes.shoppingPlan),
                      ),
                      _FeatureTile(
                        icon: AppIcons.penLine,
                        color: const Color(0xFF3B82F6),
                        title: 'Catat Manual & Berulang',
                        subtitle: 'Parkir, jajan, langganan bulanan',
                        onTap: () => context.push(AppRoutes.manualEntry),
                      ),
                      _FeatureTile(
                        icon: AppIcons.tags,
                        color: const Color(0xFFF59E0B),
                        title: 'Kelola Kategori',
                        subtitle: 'Nama, ikon, warna, dan sembunyikan',
                        onTap: () => context.push(AppRoutes.categories),
                      ),
                      _FeatureTile(
                        icon: AppIcons.bell,
                        color: const Color(0xFFEC4899),
                        title: 'Notifikasi',
                        subtitle: 'Pengingat harian dan ringkasan mingguan',
                        onTap: () => context.push(AppRoutes.notifications),
                      ),
                      _FeatureTile(
                        icon: AppIcons.databaseBackup,
                        color: const Color(0xFF8B5CF6),
                        title: 'Ekspor & Cadangan',
                        subtitle: 'Laporan CSV, backup, dan pemulihan',
                        onTap: () => context.push(AppRoutes.dataTools),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                CustomButton(
                  label: 'Logout',
                  icon: AppIcons.logOut,
                  variant: CustomButtonVariant.danger,
                  onPressed: _confirmLogout,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.emeraldTint,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Icon(icon, size: 18, color: AppColors.emeraldDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(value, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = AppColors.emeraldDark,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.coolGray,
                    ),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.chevronRight, size: 18, color: AppColors.coolGray),
          ],
        ),
      ),
    );
  }
}
