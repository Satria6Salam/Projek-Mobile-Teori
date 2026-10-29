import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import 'scan_animation.dart';

/// Lapisan penutup layar saat struk sedang diproses (OCR dan AI).
class ProcessingOverlay extends StatelessWidget {
  const ProcessingOverlay({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Positioned.fill(
      child: AbsorbPointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 250),
          builder: (BuildContext context, double opacity, Widget? child) {
            return Opacity(opacity: opacity, child: child);
          },
          child: Container(
            color: const Color(0xB30F172A),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              decoration: AppDecorations.card(radius: AppRadius.cardLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ScanAnimation(),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Memproses Struk', style: textTheme.titleMedium),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      message,
                      key: ValueKey<String>(message),
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.coolGray,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                      child: LinearProgressIndicator(minHeight: 4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
