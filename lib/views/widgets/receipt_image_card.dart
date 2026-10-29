import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';

/// Gambar struk pada pratinjau; ketuk untuk memperbesar.
class ReceiptImageCard extends StatelessWidget {
  const ReceiptImageCard({super.key, required this.imagePath});

  final String imagePath;

  Widget _fallback() {
    return Container(
      color: AppColors.emeraldTint,
      alignment: Alignment.center,
      child: Icon(AppIcons.receipt, size: 40, color: AppColors.emeraldDark),
    );
  }

  void _openFullScreen(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(AppSpacing.md),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: InteractiveViewer(
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => _fallback(),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: Container(
        height: 190,
        width: double.infinity,
        decoration: AppDecorations.card(radius: AppRadius.cardLarge),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _fallback(),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x990F172A),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Ketuk untuk memperbesar',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.white,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
