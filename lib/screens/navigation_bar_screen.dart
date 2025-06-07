import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:symphonia/controller/download_controller.dart';
import 'package:symphonia/screens/abstract_navigation_screen.dart';
import 'package:symphonia/screens/follow/friend_screen.dart';
import 'package:symphonia/screens/follow/friend_request_screen.dart';
import 'package:symphonia/screens/follow/search_user_screen.dart';
import 'package:symphonia/screens/follow/user_screen.dart';
import 'package:symphonia/screens/home/home_screen.dart';
import 'package:symphonia/screens/player/mini_player.dart';
import 'package:symphonia/screens/playlist/playlist_screen.dart';

import 'package:symphonia/screens/profile/profile_screen.dart';
import 'package:symphonia/screens/profile/song_list_screen.dart';
import 'package:symphonia/screens/search/search_screen.dart';
import 'package:symphonia/screens/setting/setting_screen.dart';
import 'package:symphonia/screens/trending/trending_screen.dart';
import 'package:symphonia/screens/playlist/playlist_creation_screen.dart';
import 'package:symphonia/services/history.dart';
import 'package:symphonia/services/like.dart';
import 'package:symphonia/constants/screen_index.dart';

class NavigationBarScreen extends StatefulWidget {
  final int selectedBottom;
  const NavigationBarScreen({super.key, required this.selectedBottom});

  @override
  State<StatefulWidget> createState() => _NavigationBarScreenState();
}

class _NavigationBarScreenState extends State<NavigationBarScreen> {
  int _selectedBody = -1;
  int _selectedBottom = -1;
  String _playlistID = "";
  bool _isNavBarVisible = true;
  late final List<AbstractScreen> _screens;
  late final List<AbstractScreen> _mainTabScreens;
  late final List<AbstractScreen> _extraScreens;

  final Map<int, List<int>> _tabNavigationStacks = {
    0: [], // Home tab
    1: [], // Trending tab
    2: [], // Follow tab
    3: [], // Profile tab
    4: [], // Setting tab
  };

  final Map<int, int> _screenSourceTabs =
      {}; // Track the source tab for each non-main screen

  @override
  void initState() {
    super.initState();
    _mainTabScreens = [
      HomeScreen(onTabSelected: _onPlaylistSelected), // ScreenIndex.home
      TrendingScreen(
        onTabSelected: _onPlaylistSelected,
      ), // ScreenIndex.trending
      FollowScreen(onTabSelected: _onPlaylistSelected), // ScreenIndex.follow
      ProfileScreen(onTabSelected: _onPlaylistSelected), // ScreenIndex.profile
      SettingScreen(onTabSelected: _onPlaylistSelected), // ScreenIndex.setting
    ];

    _extraScreens = [
      PlaylistScreen(
        // ScreenIndex.playlist (5)
        playlistID: _playlistID,
        onTabSelected: _onPlaylistSelected,
      ),
      SearchScreen(
        onTabSelected: _onPlaylistSelected,
      ), // ScreenIndex.search (6)
      UserScreen(
        // ScreenIndex.userProfile (7)
        key: const ValueKey("default"),
        userID: "1",
        searchQuery: "",
        onTabSelected: _onPlaylistSelected,
      ),
      FriendRequestsScreen(
        onTabSelected: _onPlaylistSelected,
      ), // ScreenIndex.friendRequests (8)
      SearchUserScreen(
        onTabSelected: _onPlaylistSelected,
      ), // ScreenIndex.searchUser (9)
      SongListScreen(
        // ScreenIndex.recentlyPlayed (10)
        key: const ValueKey("recently_played"),
        screenTitle: 'Nghe gần đây',
        songsLoader: () => HistoryOperations.getRecentlyPlayedSongs(),
        titleIcon: Icons.schedule,
        titleColor: Colors.orange,
        onTabSelected: _onPlaylistSelected,
      ),
      SongListScreen(
        // ScreenIndex.favorites (11)
        key: const ValueKey("favorites"),
        screenTitle: 'Yêu thích',
        songsLoader: () => LikeOperations.getLikeSongs(),
        titleIcon: Icons.favorite,
        titleColor: Colors.blue,
        onTabSelected: _onPlaylistSelected,
      ),
      SongListScreen(
        // ScreenIndex.downloaded (12)
        key: const ValueKey("downloaded"),
        screenTitle: 'Đã tải',
        songsLoader: () => DownloadController.getDownloadedSongs(),
        titleIcon: Icons.download_done,
        titleColor: Colors.purple,
        onTabSelected: _onPlaylistSelected,
      ),
      PlaylistCreationScreen(
        onTabSelected: _onPlaylistSelected,
      ), // ScreenIndex.playlistCreation (13)
    ];

    _screens = [..._mainTabScreens, ..._extraScreens];

    for (int i = 0; i < 5; i++) {
      _tabNavigationStacks[i] = [i];
    }
  }

  void _onItemTapped(int index) {
    if (_selectedBottom == index) {
      setState(() {
        _tabNavigationStacks[index] = [index];
        _selectedBottom = index;
        _selectedBody = index;
      });
    } else {
      setState(() {
        _selectedBottom = index;
        if (_tabNavigationStacks[index]!.isNotEmpty) {
          _selectedBody = _tabNavigationStacks[index]!.last;
        } else {
          _selectedBody = index;
          _tabNavigationStacks[index] = [index];
        }
      });
    }
  }

  void _onPlaylistSelected(int index, String playlistID) {
    if (index == -1) {
      setState(() {
        // Find which tab contains the current screen in its navigation stack
        int sourceTab = 0; // Default fallback
        for (int tab = 0; tab < 5; tab++) {
          if (_tabNavigationStacks[tab]!.contains(_selectedBody)) {
            sourceTab = tab;
            break;
          }
        }

        // If not found in any tab stack, use _screenSourceTabs as fallback
        if (sourceTab == 0 && _screenSourceTabs.containsKey(_selectedBody)) {
          sourceTab = _screenSourceTabs[_selectedBody]!;
        }

        // Remove current screen from its tab's navigation stack
        if (_tabNavigationStacks[sourceTab]!.contains(_selectedBody)) {
          _tabNavigationStacks[sourceTab]!.remove(_selectedBody);
        }

        // Ensure the tab stack is not empty
        if (_tabNavigationStacks[sourceTab]!.isEmpty) {
          _tabNavigationStacks[sourceTab]!.add(sourceTab);
        }

        // Navigate to the previous screen in the stack
        _selectedBody = _tabNavigationStacks[sourceTab]!.last;
        _selectedBottom = sourceTab;

        // Clean up the screen source tracking
        _screenSourceTabs.remove(_selectedBody);
      });
      return;
    }

    setState(() {
      if (_selectedBottom >= 0 && _selectedBottom < 5) {
        if (index >= 0 && index < 5) {
          // Navigating to another main tab
          _selectedBottom = index;
          _tabNavigationStacks[index] = [index];
          _selectedBody = index;
          _screenSourceTabs.removeWhere(
            (key, value) => value == index && key != index,
          );
        } else {
          // Navigating to an extra screen from a main tab
          _tabNavigationStacks[_selectedBottom]!.add(index);
          _selectedBody = index;
          _screenSourceTabs[index] = _selectedBottom;
        }
      }

      if (playlistID.isNotEmpty) {
        _playlistID = playlistID;
        if (index == ScreenIndex.playlist.value) {
          _screens[ScreenIndex.playlist.value] = PlaylistScreen(
            playlistID: _playlistID,
            onTabSelected: _onPlaylistSelected,
          );
          _extraScreens[0] = _screens[ScreenIndex.playlist.value];
        } else if (index == ScreenIndex.userProfile.value) {
          _screens[ScreenIndex.userProfile.value] = UserScreen(
            key: ValueKey(_playlistID),
            userID: _playlistID,
            searchQuery: "",
            onTabSelected: _onPlaylistSelected,
          );
          _extraScreens[2] = _screens[ScreenIndex.userProfile.value];
        }
      }
    });
  }

  void toggleNavigationBar(bool isExpanded) {
    setState(() {
      _isNavBarVisible = !isExpanded;
    });
  }

  bool _canHandlePopInternally() {
    // Find which tab contains the current screen in its navigation stack
    int currentEffectiveTab = _selectedBottom; // Default fallback
    for (int tab = 0; tab < 5; tab++) {
      if (_tabNavigationStacks[tab]!.contains(_selectedBody)) {
        currentEffectiveTab = tab;
        break;
      }
    }

    // If not found in any tab stack, use _screenSourceTabs as fallback
    if (currentEffectiveTab == _selectedBottom &&
        _screenSourceTabs.containsKey(_selectedBody)) {
      currentEffectiveTab = _screenSourceTabs[_selectedBody]!;
    }

    if (currentEffectiveTab >= 0 && currentEffectiveTab < 5) {
      if (_tabNavigationStacks.containsKey(currentEffectiveTab) &&
          _tabNavigationStacks[currentEffectiveTab]!.length > 1) {
        return true; // Can pop from internal stack
      }
    }
    return false; // Cannot handle internally, let system pop
  }

  void _performInternalPop() {
    // Assumes _canHandlePopInternally() was true
    // Find which tab contains the current screen in its navigation stack
    int currentEffectiveTab = _selectedBottom; // Default fallback
    for (int tab = 0; tab < 5; tab++) {
      if (_tabNavigationStacks[tab]!.contains(_selectedBody)) {
        currentEffectiveTab = tab;
        break;
      }
    }

    // If not found in any tab stack, use _screenSourceTabs as fallback
    if (currentEffectiveTab == _selectedBottom &&
        _screenSourceTabs.containsKey(_selectedBody)) {
      currentEffectiveTab = _screenSourceTabs[_selectedBody]!;
    }

    setState(() {
      int poppedScreen =
          _tabNavigationStacks[currentEffectiveTab]!.removeLast();
      _selectedBody = _tabNavigationStacks[currentEffectiveTab]!.last;
      _screenSourceTabs.remove(poppedScreen);
      if (_selectedBody < 5) {
        _selectedBottom = _selectedBody;
      } else {
        _selectedBottom = currentEffectiveTab;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedBottom == -1 && _selectedBody == -1) {
      _selectedBottom = widget.selectedBottom;
      _selectedBody = widget.selectedBottom;
      if (_tabNavigationStacks.containsKey(widget.selectedBottom) &&
          _tabNavigationStacks[widget.selectedBottom]!.isEmpty) {
        _tabNavigationStacks[widget.selectedBottom] = [widget.selectedBottom];
      } else if (!_tabNavigationStacks.containsKey(widget.selectedBottom)) {
        _tabNavigationStacks[widget.selectedBottom] = [widget.selectedBottom];
      }
    }

    final colourScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_canHandlePopInternally(),
      onPopInvoked: (bool didPop) {
        if (didPop) {
          return; // System handled pop or PopScope allowed it.
        }
        // If didPop is false, canPop was false, so we perform internal pop.
        _performInternalPop();
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: IndexedStack(
                      index:
                          _selectedBody >= 0 && _selectedBody < _screens.length
                              ? _selectedBody
                              : 0,
                      children: _screens,
                    ),
                  ),
                  if (_isNavBarVisible)
                    const SizedBox(height: 70), // Space for MiniPlayer
                ],
              ),
            ),
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
                  type: BottomNavigationBarType.fixed,
                  selectedIconTheme: const IconThemeData(size: 35),
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
      ),
    );
  }
}
