import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/widgets/custom_bottom_nav_bar.dart';
import 'package:cut_map/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(), // Aba 0: Início
    // const ExploreView(),    // Aba 1: Explorar
    // const BarbershopsView(),// Aba 2: Barbearias
    // const ProfileView(),    // Aba 3: Perfil
    Container(
      color: AppColors.background,
      child: Center(
        child: Text(
          'Explorar',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    ),
    Container(
      color: AppColors.background,
      child: Center(
        child: Text(
          'Barbearias',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    ),
    Container(
      color: AppColors.background,
      child: Center(
        child: Text(
          'Perfil',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
