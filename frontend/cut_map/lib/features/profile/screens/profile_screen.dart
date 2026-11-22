import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/constants/app_fonts.dart';
import 'package:cut_map/common/extensions/sizes.dart';
import 'package:cut_map/common/routes/named_routes.dart';
import 'package:cut_map/features/auth/services/auth_manager.dart';
import 'package:cut_map/locator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  final AuthManager? authManager;

  const ProfileScreen({super.key, this.authManager});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;

  AuthManager get _authManager =>
      widget.authManager ?? locator.get<AuthManager>();

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await _authManager.logout();
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Sizes().width == 0 || Sizes().height == 0) {
      Sizes.init(context);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perfil',
                style: AppFonts.bold26.apply(color: AppColors.white),
              ),
              SizedBox(height: 24.h),
              ListenableBuilder(
                listenable: _authManager,
                builder: (context, child) {
                  final user = _authManager.user;
                  final displayName =
                      (user?.name.trim().isNotEmpty ?? false)
                          ? user!.name
                          : 'Usuário Cut Map';
                  final displayEmail =
                      (user?.email.trim().isNotEmpty ?? false)
                          ? user!.email
                          : '';

                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.darkGray,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56.w,
                          height: 56.w,
                          decoration: BoxDecoration(
                            color: AppColors.yellow.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_outline,
                            color: AppColors.yellow,
                            size: 28.s,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: AppFonts.bold18.apply(
                                  color: AppColors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (displayEmail.isNotEmpty) ...[
                                SizedBox(height: 4.h),
                                Text(
                                  displayEmail,
                                  style: AppFonts.regular14.apply(
                                    color: AppColors.lightGray,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 24.h),
              Material(
                color: AppColors.darkGray,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.yellow,
                    size: 24.s,
                  ),
                  title: Text(
                    'Alterar senha',
                    style: AppFonts.medium16.apply(color: AppColors.white),
                  ),
                  subtitle: Text(
                    'Atualize sua senha atual de acesso',
                    style: AppFonts.regular12.apply(color: AppColors.gray),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.gray,
                    size: 24.s,
                  ),
                  onTap: () {
                    context.push(NamedRoutes.profileChangePassword);
                  },
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: OutlinedButton.icon(
                  onPressed: _isLoggingOut ? null : _handleLogout,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.redSnack),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isLoggingOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.redSnack,
                          ),
                        )
                      : const Icon(
                          Icons.logout_rounded,
                          color: AppColors.redSnack,
                        ),
                  label: Text(
                    _isLoggingOut ? 'Saindo...' : 'Sair da conta',
                    style: AppFonts.bold16.apply(color: AppColors.redSnack),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
}
