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
  // Keep track of non-tab screens separately
  late final List<AbstractScreen> _mainTabScreens;
  late final List<AbstractScreen> _extraScreens;

  // Store navigation stack per tab
  final Map<int, List<int>> _tabNavigationStacks = {
    0: [], // Home tab
    1: [], // Trending tab
    2: [], // Follow tab
    3: [], // Profile tab
    4: [], // Setting tab
  };

  // Track previous tab before switching
  int _previousTab = -1;

  // Track the source tab for each non-main screen
  final Map<int, int> _screenSourceTabs = {};

  @override
  void initState() {
    super.initState();
    // Initialize the main tab screens (these will be in the IndexedStack)
    _mainTabScreens = [
      HomeScreen(onTabSelected: _onPlaylistSelected),
      TrendingScreen(onTabSelected: _onPlaylistSelected),
      FollowScreen(onTabSelected: _onPlaylistSelected),
      ProfileScreen(onTabSelected: _onPlaylistSelected),
      SettingScreen(onTabSelected: _onPlaylistSelected),
    ];

    // Initialize extra screens that are accessed from tabs
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

    // Combine all screens for the old interface to work
    _screens = [..._mainTabScreens, ..._extraScreens];

    // Initialize stacks with default screens
    for (int i = 0; i < 5; i++) {
      _tabNavigationStacks[i] = [i];
    }
  }

  void _onItemTapped(int index) {
    if (_selectedBottom == index) {
      // Tapped the same tab again, reset to root screen of this tab
      setState(() {
        _tabNavigationStacks[index] = [index];
        _previousTab = _selectedBottom;
        _selectedBottom = index;
        _selectedBody = index;
      });
    } else {
      // Switched to a different tab
      setState(() {
        _previousTab = _selectedBottom;
        _selectedBottom = index;

        // Restore the last screen of the selected tab
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
    print("Selected Playlist ID: $playlistID");

    // Trường hợp đặc biệt: index = -1 nghĩa là "quay về tab nguồn"
    // (được gọi từ nút back trên PlaylistScreen)
    if (index == -1) {
      setState(() {
        // Lấy tab nguồn của màn hình hiện tại (mặc định là 0 nếu không tìm thấy)
        int sourceTab = _screenSourceTabs[_selectedBody] ?? 0;

        // Cập nhật tab hiện tại
        _selectedBottom = sourceTab;

        // Xóa màn hình hiện tại khỏi stack nếu có
        if (_tabNavigationStacks[sourceTab]!.contains(_selectedBody)) {
          _tabNavigationStacks[sourceTab]!.remove(_selectedBody);
        }

        // Đảm bảo stack không rỗng
        if (_tabNavigationStacks[sourceTab]!.isEmpty) {
          _tabNavigationStacks[sourceTab]!.add(sourceTab);
        }

        // Hiển thị màn hình cuối cùng trong stack
        _selectedBody = _tabNavigationStacks[sourceTab]!.last;

        // Xóa thông tin nguồn gốc
        _screenSourceTabs.remove(_selectedBody);
      });

      print(
        "Navigating back to source tab. Current tab: $_selectedBottom, Current screen: $_selectedBody",
      );
      print("Tab stacks: $_tabNavigationStacks");
      return;
    }

    setState(() {
      // Add the new screen to the current tab's navigation stack
      if (_selectedBottom >= 0 && _selectedBottom < 5) {
        if (index >= 0 && index < 5) {
          // If navigating to a main tab, update everything
          _selectedBottom = index;
          _tabNavigationStacks[index] = [index];
          _selectedBody = index;
        } else {
          // If navigating to an extra screen, add to current tab's stack
          _tabNavigationStacks[_selectedBottom]!.add(index);
          _selectedBody = index;

          // Record which tab this screen came from
          _screenSourceTabs[index] = _selectedBottom;
        }
      }

      if (playlistID != "") {
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

    print("Selected Playlist ID: $_playlistID");
    print("Tab stacks: $_tabNavigationStacks");
    print("Screen source tabs: $_screenSourceTabs");
  }

  void toggleNavigationBar(bool isExpanded) {
    setState(() {
      _isNavBarVisible = !isExpanded;
    });
  }

  // Handle back button presses
  Future<bool> _onWillPop() async {
    if (_selectedBottom >= 0 && _selectedBottom < 5) {
      // If we have screens in the stack besides the root
      if (_tabNavigationStacks[_selectedBottom]!.length > 1) {
        setState(() {
          // Remove the current screen
          int currentScreen =
              _tabNavigationStacks[_selectedBottom]!.removeLast();

          // Show the previous screen
          _selectedBody = _tabNavigationStacks[_selectedBottom]!.last;

          // Clean up the source tab record if needed
          _screenSourceTabs.remove(currentScreen);
        });
        // Prevent default back button behavior
        return false;
      }
    } else {
      // We're in a non-tab screen (like a playlist), go back to the source tab
      int sourceTab =
          _screenSourceTabs[_selectedBody] ??
          0; // Default to Home tab if not found

      setState(() {
        _selectedBottom = sourceTab;

        // If the source tab's stack has this screen, remove it
        if (_tabNavigationStacks[sourceTab]!.contains(_selectedBody)) {
          _tabNavigationStacks[sourceTab]!.remove(_selectedBody);
        }

        // If stack is empty (shouldn't happen), put the main tab screen
        if (_tabNavigationStacks[sourceTab]!.isEmpty) {
          _tabNavigationStacks[sourceTab]!.add(sourceTab);
        }

        // Show the previous screen from the source tab
        _selectedBody = _tabNavigationStacks[sourceTab]!.last;

        // Clean up the source tab record
        _screenSourceTabs.remove(_selectedBody);
      });

      return false; // Prevent default back behavior
    }
    // Allow default back button behavior (exit app)
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedBottom == -1 && _selectedBody == -1) {
      _selectedBottom = _selectedBody = widget.selectedBottom;
      _tabNavigationStacks[_selectedBottom] = [_selectedBottom];
    }

    final colourScheme = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            // Main content with SafeArea
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: IndexedStack(
                      index: _selectedBody,
                      children: _screens,
                    ),
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
      ),
    );
  }
}
