import 'dart:async';
import 'package:flutter/material.dart';
import '../../../controller/player_controller.dart';
import 'shared_mini_player.dart';
import 'shared_tab_navigator.dart';

class RelatedTab extends StatefulWidget {
  final VoidCallback onTopBarTap;
  final Function(int) onTabChange;

  const RelatedTab({
    super.key,
    required this.onTopBarTap,
    required this.onTabChange,
  });

  @override
  State<RelatedTab> createState() => _RelatedTabState();
}

class _RelatedTabState extends State<RelatedTab>
    with AutomaticKeepAliveClientMixin {
  final PlayerController _playerController = PlayerController.getInstance();
  final int _tabIndex = 2; // This is the "THÔNG TIN" tab (index 2)

  // Track current song to detect changes
  String _currentSongId = '';

  // Subscription for song changes
  StreamSubscription? _songChangeSubscription;

  // Flag to track initialization
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeTab();
  }

  void _initializeTab() {
    if (_isInitialized) return;

    // Get initial song ID
    _currentSongId = _playerController.playingSong.id.toString();

    // Listen for song changes
    _songChangeSubscription = _playerController.onSongChange.listen((song) {
      final newSongId = song.id.toString();
      if (_currentSongId != newSongId) {
        setState(() {
          _currentSongId = newSongId;
          // Refresh information content when song changes
          // Add your refresh logic here
        });
      }
    });

    _isInitialized = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeTab();
  }

  @override
  void dispose() {
    _songChangeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      body: Container(
        color: const Color(0xFF1E0811), // Dark maroon background
        child: Column(
          children: [
            // Mini player top bar
            SharedMiniPlayer(onTap: widget.onTopBarTap),

            // Tab indicator
            SharedTabNavigator(
              selectedIndex: _tabIndex,
              onTabTap: _handleTabTap,
            ),

            // Content area
            Expanded(
              child: Center(
                child: Text(
                  "Thông tin bài hát\nCurrent song: ${_playerController.playingSong.title}",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Handle tab selection - switch tabs directly without navigation
  void _handleTabTap(int index) {
    if (index == _tabIndex) return; // Already on this tab
    widget.onTabChange(index);
  }
}
