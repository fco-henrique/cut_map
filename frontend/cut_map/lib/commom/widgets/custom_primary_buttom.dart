import 'package:cut_map/commom/constants/app_colors.dart';
import 'package:cut_map/commom/constants/app_fonts.dart';
import 'package:cut_map/commom/extensions/sizes.dart';
import 'package:flutter/material.dart';

class CustomPrimaryButtom extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color? color;
  final IconData? icon;
  final bool isLoading; 

  const CustomPrimaryButtom({
    super.key,
    this.onPressed,
    required this.text,
    this.color,
    this.icon,
    this.isLoading = false, 
  });

  final BorderRadius _borderRadius = const BorderRadius.all(
    Radius.circular(18),
  );

  @override
  Widget build(BuildContext context) {
    return Ink(
      height: 60.h,
      width: 382.w,
      decoration: BoxDecoration(borderRadius: _borderRadius, color: color),
      child: InkWell(
        borderRadius: _borderRadius,
        splashColor: Colors.white.withValues(alpha: 0.3),
        highlightColor: Colors.blue.withValues(alpha: 0.5),
        onTap: isLoading ? null : onPressed, 
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.black, 
                  strokeWidth: 2.5,
                ),
              )
            else ...[ 
              Text(text, style: AppFonts.bold16.apply(color: Colors.black)),
              
              if (icon != null)
                Positioned(
                  right: 8,
                  child: Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.gray, size: 30.s),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}