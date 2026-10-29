import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';

/// Kolom yang tampil seperti input namun dibuka lewat ketukan (misalnya pemilih tanggal).
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.value,
    this.errorText,
  });

  final String label;
  final String hint;
  final IconData icon;
  final String? value;
  final String? errorText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(color: AppColors.coolGray),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: onTap,
          child: InputDecorator(
            isEmpty: value == null,
            decoration: InputDecoration(
              hintText: hint,
              errorText: errorText,
              prefixIcon: Icon(icon, size: 20, color: AppColors.coolGray),
            ),
            child: Text(value ?? '', style: textTheme.bodyLarge),
          ),
        ),
      ],
    );
  }
}
