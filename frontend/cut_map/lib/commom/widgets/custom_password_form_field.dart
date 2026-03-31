// import 'package:cut_map/commom/constants/app_colors.dart';
import 'package:cut_map/commom/constants/app_colors.dart';
import 'package:cut_map/commom/extensions/sizes.dart';
import 'package:cut_map/commom/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class CustomPasswordFormField extends StatefulWidget {
  final TextEditingController? textEditingController;
  final EdgeInsetsGeometry? padding;
  final String? hintText;
  final String? labelText;
  final FormFieldValidator<String>? validator;
  final String? helperText;
  final String? counterText;
  final bool? canTogglePassword;
  final IconData? prefixIcon;
  final int? maxLength;

  const CustomPasswordFormField({
    super.key,
    this.textEditingController,
    this.padding,
    this.hintText,
    this.labelText,
    this.validator,
    this.helperText,
    this.prefixIcon,
    this.maxLength,
    this.counterText,
    this.canTogglePassword = true,
  });

  @override
  State<CustomPasswordFormField> createState() =>
      _CustomPasswordFormFieldState();
}

class _CustomPasswordFormFieldState extends State<CustomPasswordFormField> {
  bool isHidden = true;

  @override
  Widget build(BuildContext context) {
    String? finalHelperText;

    if (widget.helperText != null && widget.counterText != null) {
      finalHelperText = '\u200B' * 250 + widget.counterText!;
    } else {
      finalHelperText = widget.helperText;
    }

    Widget? _buildSuffixIcon() {
      if (!(widget.canTogglePassword ?? true)) return null;

      return InkWell(
        borderRadius: BorderRadius.circular(23),
        onTap: () => setState(() => isHidden = !isHidden),
        child: Icon(
          isHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 24.s,
          color: AppColors.gray,
        ),
      );
    }

    return CustomTextFormField(
      maxLength: widget.maxLength,
      helperText: finalHelperText,
      counterText: (widget.counterText != null && widget.helperText == null)
          ? null
          : widget.counterText,
      validator: widget.validator,
      obscureText: isHidden,
      textEditingController: widget.textEditingController,
      padding: widget.padding,
      hintText: widget.hintText,
      labelText: widget.labelText,
      prefixIcon: widget.prefixIcon,
      suffixIcon: _buildSuffixIcon(),
    );
  }
}
