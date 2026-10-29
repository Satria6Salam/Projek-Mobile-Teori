import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';

/// Input form dengan label di atas, sudut melengkung 12px, dan validasi.
/// Mendukung toggle lihat/sembunyikan untuk password.
class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.prefixIcon,
    this.prefixText,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.inputFormatters,
    this.maxLines = 1,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final IconData? prefixIcon;
  final String? prefixText;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Pesan galat dari luar (misalnya dari ViewModel), dipakai bila tanpa [validator].
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool enabled;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final InputDecoration decoration = InputDecoration(
      hintText: widget.hint,
      errorText: widget.errorText,
      prefixText: widget.prefixText,
      prefixIcon: widget.prefixIcon == null
          ? null
          : Icon(widget.prefixIcon, size: 20, color: AppColors.coolGray),
      suffixIcon: widget.isPassword
          ? IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure ? AppIcons.eye : AppIcons.eyeOff,
                size: 20,
                color: AppColors.coolGray,
              ),
            )
          : null,
    );

    final bool obscure = widget.isPassword && _obscure;
    final int lines = widget.isPassword ? 1 : widget.maxLines;
    final TextStyle? style = textTheme.bodyLarge;

    final Widget field = widget.validator == null
        ? TextField(
            controller: widget.controller,
            obscureText: obscure,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            inputFormatters: widget.inputFormatters,
            maxLines: lines,
            enabled: widget.enabled,
            style: style,
            decoration: decoration,
          )
        : TextFormField(
            controller: widget.controller,
            obscureText: obscure,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            inputFormatters: widget.inputFormatters,
            maxLines: lines,
            enabled: widget.enabled,
            style: style,
            decoration: decoration,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: textTheme.labelLarge?.copyWith(color: AppColors.coolGray),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}
