import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/extensions/sizes.dart';
import 'package:flutter/material.dart';

class CustomBarberCard extends StatelessWidget {
  const CustomBarberCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 10.w),
      child: Container(
        width: 390.w,
        height: 315.h,
        decoration: BoxDecoration(
          color: AppColors.darkGray,
          borderRadius: BorderRadius.circular(18),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              child: Column(children: [
                
            ],),
            ),
          ),
        ),
      ),
    );
  }
}
