import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../core/utils/dashboard_period.dart';
import '../../core/utils/formatters.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import 'custom_button.dart';
import 'custom_textfield.dart';
import 'date_input_field.dart';
import 'message_banner.dart';

/// Lembar pencarian periode: pengguna dapat memasukkan tanggal, bulan, atau tahun
/// yang ingin dilihat (misalnya langsung tahun 2022).
Future<void> showPeriodSearchSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) => const _PeriodSearchSheet(),
  );
}

class _PeriodSearchSheet extends StatefulWidget {
  const _PeriodSearchSheet();

  @override
  State<_PeriodSearchSheet> createState() => _PeriodSearchSheetState();
}

class _PeriodSearchSheetState extends State<_PeriodSearchSheet> {
  static const int _minYear = 1990;

  late PeriodMode _mode;
  late int _month;
  DateTime? _day;
  late final TextEditingController _yearController;
  String? _error;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    final DashboardPeriod period = context.read<DashboardViewModel>().period;
    _mode = period.mode;
    _month = period.anchor.month;
    _day = period.mode == PeriodMode.day ? period.anchor : null;
    _yearController = TextEditingController(text: '${period.anchor.year}');
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  int? _parseYear() {
    final int? year = int.tryParse(_yearController.text.trim());
    final int maxYear = DateTime.now().year;
    if (year == null || year < _minYear || year > maxYear) return null;
    return year;
  }

  Future<void> _apply() async {
    final DashboardViewModel dash = context.read<DashboardViewModel>();
    final NavigatorState navigator = Navigator.of(context);
    FocusScope.of(context).unfocus();

    bool? ok;
    String? error;
    setState(() {
      _isApplying = true;
      _error = null;
    });

    switch (_mode) {
      case PeriodMode.day:
        final DateTime? day = _day;
        if (day == null) {
          error = 'Masukkan tanggal yang valid, contoh 16/11/2019';
        } else {
          ok = await dash.showDay(day);
          if (!ok) error = 'Tanggal tersebut belum terjadi';
        }
      case PeriodMode.month:
        final int? monthYear = _parseYear();
        if (monthYear == null) {
          error = 'Tahun harus antara $_minYear dan ${DateTime.now().year}';
        } else {
          ok = await dash.showMonth(monthYear, _month);
          if (!ok) error = 'Bulan tersebut belum terjadi';
        }
      case PeriodMode.year:
        final int? onlyYear = _parseYear();
        if (onlyYear == null) {
          error = 'Tahun harus antara $_minYear dan ${DateTime.now().year}';
        } else {
          ok = await dash.showYear(onlyYear);
          if (!ok) error = 'Tahun tersebut belum terjadi';
        }
    }

    if (!mounted) return;
    if (error == null) {
      navigator.pop();
    } else {
      setState(() {
        _isApplying = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final DashboardViewModel dash = context.watch<DashboardViewModel>();
    final List<int> years = dash.availableYears;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.cardLarge),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cari Periode', style: textTheme.titleLarge),
                          Text(
                            'Lihat pengeluaran berdasarkan tanggal, bulan, atau tahun',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(AppIcons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _ModeChip(
                      label: 'Tanggal',
                      selected: _mode == PeriodMode.day,
                      onTap: () => setState(() {
                        _mode = PeriodMode.day;
                        _error = null;
                      }),
                    ),
                    const SizedBox(width: 8),
                    _ModeChip(
                      label: 'Bulan',
                      selected: _mode == PeriodMode.month,
                      onTap: () => setState(() {
                        _mode = PeriodMode.month;
                        _error = null;
                      }),
                    ),
                    const SizedBox(width: 8),
                    _ModeChip(
                      label: 'Tahun',
                      selected: _mode == PeriodMode.year,
                      onTap: () => setState(() {
                        _mode = PeriodMode.year;
                        _error = null;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (_error != null) ...[
                  MessageBanner(message: _error ?? ''),
                  const SizedBox(height: AppSpacing.md),
                ],
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: _buildInputs(textTheme, years),
                ),
                const SizedBox(height: AppSpacing.lg),
                CustomButton(
                  label: 'Tampilkan',
                  icon: AppIcons.search,
                  isLoading: _isApplying,
                  onPressed: _apply,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputs(TextTheme textTheme, List<int> years) {
    switch (_mode) {
      case PeriodMode.day:
        return DateInputField(
          label: 'Tanggal',
          value: _day,
          onChanged: (DateTime? d) => setState(() {
            _day = d;
            _error = null;
          }),
        );
      case PeriodMode.month:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bulan',
              style: textTheme.labelLarge?.copyWith(color: AppColors.coolGray),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int m = 1; m <= 12; m++)
                  _SmallChip(
                    label: AppFormatters.monthShort(m),
                    selected: _month == m,
                    onTap: () => setState(() {
                      _month = m;
                      _error = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _yearField(),
            _yearSuggestions(textTheme, years),
          ],
        );
      case PeriodMode.year:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _yearField(),
            _yearSuggestions(textTheme, years),
          ],
        );
    }
  }

  Widget _yearField() {
    return CustomTextField(
      label: 'Tahun',
      hint: 'Contoh: 2022',
      controller: _yearController,
      prefixIcon: AppIcons.calendarDays,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      onChanged: (_) => setState(() => _error = null),
      onSubmitted: (_) => _apply(),
    );
  }

  Widget _yearSuggestions(TextTheme textTheme, List<int> years) {
    if (years.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tahun yang memiliki data', style: textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final int y in years)
                _SmallChip(
                  label: '$y',
                  selected: _yearController.text.trim() == '$y',
                  onTap: () => setState(() {
                    _yearController.text = '$y';
                    _error = null;
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.emerald : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(
              color: selected ? AppColors.emerald : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? AppColors.white : AppColors.slateDark,
                ),
          ),
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.emeraldTint : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.emerald : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? AppColors.emeraldDeep : AppColors.coolGray,
              ),
        ),
      ),
    );
  }
}

