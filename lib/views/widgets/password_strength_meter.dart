import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Indikator kekuatan password beserta daftar syarat yang terpenuhi secara langsung.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  int get _level {
    switch (AuthViewModel.evaluatePassword(password)) {
      case PasswordStrength.empty:
        return 0;
      case PasswordStrength.weak:
        return 1;
      case PasswordStrength.fair:
        return 2;
      case PasswordStrength.good:
        return 3;
      case PasswordStrength.strong:
        return 4;
    }
  }

  String get _label {
    switch (_level) {
      case 1:
        return 'Lemah';
      case 2:
        return 'Cukup';
      case 3:
        return 'Baik';
      case 4:
        return 'Kuat';
      default:
        return 'Belum diisi';
    }
  }

  Color get _color {
    switch (_level) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return const Color(0xFF34D399);
      case 4:
        return AppColors.emeraldDark;
      default:
        return AppColors.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int level = _level;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (int i = 1; i <= 4; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 5,
                  decoration: BoxDecoration(
                    color: i <= level ? _color : AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              if (i < 4) const SizedBox(width: 6),
            ],
            const SizedBox(width: 10),
            SizedBox(
              width: 70,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _label,
                  key: ValueKey<String>(_label),
                  textAlign: TextAlign.right,
                  style: textTheme.labelMedium?.copyWith(
                    color: level == 0 ? AppColors.coolGray : _color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _Rule(
          text: 'Minimal 8 karakter',
          ok: AuthViewModel.passwordHasMinLength(password),
        ),
        _Rule(text: 'Mengandung huruf', ok: AuthViewModel.passwordHasLetter(password)),
        _Rule(text: 'Mengandung angka', ok: AuthViewModel.passwordHasDigit(password)),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.text, required this.ok});

  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final Color color = ok ? AppColors.emeraldDark : AppColors.coolGray;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: ok
                ? Icon(
                    AppIcons.check,
                    key: const ValueKey<String>('ok'),
                    size: 15,
                    color: color,
                  )
                : Icon(
                    AppIcons.minus,
                    key: const ValueKey<String>('no'),
                    size: 15,
                    color: color,
                  ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
