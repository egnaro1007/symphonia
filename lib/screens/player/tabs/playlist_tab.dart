import 'dart:async';
import 'package:flutter/material.dart';
import '../../../controller/player_controller.dart';
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
  int _currentSongIndex = -1;
  int _playlistLength = 0;

  // Subscriptions for changes
  StreamSubscription? _songChangeSubscription;
  StreamSubscription? _playlistChangeSubscription;

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

    // Get initial song ID, index and playlist length
    _currentSongId = _playerController.playingSong.id.toString();
    _currentSongIndex = _playerController.currentSongIndex;
    _playlistLength = _playerController.currentPlaylist.songs.length;

    // Listen for song changes
    _songChangeSubscription = _playerController.onSongChange.listen((song) {
      final newSongId = song.id.toString();
      final newSongIndex = _playerController.currentSongIndex;

      if (_currentSongId != newSongId || _currentSongIndex != newSongIndex) {
        setState(() {
          _currentSongId = newSongId;
          _currentSongIndex = newSongIndex;
        });
      }
    });

    // Listen for playlist changes
    _playlistChangeSubscription = _playerController.onPlaylistChange.listen((
      playlist,
    ) {
      final newPlaylistLength = playlist.songs.length;
      final newSongIndex = _playerController.currentSongIndex;
      final newSongId = _playerController.playingSong.id.toString();

      // Update state if anything changed
      if (_playlistLength != newPlaylistLength ||
          _currentSongIndex != newSongIndex ||
          _currentSongId != newSongId) {
        setState(() {
          _playlistLength = newPlaylistLength;
          _currentSongIndex = newSongIndex;
          _currentSongId = newSongId;
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
    _playlistChangeSubscription?.cancel();
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
    final allSongs = _playerController.currentPlaylist.songs;
    final currentIndex = _currentSongIndex;

    if (allSongs.isEmpty) {
      return const Center(
        child: Text(
          "Không có bài hát nào trong danh sách phát",
          style: TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: allSongs.length,
      onReorder: (oldIndex, newIndex) {
        _playerController.reorderSongs(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final isCurrentSong =
            index == currentIndex &&
            allSongs[index].id.toString() == _currentSongId;

        return Container(
          key: ValueKey(
            allSongs[index].id,
          ), // Important: unique key for each item
          decoration:
              isCurrentSong
                  ? BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  )
                  : null,
          child: SongItem(
            song: allSongs[index],
            showTrailingControls: true,
            isHorizontal: true,
            index: index,
            showIndex: false,
            isDragMode: true, // Enable drag mode
            showDeleteIcon:
                !isCurrentSong, // Show delete icon if not current song
            onDeletePressed:
                !isCurrentSong ? () => _handleDeleteSong(index) : null,
            onTap: () => _handleSongTap(index),
          ),
        );
      },
    );
  }

  // Handle tab selection - switch tabs directly without navigation
  void _handleTabTap(int index) {
    if (index == _tabIndex) return; // Already on this tab
    widget.onTabChange(index);
  }

  // Handle song tap to play specific song from playlist
  void _handleSongTap(int index) {
    _playerController.gotoIndex(index);
  }

  // Handle delete song
  void _handleDeleteSong(int index) {
    _playerController.removeSongFromPlaylist(index);
  }
}
