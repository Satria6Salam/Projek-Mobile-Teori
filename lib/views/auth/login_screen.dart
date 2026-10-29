import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../widgets/animated_backdrop.dart';
import '../widgets/app_logo.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/message_banner.dart';

/// Halaman Login (UC-01). Navigasi ke Dasbor dilakukan otomatis oleh Auth Guard.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    FocusScope.of(context).unfocus();
    await context.read<AuthViewModel>().login(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final AuthViewModel auth = context.watch<AuthViewModel>();
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? error = auth.errorMessage;
    final String? info = auth.infoMessage;

    return Scaffold(
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppLogo(size: 72, animated: true),
                      const SizedBox(height: AppSpacing.md),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        child: Column(
                          children: [
                            Text('SmartReceipt',
                                style: textTheme.headlineMedium),
                            const SizedBox(height: 4),
                            Text(
                              'Catat pengeluaran dari struk belanja,\notomatis dan tanpa internet',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.coolGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 300),
                        offset: const Offset(0, 0.1),
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
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Selamat datang kembali',
                                    style: textTheme.titleLarge),
                                const SizedBox(height: 4),
                                Text(
                                  'Masuk untuk melanjutkan pencatatan keuangan Anda',
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
                                      if (info != null) ...[
                                        MessageBanner(
                                          message: info,
                                          type: BannerType.success,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                      ],
                                      if (error != null) ...[
                                        MessageBanner(message: error),
                                        const SizedBox(height: AppSpacing.md),
                                      ],
                                    ],
                                  ),
                                ),
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
                                  hint: 'Masukkan password',
                                  controller: _passwordController,
                                  prefixIcon: AppIcons.lock,
                                  isPassword: true,
                                  textInputAction: TextInputAction.done,
                                  validator:
                                      AuthViewModel.validateLoginPassword,
                                  onChanged: (_) => auth.clearMessages(),
                                  onSubmitted: (_) => _submit(),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                CustomButton(
                                  label: 'Login',
                                  icon: AppIcons.logIn,
                                  isLoading: auth.isLoading,
                                  onPressed: _submit,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 450),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Belum punya akun?',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.coolGray,
                              ),
                            ),
                            TextButton(
                              onPressed: auth.isLoading
                                  ? null
                                  : () {
                                      auth.clearMessages();
                                      context.push(AppRoutes.register);
                                    },
                              child: const Text('Daftar Akun Baru'),
                            ),
                          ],
                        ),
                      ),
                    ],
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
