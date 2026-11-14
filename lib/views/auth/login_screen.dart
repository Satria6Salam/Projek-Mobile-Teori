import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../widgets/app_logo.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/hero_scene.dart';
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
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Ilustrasi besar beranimasi dengan sudut bawah membulat.
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(36),
                    ),
                    child: HeroScene(
                      height: 300 + MediaQuery.paddingOf(context).top,
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.lg,
                    top: MediaQuery.paddingOf(context).top + AppSpacing.md,
                    child: FadeSlideIn(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: AppDecorations.softShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppLogo(size: 30, animated: true),
                            const SizedBox(width: 8),
                            Text(
                              'SmartReceipt',
                              style: textTheme.titleSmall?.copyWith(
                                color: AppColors.forest,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 150),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kendalikan\nKeuanganmu',
                                style: textTheme.headlineLarge?.copyWith(
                                  color: AppColors.forest,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pindai struk, catat otomatis, dan pahami pola belanjamu. Semuanya berjalan tanpa internet.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.coolGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
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
                                  color: Color(0x1416855A),
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
                                  Text('Masuk ke akun',
                                      style: textTheme.titleLarge),
                                  const SizedBox(height: AppSpacing.md),
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
                                    label: 'Mulai Sekarang',
                                    icon: AppIcons.logIn,
                                    isLoading: auth.isLoading,
                                    onPressed: _submit,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
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
                                child: const Text('Daftar'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
