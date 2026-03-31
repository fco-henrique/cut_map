import 'package:cut_map/commom/constants/app_colors.dart';
import 'package:cut_map/commom/constants/app_fonts.dart';
import 'package:cut_map/commom/extensions/sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextFormField extends StatefulWidget {
  final EdgeInsetsGeometry? padding;
  final String? hintText;
  final String? labelText;
  final TextCapitalization? textCapitalization;
  final TextEditingController? textEditingController;
  final TextInputType? textInputType;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final IconData? prefixIcon;
  final bool? obscureText;
  final List<TextInputFormatter>? inputFormatter;
  final FormFieldValidator<String>? validator;
  final String? helperText;
  final String? counterText;

  const CustomTextFormField({
    super.key,
    this.padding,
    this.labelText,
    this.hintText,
    this.textCapitalization,
    this.textEditingController,
    this.textInputType,
    this.maxLength,
    this.textInputAction,
    this.suffixIcon,
    this.prefixIcon,
    this.obscureText,
    this.inputFormatter,
    this.validator,
    this.helperText,
    this.counterText,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  final bool _isHelperTextVisible = true;
  String? _helperText;

  @override
  void initState() {
    super.initState();
    _helperText = widget.helperText;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          widget.padding ??
          const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: TextFormField(
        validator: widget.validator,
        inputFormatters: widget.inputFormatter,
        obscureText: widget.obscureText ?? false,
        textInputAction: widget.textInputAction,
        maxLength: widget.maxLength,
        keyboardType: widget.textInputType,
        controller: widget.textEditingController,
        textCapitalization:
            widget.textCapitalization ?? TextCapitalization.none,
        cursorColor: AppColors.white,
        style: AppFonts.regular16.apply(color: Colors.white),
        decoration: InputDecoration(
          // Apenas adiciona o prefixIcon se existir
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon, color: AppColors.gray, size: 24.s)
              : null,
          suffixIcon: widget.suffixIcon,
          helperText: _helperText ?? " ",
          helperStyle: TextStyle(
            color: _isHelperTextVisible ? AppColors.gray : Colors.transparent,
          ),
          errorMaxLines: 3,
          errorStyle: AppFonts.regular12.apply(color: AppColors.red),
          helperMaxLines: 3,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          hintText: widget.hintText,
          hintStyle: AppFonts.regular16.apply(
            color: Color.fromARGB(255, 174, 171, 171),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelText: widget.labelText,
          labelStyle: AppFonts.bold16.apply(color: AppColors.gray),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.gray),
            borderRadius: BorderRadius.circular(16),
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
          counterText: widget.counterText,
          filled: true,
          fillColor: AppColors.darkGray,
        ),
      ),
    );
  }
}
