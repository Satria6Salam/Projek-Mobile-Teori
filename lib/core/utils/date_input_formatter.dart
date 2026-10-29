import 'package:flutter/services.dart';

/// Memformat ketikan angka menjadi tanggal dd/MM/yyyy secara otomatis
/// (contoh: 16112019 -> 16/11/2019). Hanya menerima digit.
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final String limited = digits.length > 8 ? digits.substring(0, 8) : digits;

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(limited[i]);
    }
    final String text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
