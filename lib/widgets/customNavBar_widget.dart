import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:juegocalamar_frontend/pages/home_screen.dart';
import 'package:juegocalamar_frontend/pages/stats_screen.dart';
import 'package:juegocalamar_frontend/pages/userSettings_screen.dart';
import 'package:juegocalamar_frontend/values/app_routes.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;

  const CustomNavBar({Key? key, required this.selectedIndex}) : super(key: key);

  void _onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex) return;

    switch (index) {
      case 0:
        navigateWithFade(context, StatsScreen());
        break;
      case 1:
        navigateWithFade(context, const HomeScreen());
        break;
      case 2:
        navigateWithFade(context, const UserSettingsScreen());
        break;
    }
  }

  void navigateWithFade(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = Tween(begin: 0.0, end: 1.0).animate(animation);
          return FadeTransition(opacity: fade, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      backgroundColor: Colors.transparent,
      color: Colors.black,
      height: 60,
      animationDuration: const Duration(milliseconds: 300),
      index: selectedIndex,
      items: [
        _buildNavItem(Icons.bar_chart, 0),
        _buildNavItem(Icons.home, 1),
        _buildNavItem(Icons.person, 2),
      ],
      onTap: (index) => _onItemTapped(context, index),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = selectedIndex == index;

    return Icon(
      icon,
      color: isSelected
          ? const Color.fromARGB(255, 105, 240, 174)
          : Colors.white,
      size: 30,
      shadows: isSelected
          ? [
              const Shadow(
                color: Color.fromARGB(255, 105, 240, 174),
                blurRadius: 8,
              ),
            ]
          : [],
    );
  }
}
