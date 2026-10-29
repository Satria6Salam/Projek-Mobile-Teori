import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'pressable_scale.dart';

enum CustomButtonVariant { primary, secondary, danger }

/// Tombol aksi: utama (Emerald Green), sekunder (outline), atau destruktif (merah).
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = CustomButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final CustomButtonVariant variant;

  Color get _spinnerColor {
    switch (variant) {
      case CustomButtonVariant.primary:
        return AppColors.white;
      case CustomButtonVariant.secondary:
        return AppColors.slateDark;
      case CustomButtonVariant.danger:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Saat loading, tombol tetap tampil aktif namun mengabaikan ketukan.
    final VoidCallback? handler =
        onPressed == null ? null : (isLoading ? () {} : onPressed);

    final Widget content = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _spinnerColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final Widget button;
    switch (variant) {
      case CustomButtonVariant.primary:
        button = ElevatedButton(onPressed: handler, child: content);
      case CustomButtonVariant.secondary:
        button = OutlinedButton(onPressed: handler, child: content);
      case CustomButtonVariant.danger:
        button = OutlinedButton(
          onPressed: handler,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: Color(0x4DEF4444)),
          ),
          child: content,
        );
    }

    return PressableScale(
      enabled: handler != null,
      child: SizedBox(width: double.infinity, height: 52, child: button),
    );
  }
}
