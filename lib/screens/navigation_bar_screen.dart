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
      HomeScreen(onTabSelected: _onPlaylistSelected),
      TrendingScreen(onTabSelected: _onPlaylistSelected),
      FollowScreen(onTabSelected: _onPlaylistSelected),
      ProfileScreen(onTabSelected: _onPlaylistSelected),
      SettingScreen(onTabSelected: _onPlaylistSelected),
    ];

    _extraScreens = [
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
        int sourceTab = _screenSourceTabs[_selectedBody] ?? 0;
        _selectedBottom = sourceTab;
        if (_tabNavigationStacks[sourceTab]!.contains(_selectedBody)) {
          _tabNavigationStacks[sourceTab]!.remove(_selectedBody);
        }
        if (_tabNavigationStacks[sourceTab]!.isEmpty) {
          _tabNavigationStacks[sourceTab]!.add(sourceTab);
        }
        _selectedBody = _tabNavigationStacks[sourceTab]!.last;
        _screenSourceTabs.remove(_selectedBody);
      });
      return;
    }

    setState(() {
      if (_selectedBottom >= 0 && _selectedBottom < 5) {
        if (index >= 0 && index < 5) {
          _selectedBottom = index;
          _tabNavigationStacks[index] = [index];
          _selectedBody = index;
          _screenSourceTabs.removeWhere(
            (key, value) => value == index && key != index,
          );
        } else {
          _tabNavigationStacks[_selectedBottom]!.add(index);
          _selectedBody = index;
          _screenSourceTabs[index] = _selectedBottom;
        }
      }

      if (playlistID.isNotEmpty) {
        _playlistID = playlistID;
        if (index == 5) {
          _screens[5] = PlaylistScreen(
            playlistID: _playlistID,
            onTabSelected: _onPlaylistSelected,
          );
          _extraScreens[0] = _screens[5];
        } else if (index == 6) {
          _screens[6] = PlaylistLocalScreen(
            playlistID: _playlistID,
            onTabSelected: _onPlaylistSelected,
          );
          _extraScreens[1] = _screens[6];
        } else if (index == 8) {
          _screens[8] = UserScreen(
            userID: _playlistID,
            searchQuery: "",
            onTabSelected: _onPlaylistSelected,
          );
          _extraScreens[3] = _screens[8];
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
    int currentEffectiveTab = _selectedBottom;
    if (_selectedBody >= 5 && _screenSourceTabs.containsKey(_selectedBody)) {
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
    int currentEffectiveTab = _selectedBottom;
    if (_selectedBody >= 5 && _screenSourceTabs.containsKey(_selectedBody)) {
      currentEffectiveTab = _screenSourceTabs[_selectedBody]!;
    }

    setState(() {
      int poppedScreen =
          _tabNavigationStacks[currentEffectiveTab]!.removeLast();
      _selectedBody = _tabNavigationStacks[currentEffectiveTab]!.last;
      _screenSourceTabs.remove(poppedScreen);
      if (_selectedBody < 5) {
        _selectedBottom = _selectedBody;
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
