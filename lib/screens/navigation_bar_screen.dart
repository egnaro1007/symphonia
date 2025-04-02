import 'package:flutter/material.dart';
import 'abstract_navigation_screen.dart';
import 'home/home_screen.dart';
import 'trending/trending_screen.dart';
import 'follow/follow_screen.dart';
import 'profile/profile_screen.dart';
import 'setting/setting_screen.dart';
import '../widgets/mini_player.dart';

class NavigationBarScreen extends StatefulWidget {
  const NavigationBarScreen({super.key});

  @override
  State<StatefulWidget> createState() => _NavigationBarScreenState();
}

class _NavigationBarScreenState extends State<NavigationBarScreen> {
  int _selected = 0;
  bool _isNavBarVisible = true;

  final List<AbstractScreen> _screens = [
    const HomeScreen(),
    const TrendingScreen(),
    const FollowScreen(),
    const ProfileScreen(),
    const SettingScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selected = index;
    });
  }

  void toggleNavigationBar(bool isExpanded) {
    setState(() {
      _isNavBarVisible = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colourScheme = Theme.of(context).colorScheme;
    return Scaffold(
        body: Stack(
          children: [
            _screens[_selected],
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MiniPlayer(expandPlayerCallback: toggleNavigationBar),
            ),
          ],
        ),
      bottomNavigationBar: Visibility (
        visible: _isNavBarVisible,
        child: BottomNavigationBar(
          currentIndex: _selected,
          onTap: _onItemTapped,
          backgroundColor: colourScheme.surface,
          unselectedItemColor: colourScheme.onSurface,
          selectedItemColor: colourScheme.primary,
          showUnselectedLabels: true,
          selectedIconTheme: IconThemeData(size: 35),
          items: _screens.map((screen) =>
              BottomNavigationBarItem(icon: screen.icon, label: screen.title)
          ).toList(),
        ),
      ),
    );
  }
}