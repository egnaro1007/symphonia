import 'package:flutter/material.dart';
import 'abstract_navigation_screen.dart';
import 'home/home_screen.dart';
import 'trending/trending_screen.dart';
import 'follow/follow_screen.dart';
import 'profile/profile_screen.dart';
import 'setting/setting_screen.dart';

class NavigationBarScreen extends StatefulWidget {
  const NavigationBarScreen({super.key});

  @override
  State<StatefulWidget> createState() => _NavigationBarScreenState();
}

class _NavigationBarScreenState extends State<NavigationBarScreen> {
  int _selected = 0;

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

  @override
  Widget build(BuildContext context) {
    final colourScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: _screens[_selected], // Loads selected screen
      bottomNavigationBar: BottomNavigationBar(
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
        // items: [
        //   BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        //   BottomNavigationBarItem(icon: Icon(Icons.timeline), label: "Trending"),
        //   BottomNavigationBarItem(icon: Icon(Icons.subscriptions), label: "Following"),
        //   BottomNavigationBarItem(icon: Icon(Icons.profile), label: "My Account"),
        //   BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings")
        // ],
      ),
    );
  }
}