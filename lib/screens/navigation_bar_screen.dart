import 'package:flutter/material.dart';
import 'package:symphonia/screens/playlist/playlist_screen.dart';
import 'abstract_navigation_screen.dart';
import 'home/home_screen.dart';
import 'trending/trending_screen.dart';
import 'follow/follow_screen.dart';
import 'profile/profile_screen.dart';
import 'setting/setting_screen.dart';
import 'search/search_screen.dart';
import '../widgets/mini_player.dart';

class NavigationBarScreen extends StatefulWidget {
  const NavigationBarScreen({super.key});

  @override
  State<StatefulWidget> createState() => _NavigationBarScreenState();
}

class _NavigationBarScreenState extends State<NavigationBarScreen> {
  int _selectedBody = 0;
  int _selectedBottom = 0;
  String _playlistID = "";
  bool _isNavBarVisible = true;
  late final List<AbstractScreen> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onTabSelected: _onPlaylistSelected),
      TrendingScreen(onTabSelected: _onPlaylistSelected),
      FollowScreen(onTabSelected: _onPlaylistSelected),
      ProfileScreen(onTabSelected: _onPlaylistSelected),
      SettingScreen(onTabSelected: _onPlaylistSelected),
      PlaylistScreen(
        playlistID: _playlistID,
        onTabSelected: _onPlaylistSelected,
      ),
      SearchScreen(onTabSelected: _onPlaylistSelected)
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedBottom = index;
      _selectedBody = index;
    });
  }

  void _onPlaylistSelected(int index, String playlistID) {
    print("Selected Playlist ID: $playlistID");

    setState(() {
      _selectedBody = index; // Navigate to the Playlist screen
      if (_selectedBody >= 0 && _selectedBody < 5) {
        _selectedBottom = index;
      }

      if (playlistID != "") {
        _playlistID = playlistID;

        _screens[5] = PlaylistScreen(
          playlistID: _playlistID,
          onTabSelected: _onPlaylistSelected,
        );
      }
    });

    print("Selected Playlist ID: $_playlistID");
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
            _screens[_selectedBody],
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
          currentIndex: _selectedBottom,
          onTap: _onItemTapped,
          backgroundColor: colourScheme.surface,
          unselectedItemColor: colourScheme.onSurface,
          selectedItemColor: colourScheme.primary,
          showUnselectedLabels: true,
          selectedIconTheme: IconThemeData(size: 35),
          items: _screens.take(5).map((screen) =>
              BottomNavigationBarItem(icon: screen.icon, label: screen.title)
          ).toList(),
        ),
      ),
    );
  }
}