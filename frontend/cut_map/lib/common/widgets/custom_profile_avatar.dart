import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/extensions/sizes.dart';
import 'package:flutter/material.dart';

class CustomProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onTap;

  const CustomProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50.w,
        height: 50.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.yellow, 
            width: 2.0,
          ),
        ),
        child: ClipOval(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.darkGray,
              child: Icon(Icons.person, color: AppColors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
