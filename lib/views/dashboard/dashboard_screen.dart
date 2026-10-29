import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/dashboard_period.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../../services/insight_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../widgets/animated_counter.dart';
import '../widgets/category_breakdown_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/insight_card.dart';
import '../widgets/message_banner.dart';
import '../widgets/period_search_sheet.dart';
import '../widgets/period_selector.dart';
import '../widgets/persona_card.dart';
import '../widgets/spending_trend_chart.dart';
import '../widgets/stat_tile.dart';
import '../widgets/summary_card.dart';
import '../widgets/top_merchants_card.dart';
import '../widgets/transaction_card.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../widgets/trend_cards.dart';

/// Dasbor Keuangan: ringkasan per hari/bulan/tahun, rekap per kategori, tren harian,
/// bulanan, dan tahunan, analisis perilaku, toko favorit, dan riwayat transaksi.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Duration _delay(int step) => Duration(milliseconds: 70 * step);

  String _compareLabel(PeriodMode mode) {
    switch (mode) {
      case PeriodMode.day:
        return 'hari sebelumnya';
      case PeriodMode.month:
        return 'bulan lalu';
      case PeriodMode.year:
        return 'tahun lalu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final DashboardViewModel dash = context.watch<DashboardViewModel>();
    final AuthViewModel auth = context.watch<AuthViewModel>();
    final TextTheme textTheme = Theme.of(context).textTheme;
    final SpendingAnalytics analytics = dash.analytics;
    final DashboardPeriod period = dash.period;
    final String? error = dash.errorMessage;
    final String periodLabel = AppFormatters.period(period);
    final List<TransactionModel> transactions = dash.transactions;
    final bool hasData = analytics.hasData && !dash.isEmpty;
    final TransactionModel? biggest = analytics.biggestTransaction;
    final SpendingPersona? persona = analytics.persona;
    final bool isDay = period.mode == PeriodMode.day;
    final bool canProject = analytics.isCurrentPeriod && !isDay;

    return Scaffold(
      floatingActionButton: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.elasticOut,
        builder: (BuildContext context, double scale, Widget? child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.scan),
          backgroundColor: AppColors.emerald,
          foregroundColor: AppColors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          icon: Icon(AppIcons.scanLine),
          label: Text(
            'Scan Struk',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.white,
              fontSize: 15,
            ),
          ),
        ),
      ),
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
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideIn(
                    child: DashboardHeader(
                      name: auth.currentUser?.name ?? '',
                      onSettingsTap: () => context.push(AppRoutes.settings),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: SizedBox(
                    height: 3,
                    child: dash.isLoading
                        ? const LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor: Colors.transparent,
                          )
                        : null,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: AppSpacing.sm),
                    FadeSlideIn(
                      delay: _delay(1),
                      child: PeriodSelector(
                        period: period,
                        canGoNext: dash.canGoNext,
                        onPrevious: dash.goToPrevious,
                        onNext: dash.goToNext,
                        onSearch: () => showPeriodSearchSheet(context),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FadeSlideIn(
                      delay: _delay(2),
                      child: SummaryCard(
                        periodLabel: periodLabel,
                        totalAmount: dash.total,
                        transactionCount: dash.transactionCount,
                        averagePerDay: analytics.averagePerDay,
                        projectedTotal: analytics.projectedTotal,
                        isCurrentPeriod: canProject,
                        compareLabel: _compareLabel(period.mode),
                        changePercent: analytics.changePercent,
                        topCategoryName: dash.topCategory?.categoryName,
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      MessageBanner(
                        message: error,
                        actionLabel: 'Coba lagi',
                        onAction: dash.refresh,
                      ),
                    ],
                    if (hasData) ...[
                      const SizedBox(height: AppSpacing.md),
                      FadeSlideIn(
                        delay: _delay(3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: StatTile(
                                icon: AppIcons.banknote,
                                label: 'Rata-rata per transaksi',
                                value: AnimatedCounter(
                                  value: analytics.averagePerTransaction,
                                  formatter: AppFormatters.rupiah,
                                  style: AppTextStyles.amount(size: 17),
                                ),
                                footnote:
                                    '${analytics.transactionCount} transaksi',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatTile(
                                icon: AppIcons.crown,
                                label: 'Transaksi terbesar',
                                value: AnimatedCounter(
                                  value: biggest?.totalAmount ?? 0,
                                  formatter: AppFormatters.rupiah,
                                  style: AppTextStyles.amount(size: 17),
                                ),
                                footnote: biggest?.merchantName,
                                color: AppColors.warningDeep,
                                tint: AppColors.warningTint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeSlideIn(
                        delay: _delay(4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: StatTile(
                                icon: AppIcons.calendarDays,
                                label: 'Hari ada pengeluaran',
                                value: AnimatedCounter(
                                  value: analytics.activeDays.toDouble(),
                                  formatter: (double v) => '${v.round()} hari',
                                  style: AppTextStyles.amount(size: 17),
                                ),
                                footnote: 'dari ${analytics.daysElapsed} hari',
                                color: const Color(0xFF3B82F6),
                                tint: const Color(0x1F3B82F6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatTile(
                                icon: canProject
                                    ? AppIcons.trendingUp
                                    : AppIcons.wallet,
                                label: canProject
                                    ? (period.mode == PeriodMode.year
                                        ? 'Proyeksi akhir tahun'
                                        : 'Proyeksi akhir bulan')
                                    : 'Periode sebelumnya',
                                value: AnimatedCounter(
                                  value: canProject
                                      ? analytics.projectedTotal
                                      : analytics.previousMonthTotal,
                                  formatter: AppFormatters.rupiah,
                                  style: AppTextStyles.amount(size: 17),
                                ),
                                footnote: canProject
                                    ? 'jika pola berlanjut'
                                    : 'total ${_compareLabel(period.mode)}',
                                color: const Color(0xFF8B5CF6),
                                tint: const Color(0x1F8B5CF6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (analytics.dailyTotals.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        FadeSlideIn(
                          delay: _delay(5),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: AppDecorations.card(
                              radius: AppRadius.cardLarge,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tren Harian',
                                    style: textTheme.titleLarge),
                                const SizedBox(height: 2),
                                Text(
                                  'Pengeluaran per tanggal, $periodLabel',
                                  style: textTheme.bodySmall,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                SpendingTrendChart(data: analytics.dailyTotals),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (dash.categorySummaries.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        FadeSlideIn(
                          delay: _delay(6),
                          child: CategoryBreakdownCard(
                            summaries: dash.categorySummaries,
                            percentageOf: dash.percentageOf,
                            total: dash.categoriesTotal,
                          ),
                        ),
                      ],
                      if (persona != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        FadeSlideIn(
                          delay: _delay(7),
                          child: PersonaCard(persona: persona),
                        ),
                      ],
                      if (analytics.insights.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        FadeSlideIn(
                          delay: _delay(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Analisis Perilaku',
                                style: textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Dihitung dari kebiasaan pengeluaran Anda',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (int i = 0; i < analytics.insights.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          FadeSlideIn(
                            delay: _delay(9 + i),
                            child: InsightCard(insight: analytics.insights[i]),
                          ),
                        ],
                      ],
                      if (analytics.topMerchants.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        FadeSlideIn(
                          delay: _delay(10),
                          child: TopMerchantsCard(
                            merchants: analytics.topMerchants,
                          ),
                        ),
                      ],
                    ],
                    if (dash.trends.hasData) ...[
                      const SizedBox(height: AppSpacing.lg),
                      FadeSlideIn(
                        delay: _delay(11),
                        child: MonthlyTrendCard(
                          trends: dash.trends,
                          period: period,
                          onOpenMonth: (int month) =>
                              dash.showMonth(dash.trends.year, month),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FadeSlideIn(
                        delay: _delay(12),
                        child: YearlyTrendCard(
                          trends: dash.trends,
                          period: period,
                          onOpenYear: dash.showYear,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Riwayat Transaksi',
                            style: textTheme.titleLarge,
                          ),
                        ),
                        Text(
                          '${dash.transactionCount} transaksi',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ]),
                ),
              ),
              if (dash.isEmpty)
                SliverToBoxAdapter(
                  child: FadeSlideIn(
                    child: EmptyState(
                      icon: AppIcons.receipt,
                      title: 'Belum ada transaksi',
                      message:
                          'Tidak ada pengeluaran tercatat pada $periodLabel. Gunakan tombol cari untuk melihat periode lain, atau tekan Scan Struk untuk mencatat.',
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final TransactionModel transaction =
                            transactions[index];
                        return FadeSlideIn(
                          delay: Duration(
                            milliseconds: 40 * (index < 8 ? index : 8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TransactionCard(
                              transaction: transaction,
                              onTap: () => showTransactionDetailSheet(
                                context,
                                transaction,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: transactions.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}
