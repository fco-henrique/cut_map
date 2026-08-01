import 'package:cut_map/common/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cut_map/common/extensions/sizes.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.background, 
        border: Border(
          top: BorderSide(
            color: AppColors.gray.withValues(
              alpha: 0.1,
            ),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        height: 80.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons
                  .home_filled, 
              label: 'Início',
            ),
            _buildNavItem(index: 1, icon: Icons.search, label: 'Explorar'),
            _buildNavItem(
              index: 2,
              icon: Icons.content_cut, 
              label: 'Barbearias',
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.person_outline,
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    final activeColor = AppColors.yellow; 
    final inactiveColor = AppColors.gray; 

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque, 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 3.h,
            width: 32.w,
            decoration: BoxDecoration(
              color: isSelected ? activeColor : Colors.transparent,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
          ),
          SizedBox(height: 8.h),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(
                      alpha: 0.15,
                    ) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
          ),
          SizedBox(height: 4.h),

          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
