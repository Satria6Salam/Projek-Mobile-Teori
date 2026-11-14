import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category_summary_model.dart';
import '../../services/insight_service.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../widgets/category_breakdown_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/theme_illustrations.dart';
import '../widgets/insight_card.dart';
import '../widgets/period_search_sheet.dart';
import '../widgets/period_selector.dart';
import '../widgets/persona_card.dart';
import '../widgets/segmented_tabs.dart';
import '../widgets/spending_trend_chart.dart';
import '../widgets/top_merchants_card.dart';
import '../widgets/trend_cards.dart';

/// Menu Analisis, terbagi tiga tab: Rekap (kategori dan toko), Tren (harian, bulanan,
/// tahunan), dan Wawasan (profil serta analisis perilaku pengeluaran).
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int _tab = 0;

  static const List<String> _labels = <String>['Rekap', 'Tren', 'Wawasan'];

  @override
  Widget build(BuildContext context) {
    final DashboardViewModel dash = context.watch<DashboardViewModel>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.emerald,
          onRefresh: dash.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const GradientHeader(
                      title: 'Analisis',
                      subtitle: 'Pahami ke mana uang Anda pergi',
                      kind: ThemeArtKind.chart,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 60),
                      child: PeriodSelector(
                        period: dash.period,
                        canGoNext: dash.canGoNext,
                        onPrevious: dash.goToPrevious,
                        onNext: dash.goToNext,
                        onSearch: () => showPeriodSearchSheet(context),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: SegmentedTabs(
                        labels: _labels,
                        selectedIndex: _tab,
                        onChanged: (int i) => setState(() => _tab = i),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.03),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<int>(_tab),
                        child: _buildTab(context, dash),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, DashboardViewModel dash) {
    final String periodLabel = AppFormatters.period(dash.period);
    final SpendingAnalytics analytics = dash.analytics;
    final bool hasData = analytics.hasData && !dash.isEmpty;

    Widget empty(String message) {
      return EmptyState(
        art: ThemeArtKind.chart,
        icon: AppIcons.trendingUp,
        title: 'Belum ada data',
        message: message,
      );
    }

    switch (_tab) {
      case 0:
        if (!hasData) {
          return empty(
              'Tidak ada pengeluaran pada $periodLabel. Pilih periode lain atau catat transaksi baru.');
        }
        return Column(
          children: [
            CategoryBreakdownCard(
              summaries: dash.categorySummaries,
              percentageOf: dash.percentageOf,
              total: dash.categoriesTotal,
              onSelect: (CategorySummaryModel s) {
                dash.setCategoryFilter(<int>{s.categoryId});
                context.go(AppRoutes.history);
              },
            ),
            if (analytics.topMerchants.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              TopMerchantsCard(merchants: analytics.topMerchants),
            ],
          ],
        );
      case 1:
        if (!dash.trends.hasData) {
          return empty(
              'Catat transaksi pada beberapa bulan agar tren dapat ditampilkan.');
        }
        return Column(
          children: [
            if (analytics.dailyTotals.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: AppDecorations.card(radius: AppRadius.cardLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tren Harian',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      'Pengeluaran per tanggal, $periodLabel',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SpendingTrendChart(data: analytics.dailyTotals),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            MonthlyTrendCard(
              trends: dash.trends,
              period: dash.period,
              onOpenMonth: (int month) =>
                  dash.showMonth(dash.trends.year, month),
            ),
            const SizedBox(height: AppSpacing.md),
            YearlyTrendCard(
              trends: dash.trends,
              period: dash.period,
              onOpenYear: dash.showYear,
            ),
          ],
        );
      default:
        if (!hasData) {
          return empty(
              'Analisis perilaku muncul setelah ada transaksi pada $periodLabel.');
        }
        final SpendingPersona? persona = analytics.persona;
        return Column(
          children: [
            if (persona != null) ...[
              PersonaCard(persona: persona),
              const SizedBox(height: AppSpacing.md),
            ],
            for (int i = 0; i < analytics.insights.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              FadeSlideIn(
                delay: Duration(milliseconds: 60 * i),
                child: InsightCard(insight: analytics.insights[i]),
              ),
            ],
          ],
        );
    }
  }
}
