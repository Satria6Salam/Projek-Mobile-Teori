import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../widgets/animated_counter.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/theme_illustrations.dart';
import '../widgets/period_search_sheet.dart';
import '../widgets/period_selector.dart';
import '../widgets/transaction_card.dart';
import '../widgets/transaction_detail_sheet.dart';

/// Menu Riwayat: seluruh transaksi pada periode terpilih dengan pencarian nama toko,
/// filter kategori (dapat memilih beberapa), dan pengurutan.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _sortLabel(HistorySort sort) {
    switch (sort) {
      case HistorySort.newest:
        return 'Terbaru';
      case HistorySort.oldest:
        return 'Terlama';
      case HistorySort.highest:
        return 'Nominal terbesar';
      case HistorySort.lowest:
        return 'Nominal terkecil';
    }
  }

  void _clearFilters(DashboardViewModel dash) {
    _searchController.clear();
    dash.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final DashboardViewModel dash = context.watch<DashboardViewModel>();
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<TransactionModel> items = dash.filteredTransactions;

    // Samakan kolom pencarian bila teks diubah dari luar (mis. filter dihapus).
    if (dash.searchQuery.isEmpty && _searchController.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && dash.searchQuery.isEmpty) _searchController.clear();
      });
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
                  AppSpacing.sm,
                ),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideIn(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Riwayat Transaksi',
                                  style: textTheme.headlineMedium),
                              Text(
                                'Cari dan saring semua catatan Anda',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration:
                              AppDecorations.card(radius: AppRadius.control),
                          child: PopupMenuButton<HistorySort>(
                            tooltip: 'Urutkan',
                            icon: Icon(AppIcons.arrowUpDown, size: 22),
                            initialValue: dash.sort,
                            onSelected: dash.setSort,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                            ),
                            itemBuilder: (BuildContext context) {
                              return <PopupMenuEntry<HistorySort>>[
                                for (final HistorySort s in HistorySort.values)
                                  PopupMenuItem<HistorySort>(
                                    value: s,
                                    child: Row(
                                      children: [
                                        Expanded(child: Text(_sortLabel(s))),
                                        if (s == dash.sort)
                                          Icon(
                                            AppIcons.check,
                                            size: 18,
                                            color: AppColors.emeraldDark,
                                          ),
                                      ],
                                    ),
                                  ),
                              ];
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
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
                      child: TextField(
                        controller: _searchController,
                        onChanged: dash.setSearchQuery,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Cari nama toko...',
                          prefixIcon: Icon(
                            AppIcons.search,
                            size: 20,
                            color: AppColors.coolGray,
                          ),
                          suffixIcon: dash.searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Hapus pencarian',
                                  onPressed: () {
                                    _searchController.clear();
                                    dash.setSearchQuery('');
                                  },
                                  icon: Icon(AppIcons.close, size: 18),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ]),
                ),
              ),
              if (dash.categorySummaries.isNotEmpty)
                SliverToBoxAdapter(
                  child: FadeSlideIn(
                    delay: const Duration(milliseconds: 180),
                    child: CategoryFilterBar(
                      categories: dash.categorySummaries,
                      selectedIds: dash.categoryFilter,
                      onToggle: dash.toggleCategoryFilter,
                      onClear: dash.clearCategoryFilter,
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldTint,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Row(
                      children: [
                        Icon(AppIcons.receipt,
                            size: 18, color: AppColors.emeraldDeep),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${items.length} transaksi'
                            '${dash.hasCategoryFilter ? '  •  kategori terpilih' : ''}',
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.emeraldDeep,
                            ),
                          ),
                        ),
                        AnimatedCounter(
                          value: dash.filteredTotal,
                          formatter: AppFormatters.rupiah,
                          style: AppTextStyles.amount(
                            size: 15,
                            color: AppColors.emeraldDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (dash.transactions.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    art: ThemeArtKind.history,
                    icon: AppIcons.receipt,
                    title: 'Belum ada transaksi',
                    message:
                        'Tidak ada pengeluaran tercatat pada periode ini. Coba periode lain dengan tombol cari.',
                  ),
                )
              else if (items.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    art: ThemeArtKind.tags,
                    icon: AppIcons.search,
                    title: 'Tidak ada hasil',
                    message:
                        'Tidak ada transaksi yang cocok dengan pencarian atau filter kategori Anda.',
                    actionLabel: 'Hapus filter',
                    onAction: () => _clearFilters(dash),
                  ),
                )
              else
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final TransactionModel transaction = items[index];
                        return FadeSlideIn(
                          key: ValueKey<int?>(transaction.id),
                          delay: Duration(
                              milliseconds: 30 * (index < 10 ? index : 10)),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TransactionCard(
                              transaction: transaction,
                              amount: dash.hasCategoryFilter
                                  ? dash.filteredAmountOf(transaction)
                                  : null,
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
                      childCount: items.length,
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
