import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/screens/player/tabs/lyrics_tab.dart';
import 'package:symphonia/screens/player/tabs/playlist_tab.dart';
import 'package:symphonia/screens/player/tabs/information_tab.dart';
import 'package:symphonia/screens/player/tabs/shared_tab_navigator.dart';
import '/controller/player_controller.dart';

class PlayerScreen extends StatefulWidget {
  final VoidCallback closePlayer;

  const PlayerScreen({super.key, required this.closePlayer});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
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

  @override
  void initState() {
    super.initState();

    _isPlaying = _playerController.isPlaying();
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
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Listen to total duration
    _playerController.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    // Listen to song info change
    _playerController.onSongChange.listen((song) {
      if (mounted) {
        setState(() {
          playingSong = song;
          _justReleasedSlider = false;
        });
      }
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

  // // Handle changing tabs within tab view
  // void _changeTabWithinTabView(int index) {
  //   setState(() {
  //     _selectedTabIndex = index;
  //   });
  // }

  // Handle tab change from within any tab
  void _switchToTab(int tabIndex) {
    setState(() {
      _selectedTabIndex = tabIndex;
      _showTabContent = true;
    });
  }

  // Get the appropriate tab widget based on selected index
  Widget _getTabContent() {
    // Create the tab without using navigation
    switch (_selectedTabIndex) {
      case 0:
        return NextTrackTab(
          onTopBarTap: _returnToMainPlayer,
          onTabChange: _switchToTab,
        );
      case 1:
        return LyricsTab(
          onTopBarTap: _returnToMainPlayer,
          onTabChange: _switchToTab,
        );
      case 2:
        return RelatedTab(
          onTopBarTap: _returnToMainPlayer,
          onTabChange: _switchToTab,
        );
      default:
        // Show lyrics tab as fallback if somehow an invalid index is selected
        return LyricsTab(
          onTopBarTap: _returnToMainPlayer,
          onTabChange: _switchToTab,
        );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: false, // Prevent keyboard from causing overflow
    body: SafeArea(
      child:
          _showTabContent
              ? _getTabContent()
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
                                children: [_buildSlider()],
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
                child: Image.network(
                  _playerController.playingSong.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Icon(
                        Icons.music_note,
                        size: 100,
                        color: Colors.white,
                      ),
                ),
              ),
    );
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
            overlayColor: Colors.white.withOpacity(0.2),
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
            // Shuffle functionality (not implemented yet)
          },
          icon: Icon(Icons.shuffle, size: 28, color: Colors.white),
        ),
        IconButton(
          onPressed: () {
            // Previous track (not implemented yet)
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
            // Next track (not implemented yet)
          },
          icon: Icon(Icons.skip_next, size: 40, color: Colors.white),
        ),
        IconButton(
          onPressed: () {
            // Repeat functionality (not implemented yet)
          },
          icon: Icon(Icons.repeat, size: 28, color: Colors.white),
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
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
