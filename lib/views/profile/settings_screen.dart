import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/message_banner.dart';

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
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: AppDecorations.card(radius: AppRadius.cardLarge),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: textTheme.headlineMedium?.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        name.isEmpty ? 'Pengguna' : name,
                        style: textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.email,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.coolGray,
                        ),
                      ),
                    ],
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
