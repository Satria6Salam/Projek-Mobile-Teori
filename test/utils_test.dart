import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_receipt/core/utils/dashboard_period.dart';
import 'package:smart_receipt/core/utils/date_input_formatter.dart';
import 'package:smart_receipt/core/utils/thousands_separator_formatter.dart';

TextEditingValue _type(TextInputFormatter formatter, String text) {
  return formatter.formatEditUpdate(
    TextEditingValue.empty,
    TextEditingValue(text: text),
  );
}

void main() {
  group('DashboardPeriod', () {
    test('batas awal dan akhir tiap jenis periode', () {
      final DashboardPeriod day = DashboardPeriod.day(DateTime(2019, 11, 16));
      expect(day.start, DateTime(2019, 11, 16));
      expect(day.endExclusive, DateTime(2019, 11, 17));
      expect(day.totalDays, 1);

      final DashboardPeriod month = DashboardPeriod.month(2024, 2);
      expect(month.start, DateTime(2024, 2));
      expect(month.endExclusive, DateTime(2024, 3));
      expect(month.totalDays, 29); // tahun kabisat

      final DashboardPeriod year = DashboardPeriod.year(2022);
      expect(year.start, DateTime(2022));
      expect(year.endExclusive, DateTime(2023));
      expect(year.totalDays, 365);
    });

    test('periode sebelumnya dan berikutnya melintasi batas tahun', () {
      expect(DashboardPeriod.month(2026, 1).previous, DashboardPeriod.month(2025, 12));
      expect(DashboardPeriod.month(2025, 12).next, DashboardPeriod.month(2026, 1));
      expect(
        DashboardPeriod.day(DateTime(2026, 1, 1)).previous,
        DashboardPeriod.day(DateTime(2025, 12, 31)),
      );
      expect(DashboardPeriod.year(2022).next, DashboardPeriod.year(2023));
    });

    test('periode berjalan dan batas navigasi', () {
      final DateTime now = DateTime(2026, 10, 15);
      expect(DashboardPeriod.month(2026, 10).isCurrent(now), isTrue);
      expect(DashboardPeriod.month(2026, 9).isCurrent(now), isFalse);
      expect(DashboardPeriod.month(2026, 10).canGoNext(now), isFalse);
      expect(DashboardPeriod.month(2026, 9).canGoNext(now), isTrue);
      expect(DashboardPeriod.year(2026).canGoNext(now), isFalse);
      expect(DashboardPeriod.year(2025).canGoNext(now), isTrue);
    });
  });

  group('Pemformat input', () {
    test('DateInputFormatter menyisipkan garis miring otomatis', () {
      final DateInputFormatter formatter = DateInputFormatter();
      expect(_type(formatter, '16112019').text, '16/11/2019');
      expect(_type(formatter, '1611').text, '16/11');
      expect(_type(formatter, '16').text, '16');
      expect(_type(formatter, '161120191234').text, '16/11/2019');
      expect(_type(formatter, '16/11/2019').text, '16/11/2019');
    });

    test('ThousandsSeparatorFormatter memberi pemisah ribuan', () {
      final ThousandsSeparatorFormatter formatter = ThousandsSeparatorFormatter();
      expect(_type(formatter, '17000').text, '17.000');
      expect(_type(formatter, '1234567').text, '1.234.567');
      expect(_type(formatter, '875000').text, '875.000');
      expect(_type(formatter, 'abc').text, '');
    });
  });
}
