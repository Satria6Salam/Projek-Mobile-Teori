import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../services/insight_service.dart';

/// Kartu satu temuan analisis perilaku pengeluaran.
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.insight});

  final Insight insight;

  Color get _color {
    switch (insight.kind) {
      case InsightKind.warning:
        return AppColors.warning;
      case InsightKind.positive:
        return AppColors.emerald;
      case InsightKind.info:
        return const Color(0xFF3B82F6);
      case InsightKind.tip:
        return const Color(0xFF8B5CF6);
    }
  }

  Color get _tint {
    switch (insight.kind) {
      case InsightKind.warning:
        return AppColors.warningTint;
      case InsightKind.positive:
        return AppColors.emeraldTint;
      case InsightKind.info:
        return const Color(0x1F3B82F6);
      case InsightKind.tip:
        return const Color(0x1F8B5CF6);
    }
  }

  String get _label {
    switch (insight.kind) {
      case InsightKind.warning:
        return 'Perhatian';
      case InsightKind.positive:
        return 'Kabar baik';
      case InsightKind.info:
        return 'Info';
      case InsightKind.tip:
        return 'Saran';
    }
  }

  IconData get _icon {
    switch (insight.topic) {
      case InsightTopic.trend:
        return insight.kind == InsightKind.positive
            ? AppIcons.trendingDown
            : AppIcons.trendingUp;
      case InsightTopic.projection:
        return AppIcons.calendarDays;
      case InsightTopic.category:
        return AppIcons.tag;
      case InsightTopic.shift:
        return AppIcons.repeat;
      case InsightTopic.weekend:
      case InsightTopic.weekday:
        return AppIcons.calendar;
      case InsightTopic.merchant:
        return AppIcons.store;
      case InsightTopic.biggest:
        return AppIcons.crown;
      case InsightTopic.smallSpend:
        return AppIcons.coins;
      case InsightTopic.tip:
        return AppIcons.lightbulb;
      case InsightTopic.data:
        return AppIcons.info;
      case InsightTopic.monthlyTrend:
        return AppIcons.calendarDays;
      case InsightTopic.yearlyTrend:
        return AppIcons.trendingUp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _tint,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Icon(_icon, size: 22, color: _color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _tint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _label,
                        style: textTheme.labelMedium?.copyWith(
                          color: _color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(insight.title, style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.coolGray,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
