import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/utils/date_input_formatter.dart';
import '../../core/utils/formatters.dart';

/// Kolom tanggal: dapat diketik langsung (dd/mm/yyyy) atau dipilih dari kalender.
/// Nama hari ditampilkan otomatis di bawah kolom (mis. "Sabtu, 16 November 2019").
class DateInputField extends StatefulWidget {
  const DateInputField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.minYear = 1990,
  });

  final String label;
  final DateTime? value;

  /// Dipanggil dengan tanggal valid, atau null bila isian belum lengkap/tidak valid.
  final ValueChanged<DateTime?> onChanged;
  final String? errorText;
  final int minYear;

  @override
  State<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<DateInputField> {
  late final TextEditingController _controller;
  String? _localError;

  static String _format(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year.toString().padLeft(4, '0')}';
  }

  DateTime? _parse(String text) {
    final RegExpMatch? m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(text);
    if (m == null) return null;
    final int? day = int.tryParse(m.group(1) ?? '');
    final int? month = int.tryParse(m.group(2) ?? '');
    final int? year = int.tryParse(m.group(3) ?? '');
    if (day == null || month == null || year == null) return null;
    if (year < widget.minYear || year > DateTime.now().year + 1) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final DateTime date = DateTime(year, month, day);
    return (date.month == month && date.day == day) ? date : null;
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == b;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void initState() {
    super.initState();
    final DateTime? value = widget.value;
    _controller = TextEditingController(text: value == null ? '' : _format(value));
  }

  @override
  void didUpdateWidget(DateInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final DateTime? value = widget.value;
    // Sinkronkan bila tanggal berubah dari luar (mis. dipilih lewat kalender).
    if (value != null && !_sameDay(_parse(_controller.text), value)) {
      final String text = _format(value);
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      _localError = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (text.length < 10) {
      setState(() => _localError = null);
      widget.onChanged(null);
      return;
    }
    final DateTime? date = _parse(text);
    setState(() {
      _localError = date == null ? 'Tanggal tidak valid (contoh: 16/11/2019)' : null;
    });
    widget.onChanged(date);
  }

  Future<void> _openCalendar() async {
    final DateTime now = DateTime.now();
    final DateTime first = DateTime(widget.minYear);
    DateTime initial = widget.value ?? _parse(_controller.text) ?? now;
    if (initial.isBefore(first)) initial = first;
    final DateTime last = initial.isAfter(now) ? initial : now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Pilih tanggal',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked == null || !mounted) return;
    final String text = _format(picked);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() => _localError = null);
    widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final DateTime? parsed = _parse(_controller.text);
    final String? error = widget.errorText ?? _localError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: textTheme.labelLarge?.copyWith(color: AppColors.coolGray),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: [DateInputFormatter()],
          onChanged: _onTextChanged,
          style: textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'dd/mm/yyyy',
            errorText: error,
            prefixIcon: Icon(AppIcons.calendar, size: 20, color: AppColors.coolGray),
            suffixIcon: IconButton(
              tooltip: 'Pilih dari kalender',
              onPressed: _openCalendar,
              icon: Icon(AppIcons.calendarDays, size: 20, color: AppColors.emeraldDark),
            ),
          ),
        ),
        if (parsed != null && error == null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(AppIcons.check, size: 14, color: AppColors.emeraldDark),
              const SizedBox(width: 6),
              Text(
                AppFormatters.fullDate(parsed),
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.emeraldDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ] else if (error == null) ...[
          const SizedBox(height: 6),
          Text('Ketik atau pilih dari kalender', style: textTheme.bodySmall),
        ],
      ],
    );
  }
}
