import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../services/insight_service.dart';

/// Kartu "Profil Pengeluaran Anda" berdasarkan kategori dominan.
class PersonaCard extends StatelessWidget {
  const PersonaCard({super.key, required this.persona});

  final SpendingPersona persona;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? category = persona.categoryName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF134E4A), Color(0xFF065F46)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.sparkles, size: 18, color: const Color(0xFF6EE7B7)),
              const SizedBox(width: 8),
              Text(
                'Profil Pengeluaran Anda',
                style: textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF6EE7B7),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            persona.title,
            style: textTheme.headlineMedium?.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            persona.description,
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xCCFFFFFF),
              height: 1.5,
            ),
          ),
          if (category != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0x26FFFFFF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$category  •  ${persona.sharePercent.round()}% dari pengeluaran',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
