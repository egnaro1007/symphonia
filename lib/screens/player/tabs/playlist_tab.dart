import 'dart:async';
import 'package:flutter/material.dart';
import '../../../controller/player_controller.dart';
import '../../../models/song.dart';
import '../../../widgets/song_item.dart';
import 'shared_mini_player.dart';
import 'shared_tab_navigator.dart';

class NextTrackTab extends StatefulWidget {
  final VoidCallback onTopBarTap;
  final Function(int) onTabChange;

  const NextTrackTab({
    super.key,
    required this.onTopBarTap,
    required this.onTabChange,
  });

  @override
  State<NextTrackTab> createState() => _NextTrackTabState();
}

class _NextTrackTabState extends State<NextTrackTab>
    with AutomaticKeepAliveClientMixin {
  final PlayerController _playerController = PlayerController.getInstance();
  final int _tabIndex = 0; // This is the "TIẾP THEO" tab (index 0)

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
          // Refresh playlist content when song changes
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
            Expanded(child: _buildPlaylistContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistContent() {
    final nextSongs = _playerController.queueSongs;

    if (nextSongs.isEmpty) {
      return const Center(
        child: Text(
          "Không có bài hát nào trong danh sách phát tiếp theo",
          style: TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: nextSongs.length,
      itemBuilder: (context, index) {
        return SongItem(
          song: nextSongs[index],
          showTrailingControls: true,
          isHorizontal: true,
          index: index,
          showIndex: true,
        );
      },
    );
  }

  // Handle tab selection - switch tabs directly without navigation
  void _handleTabTap(int index) {
    if (index == _tabIndex) return; // Already on this tab
    widget.onTabChange(index);
  }
}
