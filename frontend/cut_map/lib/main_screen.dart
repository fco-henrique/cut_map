import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/widgets/custom_bottom_nav_bar.dart';
import 'package:cut_map/features/barbershops/screens/barbershops_screen.dart';
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

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onExplore: _openExplore),
      Container(
        color: AppColors.background,
        child: const Center(
          child: Text(
            'Explorar',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
      ),
      const BarbershopsScreen(),
      Container(
        color: AppColors.background,
        child: const Center(
          child: Text(
            'Perfil',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
      ),
    ];
  }

  void _openExplore() => setState(() => _currentIndex = 1);

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
