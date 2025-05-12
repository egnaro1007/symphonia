import 'package:flutter/material.dart';
import 'package:symphonia/screens/follow/user_screen.dart';
import 'package:symphonia/screens/follow/friend_request_screen.dart';
import 'package:symphonia/screens/follow/search_user_screen.dart';
import 'package:symphonia/screens/playlist/playlist_local_screen.dart';
import 'package:symphonia/screens/playlist/playlist_screen.dart';
import 'abstract_navigation_screen.dart';
import 'home/home_screen.dart';
import 'trending/trending_screen.dart';
import 'follow/follow_screen.dart';
import 'profile/profile_screen.dart';
import 'setting/setting_screen.dart';
import 'search/search_screen.dart';
import 'player/mini_player.dart';

class NavigationBarScreen extends StatefulWidget {
  int selectedBottom;
  NavigationBarScreen({super.key, required this.selectedBottom});

  @override
  State<StatefulWidget> createState() => _NavigationBarScreenState();
}

class _NavigationBarScreenState extends State<NavigationBarScreen> {
  int _selectedBody = -1;
  int _selectedBottom = -1;
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
      PlaylistLocalScreen(
        playlistID: _playlistID,
        onTabSelected: _onPlaylistSelected,
      ),
      SearchScreen(onTabSelected: _onPlaylistSelected),
      UserScreen(
        userID: "1",
        searchQuery: "",
        onTabSelected: _onPlaylistSelected,
      ),
      FriendRequestsScreen(onTabSelected: _onPlaylistSelected),
      SearchUserScreen(onTabSelected: _onPlaylistSelected),
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

        if (_selectedBody == 5) {
          _screens[5] = PlaylistScreen(
            playlistID: _playlistID,
            onTabSelected: _onPlaylistSelected,
          );
        } else if (_selectedBody == 6) {
          _screens[6] = PlaylistLocalScreen(
            playlistID: _playlistID,
            onTabSelected: _onPlaylistSelected,
          );
        } else if (_selectedBody == 8) {
          _screens[8] = UserScreen(
            userID: _playlistID,
            searchQuery: "",
            onTabSelected: _onPlaylistSelected,
          );
        }
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
    if (_selectedBottom == -1 && _selectedBody == -1) {
      _selectedBottom = _selectedBody = widget.selectedBottom;
    }

    final colourScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Main content with SafeArea
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child:
                      _selectedBody >= 0
                          ? _screens[_selectedBody]
                          : Container(),
                ),
                // Only add spacing when navigation bar is visible
                if (_isNavBarVisible)
                  SizedBox(height: 70), // chừa chỗ cho MiniPlayer
              ],
            ),
          ),
          // Mini player doesn't need to be in the SafeArea
          Align(
            alignment: Alignment.bottomCenter,
            child: MiniPlayer(expandPlayerCallback: toggleNavigationBar),
          ),
        ],
      ),
      bottomNavigationBar:
          _isNavBarVisible
              ? BottomNavigationBar(
                currentIndex: _selectedBottom,
                onTap: _onItemTapped,
                backgroundColor: colourScheme.surface,
                unselectedItemColor: colourScheme.onSurface,
                selectedItemColor: colourScheme.primary,
                showUnselectedLabels: true,
                selectedIconTheme: IconThemeData(size: 35),
                items:
                    _screens
                        .take(5)
                        .map(
                          (screen) => BottomNavigationBarItem(
                            icon: screen.icon,
                            label: screen.title,
                          ),
                        )
                        .toList(),
              )
              : null,
    );
  }
}
