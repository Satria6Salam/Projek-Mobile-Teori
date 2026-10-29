import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_decorations.dart';
import 'app_text_styles.dart';

/// Konfigurasi tema global Material Design 3 untuk SmartReceipt.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final TextTheme textTheme = AppTextStyles.buildTextTheme();

    const ColorScheme colorScheme = ColorScheme.light(
      primary: AppColors.emerald,
      onPrimary: AppColors.white,
      secondary: AppColors.emeraldDark,
      onSecondary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.slateDark,
      error: AppColors.error,
      onError: AppColors.white,
      outline: AppColors.border,
    );

    final RoundedRectangleBorder controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
    );

    OutlineInputBorder inputBorder(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.offWhite,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      iconTheme: const IconThemeData(color: AppColors.slateDark, size: 24),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.offWhite,
        foregroundColor: AppColors.slateDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.coolGray),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.coolGray),
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.error),
        border: inputBorder(AppColors.border),
        enabledBorder: inputBorder(AppColors.border),
        focusedBorder: inputBorder(AppColors.emerald, width: 1.5),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error, width: 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(88, 52)),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(controlShape),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(fontSize: 16),
          ),
          foregroundColor: const WidgetStatePropertyAll(AppColors.white),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.border;
            }
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return AppColors.emeraldDark; // efek menggelap saat disentuh
            }
            return AppColors.emerald;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(88, 52)),
          shape: WidgetStatePropertyAll(controlShape),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(fontSize: 16),
          ),
          foregroundColor: const WidgetStatePropertyAll(AppColors.slateDark),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.border),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(controlShape),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          foregroundColor: const WidgetStatePropertyAll(AppColors.emeraldDark),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.slateDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.white,
        ),
        shape: controlShape,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.emerald,
      ),
    );
  }
}
