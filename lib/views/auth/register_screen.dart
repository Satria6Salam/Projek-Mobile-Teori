import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../widgets/animated_backdrop.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/message_banner.dart';
import '../widgets/password_strength_meter.dart';

/// Halaman Registrasi (UC-01, skenario alternatif "Belum Punya Akun").
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthViewModel>().clearMessages();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    FocusScope.of(context).unfocus();

    final bool ok = await context.read<AuthViewModel>().register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!mounted || !ok) return;

    // Kembali ke Login; pesan "Registrasi berhasil" ditampilkan di sana.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthViewModel auth = context.watch<AuthViewModel>();
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? error = auth.errorMessage;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Daftar Akun Baru'),
        backgroundColor: Colors.transparent,
      ),
      body: AnimatedBackdrop(
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: FadeSlideIn(
                    offset: const Offset(0, 0.08),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius:
                            BorderRadius.circular(AppRadius.cardLarge),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1410B981),
                            blurRadius: 30,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Buat akun Anda', style: textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text(
                              'Isi data diri untuk mulai mencatat pengeluaran',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.coolGray,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                              child: Column(
                                children: [
                                  if (error != null) ...[
                                    MessageBanner(message: error),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                ],
                              ),
                            ),
                            CustomTextField(
                              label: 'Nama Lengkap',
                              hint: 'Nama Anda',
                              controller: _nameController,
                              prefixIcon: AppIcons.user,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              validator: AuthViewModel.validateName,
                              onChanged: (_) => auth.clearMessages(),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            CustomTextField(
                              label: 'Email',
                              hint: 'nama@email.com',
                              controller: _emailController,
                              prefixIcon: AppIcons.mail,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: AuthViewModel.validateEmail,
                              onChanged: (_) => auth.clearMessages(),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            CustomTextField(
                              label: 'Password',
                              hint: 'Minimal 8 karakter',
                              controller: _passwordController,
                              prefixIcon: AppIcons.lock,
                              isPassword: true,
                              textInputAction: TextInputAction.next,
                              validator: AuthViewModel.validatePassword,
                              onChanged: (_) => auth.clearMessages(),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _passwordController,
                              builder: (
                                BuildContext context,
                                TextEditingValue value,
                                Widget? child,
                              ) {
                                return PasswordStrengthMeter(
                                  password: value.text,
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            CustomTextField(
                              label: 'Konfirmasi Password',
                              hint: 'Ulangi password',
                              controller: _confirmController,
                              prefixIcon: AppIcons.lock,
                              isPassword: true,
                              textInputAction: TextInputAction.done,
                              validator: (String? value) =>
                                  AuthViewModel.validateConfirmPassword(
                                _passwordController.text,
                                value,
                              ),
                              onChanged: (_) => auth.clearMessages(),
                              onSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            CustomButton(
                              label: 'Simpan',
                              icon: AppIcons.userPlus,
                              isLoading: auth.isLoading,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
