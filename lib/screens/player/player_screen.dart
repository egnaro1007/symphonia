import 'package:flutter/material.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/models/playlist.dart';
import 'package:symphonia/screens/player/tabs/lyrics_tab.dart';
import 'package:symphonia/screens/player/tabs/playlist_tab.dart';
import 'package:symphonia/screens/player/tabs/information_tab.dart';
import 'package:symphonia/screens/player/tabs/shared_tab_navigator.dart';
import '/controller/player_controller.dart';
import 'package:symphonia/services/like.dart';
import 'package:symphonia/services/playlist.dart';
import 'package:symphonia/services/data_event_manager.dart';
import 'package:symphonia/services/playlist_notifier.dart';
import 'dart:async';
import 'dart:io';

class PlayerScreen extends StatefulWidget {
  final VoidCallback closePlayer;
  final Function(int, String)? onTabSelected;

  const PlayerScreen({
    super.key,
    required this.closePlayer,
    this.onTabSelected,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  final PlayerController _playerController = PlayerController.getInstance();
  bool _isPlaying = false;
  Song playingSong = Song();
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Duration _tempSliderPosition =
      Duration.zero; // For showing position during drag
  bool _isDraggingSlider = false; // Track if user is dragging
  bool _justReleasedSlider = false; // Track if slider was just released
  int _selectedTabIndex = -1; // No tab selected by default
  bool _showTabContent = false; // Whether to show tab content
  bool _isShuffleOn = false; // Track shuffle state

  // New state variables for top control row
  bool _isLiked = false; // Track if song is liked
  String _selectedQuality = '320kbps'; // Track selected quality
  List<String> _availableQualities = []; // Dynamic list based on current song

  // Tab controller to notify all tabs
  late TabController _tabController;
  bool _tabsInitialized = false;
  StreamSubscription<DataEvent>? _eventSubscription;

  // Caching tab instances to preserve state
  late final List<Widget> _tabWidgets = [
    NextTrackTab(onTopBarTap: _returnToMainPlayer, onTabChange: _switchToTab),
    LyricsTab(onTopBarTap: _returnToMainPlayer, onTabChange: _switchToTab),
    RelatedTab(
      onTopBarTap: _returnToMainPlayer,
      closePlayer: widget.closePlayer,
      onTabChange: _switchToTab,
      onTabSelected: widget.onTabSelected,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize tab controller with 3 tabs
    _tabController = TabController(length: 3, vsync: this);

    _isPlaying = _playerController.isPlaying();
    _isShuffleOn = _playerController.shuffleMode == ShuffleMode.on;
    _tempSliderPosition = _currentPosition; // Initialize temp position

    // Initialize selected quality from player controller
    _selectedQuality = _playerController.currentQuality;

    _playerController.getDuration().then((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    _playerController.getCurrentPosition().then((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _tempSliderPosition = position;
        });
      }
    });

    // Listen to position updates
    _playerController.onPositionChanged.listen((position) {
      if (mounted) {
        // Only update current position if not dragging
        if (!_isDraggingSlider) {
          setState(() {
            _currentPosition = position;
            // Reset the just released flag once position updates after seeking
            if (_justReleasedSlider &&
                (_tempSliderPosition.inMilliseconds - position.inMilliseconds)
                        .abs() <
                    500) {
              _justReleasedSlider = false;
            }
          });
        }
      }
    });

    // Listen to state changes
    _playerController.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    // Listen to total duration
    _playerController.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration ?? Duration.zero;
        });
      }
    });

    // Listen to song info change
    _playerController.onSongChange.listen((song) {
      if (mounted) {
        setState(() {
          playingSong = song;
          _justReleasedSlider = false;

          // Update available qualities and current quality
          _updateQualityInfo();

          // Check if the new song is liked
          _checkLikeStatus();

          // Force rebuild all tabs when song changes
          _forceTabsUpdate();
        });
      }
    });

    // Listen to shuffle mode changes
    _playerController.onShuffleModeChange.listen((shuffleMode) {
      if (mounted) {
        setState(() {
          _isShuffleOn = shuffleMode == ShuffleMode.on;
        });
      }
    });

    // Initialize tabs immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTabs();
      _checkLikeStatus(); // Check initial like status
      _updateQualityInfo(); // Update quality info
    });

    // Setup DataEventManager listener for like status changes
    _setupEventListener();
  }

  // Initialize all tabs immediately
  void _initializeTabs() {
    if (_tabsInitialized) return;

    // Pre-build all tabs to ensure they're initialized
    for (int i = 0; i < _tabWidgets.length; i++) {
      // Notify the tab controller to ensure all tabs get built
      _tabController.animateTo(i, duration: Duration.zero);
    }

    // Reset to default tab
    _tabController.animateTo(0, duration: Duration.zero);
    _tabsInitialized = true;
  }

  // Force update all tabs when song changes
  void _forceTabsUpdate() {
    if (!mounted) return;

    // Force a rebuild of the IndexedStack by updating its key
    setState(() {
      // The state update itself will trigger rebuilds
    });
  }

  // Toggle to show tab content
  void _switchToTabContent() {
    setState(() {
      _showTabContent = true;
    });
  }

  // Toggle back to main player
  void _returnToMainPlayer() {
    setState(() {
      _showTabContent = false;
      _selectedTabIndex = -1; // Reset to no selection when returning to player
    });
  }

  // Handle tab change from within any tab
  void _switchToTab(int tabIndex) {
    setState(() {
      _selectedTabIndex = tabIndex;
      _showTabContent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent keyboard from causing overflow
      body: SafeArea(
        child:
            _showTabContent
                ? IndexedStack(
                  key: ValueKey('tabs-stack-${playingSong.title}'),
                  index:
                      _selectedTabIndex < 0 ||
                              _selectedTabIndex >= _tabWidgets.length
                          ? 1
                          : _selectedTabIndex, // Default to lyrics if invalid
                  children: _tabWidgets,
                )
                : Container(
                  color: const Color(0xFF1E0811), // Dark maroon background
                  height: MediaQuery.of(context).size.height,
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.vertical,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top section
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCloseButton(),
                              const SizedBox(height: 40),
                              _buildAlbumCover(),
                              const SizedBox(height: 30),
                              _buildSongInfo(),
                            ],
                          ),

                          // Bottom section
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildTopControlRow(),
                                    const SizedBox(height: 20),
                                    _buildSlider(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                              _buildPlaybackControls(),
                              const SizedBox(height: 30),
                              _buildBottomTabs(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, top: 12.0),
      child: Align(
        alignment: Alignment.topLeft,
        child: IconButton(
          icon: Icon(Icons.expand_more, color: Colors.white, size: 30),
          onPressed: widget.closePlayer,
        ),
      ),
    );
  }

  Widget _buildAlbumCover() {
    return Container(
      height: 250,
      width: 250,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      child:
          _playerController.playingSong.imagePath.isEmpty
              ? Icon(Icons.music_note, size: 100, color: Colors.white)
              : ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildCoverImage(),
              ),
    );
  }

  Widget _buildCoverImage() {
    String imagePath = _playerController.playingSong.imagePath;

    // Check if it's a network URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.music_note, size: 100, color: Colors.white),
          );
        },
      );
    }
    // Check if it's an asset path
    else if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.music_note, size: 100, color: Colors.white),
          );
        },
      );
    }
    // Treat as local file path
    else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.music_note, size: 100, color: Colors.white),
          );
        },
      );
    }
  }

  Widget _buildSongInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _playerController.playingSong.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          _playerController.playingSong.artist,
          style: TextStyle(color: Colors.white70, fontSize: 24),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSlider() {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade600,
            thumbColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.2),
          ),
          child: Slider(
            value:
                _totalDuration.inSeconds > 0
                    ? (_isDraggingSlider || _justReleasedSlider
                        ? _tempSliderPosition.inSeconds.toDouble()
                        : _currentPosition.inSeconds.toDouble())
                    : 0.0,
            max:
                _totalDuration.inSeconds > 0
                    ? (_totalDuration.inSeconds.toDouble() + 1)
                    : 1.0,
            onChangeStart: (value) {
              setState(() {
                _isDraggingSlider = true;
                _justReleasedSlider = false;
                _tempSliderPosition = Duration(seconds: value.toInt());
              });
            },
            onChanged: (value) {
              // Update temp position for visual feedback
              setState(() {
                _tempSliderPosition = Duration(seconds: value.toInt());
              });
            },
            onChangeEnd: (value) {
              // Only seek when dragging ends
              if (_totalDuration.inSeconds > 0) {
                final newPosition = Duration(seconds: value.toInt());
                _playerController.seek(newPosition);
                setState(() {
                  _isDraggingSlider = false;
                  _justReleasedSlider = true;
                  _tempSliderPosition = newPosition;
                });
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 17.0, right: 17.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(
                  _isDraggingSlider || _justReleasedSlider
                      ? _tempSliderPosition
                      : _currentPosition,
                ),
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _playerController.changeShuffleMode();
              _isShuffleOn = _playerController.shuffleMode == ShuffleMode.on;
            });
          },
          icon: Icon(
            Icons.shuffle,
            size: _isShuffleOn ? 32 : 28,
            color:
                _isShuffleOn
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
          ),
        ),
        IconButton(
          onPressed: () {
            _playerController.previous();
          },
          icon: Icon(Icons.skip_previous, size: 40, color: Colors.white),
        ),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: IconButton(
            onPressed: () {
              if (_isPlaying) {
                _playerController.pause();
              } else {
                _playerController.play();
              }
            },
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              size: 40,
              color: Colors.black,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            _playerController.next();
          },
          icon: Icon(Icons.skip_next, size: 40, color: Colors.white),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _playerController.changeRepeatMode();
            });
          },
          icon: Icon(
            _playerController.repeatMode == RepeatMode.repeatOne
                ? Icons.repeat_one
                : Icons.repeat,
            size: _playerController.repeatMode == RepeatMode.noRepeat ? 28 : 32,
            color:
                _playerController.repeatMode == RepeatMode.noRepeat
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomTabs() {
    // Make sure the selectedIndex is properly set before rendering
    // This ensures the tab is visibly highlighted when in the player screen
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SharedTabNavigator(
        selectedIndex: _selectedTabIndex,
        onTabTap: (index) {
          setState(() {
            _selectedTabIndex = index;
            _switchToTabContent();
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _playerController.onPositionChanged.drain();
    _playerController.onPlayerStateChanged.drain();
    _playerController.onDurationChanged.drain();
    _tabController.dispose();
    _eventSubscription?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  // Check if current song is liked via API
  void _checkLikeStatus() async {
    try {
      bool isLiked = await LikeOperations.getLikeStatus(
        _playerController.playingSong,
      );
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
        });
      }
    } catch (e) {
      print('Error checking like status: $e');
    }
  }

  // Toggle like status
  void _toggleLike() async {
    try {
      bool success;
      if (_isLiked) {
        success = await LikeOperations.unlike(_playerController.playingSong);
      } else {
        success = await LikeOperations.like(_playerController.playingSong);
      }

      if (success) {
        setState(() {
          _isLiked = !_isLiked;
        });

        // Show feedback to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isLiked ? 'Đã thêm vào yêu thích' : 'Đã xóa khỏi yêu thích',
            ),
            duration: Duration(seconds: 1),
            backgroundColor: _isLiked ? Colors.red : Colors.grey,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Có lỗi xảy ra khi ${_isLiked ? 'xóa khỏi' : 'thêm vào'} yêu thích',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error toggling like status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra'), backgroundColor: Colors.red),
      );
    }
  }

  // Build top control row with 3 buttons
  Widget _buildTopControlRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildLikeButton(),
        _buildQualitySelector(),
        _buildAddToPlaylistButton(),
      ],
    );
  }

  // Build like button
  Widget _buildLikeButton() {
    return IconButton(
      onPressed: _toggleLike,
      icon: Icon(
        _isLiked ? Icons.favorite : Icons.favorite_border,
        color: _isLiked ? Colors.red : Colors.white70,
        size: 28,
      ),
    );
  }

  // Build quality selector
  Widget _buildQualitySelector() {
    return GestureDetector(
      onTap: () {
        _showQualitySelector();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white30),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Song.getQualityDisplayName(_selectedQuality),
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  // Build add to playlist button
  Widget _buildAddToPlaylistButton() {
    return IconButton(
      onPressed: () {
        _showAddToPlaylistDialog();
      },
      icon: Icon(Icons.playlist_add, color: Colors.white70, size: 28),
    );
  }

  // Show quality selector dialog
  void _showQualitySelector() {
    if (_availableQualities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không có chất lượng âm thanh khác cho bài hát này'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF2A1219),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chọn chất lượng âm thanh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              ..._availableQualities.map((quality) {
                int fileSize = _playerController.getFileSizeForQuality(quality);
                String fileSizeText =
                    fileSize > 0 ? ' (${_formatFileSize(fileSize)})' : '';

                return ListTile(
                  title: Row(
                    children: [
                      Text(
                        Song.getQualityDisplayName(quality),
                        style: TextStyle(color: Colors.white),
                      ),
                      if (fileSizeText.isNotEmpty)
                        Text(
                          fileSizeText,
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                    ],
                  ),
                  trailing:
                      _selectedQuality == quality
                          ? Icon(Icons.check, color: Colors.white)
                          : null,
                  onTap: () async {
                    Navigator.pop(context);
                    await _changeQuality(quality);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // Change audio quality
  Future<void> _changeQuality(String quality) async {
    if (quality == _selectedQuality) return;

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Đang chuyển sang chất lượng ${Song.getQualityDisplayName(quality)}...',
            ),
          ],
        ),
        duration: Duration(seconds: 3),
      ),
    );

    try {
      bool success = await _playerController.changeAudioQuality(quality);

      // Clear the loading snackbar
      ScaffoldMessenger.of(context).clearSnackBars();

      if (success) {
        setState(() {
          _selectedQuality = quality;
        });

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã chuyển sang chất lượng ${Song.getQualityDisplayName(quality)}',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Show error feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể chuyển sang chất lượng ${Song.getQualityDisplayName(quality)}',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error changing quality: $e');

      // Clear the loading snackbar
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra khi chuyển chất lượng'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Format file size in human readable format
  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '';

    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int suffixIndex = 0;
    double size = bytes.toDouble();

    while (size > 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }

    return '${size.toStringAsFixed(1)}${suffixes[suffixIndex]}';
  }

  // Show add to playlist dialog
  void _showAddToPlaylistDialog() async {
    // Get existing playlists
    List<PlayList> localPlaylists =
        await PlayListOperations.getLocalPlaylists();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF2A1219),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height *
                0.5, // Limit to 70% of screen height
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Thêm vào danh sách phát',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Divider(color: Colors.white30),

              // Scrollable playlist list
              Flexible(
                child:
                    localPlaylists.isEmpty
                        ? Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Chưa có playlist nào',
                            style: TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          itemCount: localPlaylists.length,
                          itemBuilder: (context, index) {
                            final playlist = localPlaylists[index];
                            return ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.grey[600],
                                ),
                                child:
                                    playlist.picture.isNotEmpty
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: Image.network(
                                            playlist.picture,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Icon(
                                                Icons.queue_music,
                                                color: Colors.white,
                                              );
                                            },
                                          ),
                                        )
                                        : Icon(
                                          Icons.queue_music,
                                          color: Colors.white,
                                        ),
                              ),
                              title: Text(
                                playlist.title,
                                style: TextStyle(color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                playlist.creator,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () async {
                                Navigator.pop(context);
                                await _addToPlaylist(
                                  playlist.id,
                                  playlist.title,
                                );
                              },
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Add current song to specific playlist
  Future<void> _addToPlaylist(String playlistId, String playlistName) async {
    try {
      bool success = await PlayListOperations.addSongToPlaylist(
        playlistId,
        _playerController.playingSong.id.toString(),
      );

      if (success) {
        // Notify playlist updates
        DataEventManager.instance.notifyPlaylistChanged(playlistId: playlistId);
        PlaylistUpdateNotifier().notifyPlaylistUpdate();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã thêm "${_playerController.playingSong.title}" vào "$playlistName"',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể thêm bài hát vào playlist'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error adding song to playlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra khi thêm bài hát vào playlist'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Setup DataEventManager listener for like status changes
  void _setupEventListener() {
    _eventSubscription = DataEventManager.instance.events.listen((event) {
      if (event.type == DataEventType.likeChanged) {
        int? songId = event.data['songId'];
        if (songId == _playerController.playingSong.id) {
          _checkLikeStatus(); // Refresh like status when this song's like status changes
        }
      }
    });
  }

  // Update quality information when song changes
  void _updateQualityInfo() {
    _availableQualities = _playerController.getAvailableQualities();
    _selectedQuality = _playerController.currentQuality;

    // If current quality is not available for this song, update to first available
    if (_availableQualities.isNotEmpty &&
        !_availableQualities.contains(_selectedQuality)) {
      _selectedQuality =
          _availableQualities.contains('320kbps')
              ? '320kbps'
              : _availableQualities.first;
    }
  }
}
