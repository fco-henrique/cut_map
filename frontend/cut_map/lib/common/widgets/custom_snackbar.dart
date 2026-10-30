import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/extensions/sizes.dart';
import 'package:flutter/material.dart';

enum SnackbarType { success, error, warning, unavailable, notification }

class CustomSnackbar {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    SnackbarType type = SnackbarType.success,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.all(16),
        content: _SnackbarContent(title: title, message: message, type: type),
      ),
    );
  }
}

class _SnackbarContent extends StatelessWidget {
  final String title;
  final String message;
  final SnackbarType type;

  const _SnackbarContent({
    required this.title,
    required this.message,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final Color mainColor = _getMainColor();
    final Color backgroundColor = AppColors.darkGray;
    final Color iconBackgroundColor = mainColor.withValues(alpha: 0.2);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: mainColor, width: 4.w),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(_getIcon(), color: mainColor, size: 24.s),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              child: Icon(
                Icons.close,
                color: AppColors.white.withValues(alpha: 0.5),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMainColor() {
    switch (type) {
      case SnackbarType.success:
        return AppColors.greenSnack;
      case SnackbarType.error:
        return AppColors.redSnack;
      case SnackbarType.warning:
        return AppColors.yellowSnack;
      case SnackbarType.unavailable:
        return AppColors.orangeSnack;
      case SnackbarType.notification:
        return AppColors.blueSnack;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle_rounded;
      case SnackbarType.error:
        return Icons.error_rounded;
      case SnackbarType.warning:
        return Icons.warning_rounded;
      case SnackbarType.unavailable:
        return Icons.close_rounded;
      case SnackbarType.notification:
        return Icons.notifications_active_rounded;
    }
  }
}
