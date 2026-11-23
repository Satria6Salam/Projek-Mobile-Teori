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
import '../../data/models/category_summary_model.dart';
import '../../data/models/transaction_model.dart';
import '../../services/insight_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../widgets/animated_counter.dart';
import '../widgets/category_mini_list.dart';
import '../widgets/custom_button.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/insight_card.dart';
import '../widgets/message_banner.dart';
import '../widgets/period_search_sheet.dart';
import '../widgets/period_selector.dart';
import '../widgets/quick_actions.dart';
import '../widgets/stat_tile.dart';
import '../widgets/summary_card.dart';
import '../widgets/theme_illustrations.dart';
import '../widgets/transaction_card.dart';
import '../widgets/transaction_detail_sheet.dart';

/// Menu Beranda: ringkasan periode, angka penting, rekap singkat kategori,
/// satu wawasan utama, dan transaksi terbaru. Rincian ada di menu lain.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const int _recentCount = 5;

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
    final SpendingAnalytics analytics = dash.analytics;
    final DashboardPeriod period = dash.period;
    final String? error = dash.errorMessage;
    final String periodLabel = AppFormatters.period(period);
    final List<TransactionModel> recent =
        dash.transactions.take(_recentCount).toList();
    final bool hasData = analytics.hasData && !dash.isEmpty;
    final TransactionModel? biggest = analytics.biggestTransaction;
    final bool isDay = period.mode == PeriodMode.day;
    final bool canProject = analytics.isCurrentPeriod && !isDay;
    final Insight? topInsight =
        analytics.insights.isEmpty ? null : analytics.insights.first;

    void openCategory(CategorySummaryModel summary) {
      dash.setCategoryFilter(<int>{summary.categoryId});
      context.go(AppRoutes.history);
    }

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
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideIn(
                    child: DashboardHeader(
                      name: auth.currentUser?.name ?? '',
                      onSettingsTap: () => context.go(AppRoutes.settings),
                      onNotificationTap: () =>
                          context.push(AppRoutes.notifications),
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
                    const SizedBox(height: AppSpacing.md),
                    FadeSlideIn(
                      delay: _delay(3),
                      child: QuickActionsRow(
                        actions: [
                          QuickAction(
                            icon: AppIcons.scanLine,
                            label: 'Scan',
                            highlight: true,
                            onTap: () => context.push(AppRoutes.scan),
                          ),
                          QuickAction(
                            icon: AppIcons.penLine,
                            label: 'Catat',
                            onTap: () => context.push(AppRoutes.manualEntry),
                          ),
                          QuickAction(
                            icon: AppIcons.piggyBank,
                            label: 'Anggaran',
                            onTap: () => context.push(AppRoutes.budget),
                          ),
                          QuickAction(
                            icon: AppIcons.shoppingCart,
                            label: 'Rencana',
                            onTap: () => context.push(AppRoutes.shoppingPlan),
                          ),
                        ],
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
                      const SizedBox(height: AppSpacing.lg),
                      FadeSlideIn(
                        delay: _delay(5),
                        child: _SectionHeader(
                          title: 'Rekap Singkat',
                          actionLabel: 'Analisis',
                          onAction: () => context.go(AppRoutes.analysis),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FadeSlideIn(
                        delay: _delay(6),
                        child: CategoryMiniList(
                          summaries: dash.categorySummaries,
                          percentageOf: dash.percentageOf,
                          onSelect: openCategory,
                        ),
                      ),
                      if (topInsight != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        FadeSlideIn(
                          delay: _delay(7),
                          child: _SectionHeader(
                            title: 'Wawasan untuk Anda',
                            actionLabel: 'Lainnya',
                            onAction: () => context.go(AppRoutes.analysis),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FadeSlideIn(
                          delay: _delay(8),
                          child: InsightCard(insight: topInsight),
                        ),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    FadeSlideIn(
                      delay: _delay(9),
                      child: _SectionHeader(
                        title: 'Transaksi Terbaru',
                        actionLabel: dash.isEmpty ? null : 'Lihat semua',
                        onAction: () => context.go(AppRoutes.history),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ]),
                ),
              ),
              if (dash.isEmpty)
                SliverToBoxAdapter(
                  child: FadeSlideIn(
                    child: Column(
                      children: [
                        EmptyState(
                          art: ThemeArtKind.scan,
                          icon: AppIcons.receipt,
                          title: 'Belum ada transaksi',
                          message:
                              'Tidak ada pengeluaran tercatat pada $periodLabel. Pindai struk untuk mulai mencatat, atau gunakan tombol cari untuk melihat periode lain.',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                          ),
                          child: CustomButton(
                            label: 'Scan Struk',
                            icon: AppIcons.scanLine,
                            onPressed: () => context.push(AppRoutes.scan),
                          ),
                        ),
                      ],
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
                        final TransactionModel transaction = recent[index];
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 40 * index),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TransactionCard(
                              transaction: transaction,
                              extraCategories:
                                  dash.categoryCountOf(transaction) - 1,
                              onTap: () => showTransactionDetailSheet(
                                context,
                                transaction,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: recent.length,
                    ),
                  ),
                ),
              if (!dash.isEmpty && dash.transactionCount > _recentCount)
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: CustomButton(
                      label: 'Lihat semua ${dash.transactionCount} transaksi',
                      variant: CustomButtonVariant.secondary,
                      onPressed: () => context.go(AppRoutes.history),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(child: Text(title, style: textTheme.titleLarge)),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel ?? '')),
      ],
    );
  }
}
