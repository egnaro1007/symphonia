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
  int _currentSongIndex = -1;
  int _playlistLength = 0;
  bool _isShuffleOn = false;

  // Subscriptions for changes
  StreamSubscription? _songChangeSubscription;
  StreamSubscription? _playlistChangeSubscription;
  StreamSubscription? _shuffleModeChangeSubscription;

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
    _isShuffleOn = _playerController.shuffleMode == ShuffleMode.on;

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

    // Listen for shuffle mode changes
    _shuffleModeChangeSubscription = _playerController.onShuffleModeChange
        .listen((shuffleMode) {
          if (mounted) {
            setState(() {
              _isShuffleOn = shuffleMode == ShuffleMode.on;
              // Force rebuild to update shuffle order display
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
    _shuffleModeChangeSubscription?.cancel();
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
    final allSongs = _playerController.songsInDisplayOrder;
    final currentDisplayIndex =
        _playerController.currentSongIndexInDisplayOrder;

    if (allSongs.isEmpty) {
      return const Center(
        child: Text(
          "Không có bài hát nào trong danh sách phát",
          style: TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        // Show shuffle indicator
        if (_isShuffleOn)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shuffle, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Đang phát ngẫu nhiên",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Playlist content
        Expanded(
          child:
              _isShuffleOn
                  ? _buildShuffledPlaylist(allSongs, currentDisplayIndex)
                  : _buildNormalPlaylist(allSongs, currentDisplayIndex),
        ),
      ],
    );
  }

  Widget _buildNormalPlaylist(List<Song> allSongs, int currentDisplayIndex) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: allSongs.length,
      onReorder: (oldIndex, newIndex) {
        _playerController.reorderSongs(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final isCurrentSong =
            index == currentDisplayIndex &&
            allSongs[index].id.toString() == _currentSongId;

        return Container(
          key: ValueKey(allSongs[index].id),
          decoration:
              isCurrentSong
                  ? BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  )
                  : null,
          child: SongItem(
            song: allSongs[index],
            showTrailingControls: true,
            isHorizontal: true,
            index: index,
            showIndex: false,
            isDragMode: true,
            showDeleteIcon: !isCurrentSong,
            onDeletePressed:
                !isCurrentSong ? () => _handleDeleteSong(index) : null,
            onTap: () => _handleSongTap(index),
          ),
        );
      },
    );
  }

  Widget _buildShuffledPlaylist(List<Song> allSongs, int currentDisplayIndex) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: allSongs.length,
      onReorder: (oldIndex, newIndex) {
        // Only affects shuffle order, not original playlist
        _playerController.reorderSongsInShuffle(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final isCurrentSong =
            index == currentDisplayIndex &&
            allSongs[index].id.toString() == _currentSongId;

        return Container(
          key: ValueKey(allSongs[index].id),
          decoration:
              isCurrentSong
                  ? BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  )
                  : null,
          child: SongItem(
            song: allSongs[index],
            showTrailingControls: true,
            isHorizontal: true,
            index: index,
            showIndex: false,
            isDragMode: true, // Enable drag mode in shuffle
            showDeleteIcon: !isCurrentSong,
            onDeletePressed:
                !isCurrentSong ? () => _handleDeleteSongInShuffle(index) : null,
            onTap: () => _handleSongTapInShuffle(index),
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

  // Handle song tap in shuffle mode
  void _handleSongTapInShuffle(int displayIndex) {
    // Convert display index to actual playlist index
    final playlistIndex = _playerController.displayIndexToPlaylistIndex(
      displayIndex,
    );
    if (playlistIndex >= 0) {
      _playerController.gotoIndex(playlistIndex);
    }
  }

  // Handle delete song in shuffle mode
  void _handleDeleteSongInShuffle(int displayIndex) {
    // Convert display index to actual playlist index
    final playlistIndex = _playerController.displayIndexToPlaylistIndex(
      displayIndex,
    );
    if (playlistIndex >= 0) {
      _playerController.removeSongFromPlaylist(playlistIndex);
    }
  }
}
