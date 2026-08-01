import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/constants/app_fonts.dart';
import 'package:cut_map/common/extensions/sizes.dart';
import 'package:flutter/material.dart';

class CustomNotificationButton extends StatelessWidget {
  final int notificationCount;
  final VoidCallback onTap;

  const CustomNotificationButton({
    super.key,
    this.notificationCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors
              .darkGray,
          shape: CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 50.w, 
              height: 50.h,
              child: const Icon(
                Icons.notifications_none,
                color: AppColors.white,
                size: 22,
              ),
            ),
          ),
        ),

        if (notificationCount > 0)
          Positioned(
            top: -2,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.yellow,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              alignment: Alignment.center,
              child: Text(
                notificationCount > 99 ? '99+' : notificationCount.toString(),
                style: AppFonts.bold12.apply(
                  color: AppColors.background,
                ), 
              ),
            ),
          ),
      ],
    );
  }
}
