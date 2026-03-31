import 'package:cut_map/commom/constants/app_colors.dart';
import 'package:cut_map/commom/constants/app_fonts.dart';
import 'package:flutter/material.dart';

class CustomCodigFormField extends StatefulWidget {
  final String? hintText;
  final String? labelText;
  final String? helperText;
  final TextEditingController? controller;
  final int? maxLength;

  const CustomCodigFormField({
    super.key,
    this.hintText,
    this.labelText,
    this.helperText,
    this.controller,
    this.maxLength,
  });

  @override
  State<CustomCodigFormField> createState() => _CustomCodigFormFieldState();
}

class _CustomCodigFormFieldState extends State<CustomCodigFormField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller ?? TextEditingController(),
      textAlign: TextAlign.center,
      style: AppFonts.bold24.apply(color: AppColors.white),
      cursorColor: AppColors.white,
      maxLength: widget.maxLength ?? 6,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.darkGray,
        hintText: "000000",
        hintStyle: AppFonts.bold24.apply(color: const Color(0x83F5C518)),
        helperText: widget.helperText ?? " ",
        helperStyle: TextStyle(
          color: widget.helperText != null
              ? AppColors.gray
              : Colors.transparent,
        ),
        helperMaxLines: 3,
        errorStyle: AppFonts.regular12.apply(color: AppColors.red),
        errorMaxLines: 3,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.darkGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.gray, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ).copyWith(borderSide: BorderSide(color: AppColors.red)),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ).copyWith(borderSide: BorderSide(color: AppColors.red)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.gray, width: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
