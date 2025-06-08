import 'package:flutter/material.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/screens/player/tabs/lyrics_tab.dart';
import 'package:symphonia/screens/player/tabs/playlist_tab.dart';
import 'package:symphonia/screens/player/tabs/information_tab.dart';
import 'package:symphonia/screens/player/tabs/shared_tab_navigator.dart';
import '/controller/player_controller.dart';
import '/controller/download_controller.dart';
import 'dart:io';

class DownloadedPlayerScreen extends StatefulWidget {
  final VoidCallback closePlayer;
  final Function(int, String)? onTabSelected;

  const DownloadedPlayerScreen({
    super.key,
    required this.closePlayer,
    this.onTabSelected,
  });

  @override
  State<DownloadedPlayerScreen> createState() => _DownloadedPlayerScreenState();
}

class _DownloadedPlayerScreenState extends State<DownloadedPlayerScreen>
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

  // Downloaded song quality (fixed, not changeable)
  String _downloadedQuality = '320kbps';

  // Tab controller to notify all tabs
  late TabController _tabController;
  bool _tabsInitialized = false;

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

          // Update downloaded quality info
          _updateDownloadedQualityInfo();

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
      _updateDownloadedQualityInfo(); // Update quality info
    });
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
                  color: Theme.of(context).colorScheme.surface,
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
                                    const SizedBox(height: 30),
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
          icon: Icon(
            Icons.expand_more,
            color: Theme.of(context).colorScheme.onSurface,
            size: 30,
          ),
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
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child:
          _playerController.playingSong.imagePath.isEmpty
              ? Icon(
                Icons.music_note,
                size: 100,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              )
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.music_note,
              size: 100,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.music_note,
              size: 100,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.music_note,
              size: 100,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          _playerController.playingSong.artist,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 24,
          ),
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
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(context).colorScheme.outline,
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.2),
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
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 17,
                ),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 17,
                ),
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
            size: _isShuffleOn ? 32 : 25,
            color:
                _isShuffleOn
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        IconButton(
          onPressed: () {
            _playerController.previous();
          },
          icon: Icon(
            Icons.skip_previous,
            size: 40,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary,
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
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            _playerController.next();
          },
          icon: Icon(
            Icons.skip_next,
            size: 40,
            color: Theme.of(context).colorScheme.onSurface,
          ),
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
            size: _playerController.repeatMode == RepeatMode.noRepeat ? 25 : 32,
            color:
                _playerController.repeatMode == RepeatMode.noRepeat
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.primary,
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
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  // Build top control row - only shows quality for downloaded songs
  Widget _buildTopControlRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [_buildQualityDisplay()],
    );
  }

  // Build quality display (non-clickable for downloaded songs)
  Widget _buildQualityDisplay() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.download_done,
            color: Theme.of(context).colorScheme.primary,
            size: 16,
          ),
          SizedBox(width: 6),
          Text(
            Song.getQualityDisplayName(_downloadedQuality),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Update downloaded quality information when song changes
  void _updateDownloadedQualityInfo() async {
    try {
      Map<String, dynamic>? downloadInfo =
          await DownloadController.getDownloadInfo(
            _playerController.playingSong.id,
          );

      if (downloadInfo != null && downloadInfo['quality'] != null) {
        setState(() {
          _downloadedQuality = downloadInfo['quality'];
        });
      }
    } catch (e) {
      print('Error getting download info: $e');
      // Default to 320kbps if we can't get the info
      setState(() {
        _downloadedQuality = '320kbps';
      });
    }
  }
}
