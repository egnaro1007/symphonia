import 'package:flutter/material.dart';
import 'adaptive_player_screen.dart';
import '/controller/player_controller.dart';
import 'dart:async';
import 'dart:io';

class MiniPlayer extends StatefulWidget {
  final Function(bool) expandPlayerCallback;
  final Function(int, String)? onTabSelected;

  const MiniPlayer({
    super.key,
    required this.expandPlayerCallback,
    this.onTabSelected,
  });

  @override
  MiniPlayerState createState() => MiniPlayerState();
}

class MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  final PlayerController _playerController = PlayerController.getInstance();
  late AnimationController _controller;
  bool _isExpanded = false;
  bool _isPlaying = false;
  double _progress = 0.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _hasSong = false;
  StreamSubscription? _songChangeSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    // Listen for song changes
    _songChangeSubscription = _playerController.onSongChange.listen((song) {
      if (mounted) {
        setState(() {
          _progress = 0.0;
          _currentPosition = Duration.zero;
          _hasSong = _playerController.hasSong;
          // Force a full UI refresh when song changes
        });
        // Get new duration for the new song
        _playerController.getDuration().then((duration) {
          if (mounted) {
            setState(() {
              _totalDuration = duration;
            });
          }
        });
      }
    });

    // Listen for player state changes
    _playerStateSubscription = _playerController.onPlayerStateChanged.listen((
      state,
    ) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    // Listen for position changes
    _positionSubscription = _playerController.onPositionChanged.listen((
      position,
    ) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          if (_totalDuration.inMilliseconds > 0) {
            _progress =
                _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
          }
        });
      }
    });

    // Listen for duration changes
    _durationSubscription = _playerController.onDurationChanged.listen((
      duration,
    ) {
      if (mounted) {
        setState(() {
          _totalDuration = duration ?? Duration.zero;
        });
      }
    });

    // Initialize playing state
    _isPlaying = _playerController.isPlaying();
    _hasSong = _playerController.hasSong;

    // Get initial duration
    _playerController.getDuration().then((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    // Get initial position
    _playerController.getCurrentPosition().then((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _songChangeSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    super.dispose();
  }

  void _togglePlayer() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _controller.forward() : _controller.reverse();
    });
    widget.expandPlayerCallback(_isExpanded);
  }

  bool _isPressed = false;

  void _handlePlayPauseInteraction({
    TapDownDetails? down,
    bool cancel = false,
  }) {
    if (!_hasSong) return;

    setState(() {
      if (down != null) {
        _isPressed = true;
      } else if (!cancel) {
        _isPressed = false;
        _isPlaying ? _playerController.pause() : _playerController.play();
      } else {
        _isPressed = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Sync local state with controller state on every build
    // This ensures UI is always up to date even if song change event was missed
    if (_hasSong != _playerController.hasSong) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasSong = _playerController.hasSong;
          });
        }
      });
    }

    return AnimatedContainer(
      duration: Duration(
        milliseconds: 300,
      ), // Reduced from 1000ms for smoother transition
      height: _isExpanded ? screenHeight : 80,
      width: screenWidth,
      child:
          _isExpanded
              ? SizedBox(
                height: screenHeight,
                child: AdaptivePlayerScreen(
                  closePlayer: _togglePlayer,
                  onTabSelected: widget.onTabSelected,
                ),
              )
              : GestureDetector(
                onTap: _hasSong ? _togglePlayer : null,
                child: _buildMiniPlayer(),
              ),
    );
  }

  Widget _buildMiniPlayer() {
    return Column(
      children: [
        Container(
          height: 76,
          padding: const EdgeInsets.only(left: 15, right: 15),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.inverseSurface,
          ),
          child: Row(
            children: [
              // Ảnh cover
              Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(right: 15),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child:
                    _hasSong &&
                            _playerController.playingSong.imagePath.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: _buildCoverImage(),
                        )
                        : Icon(
                          Icons.music_note,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
              ),

              // Tiêu đề và tên nghệ sĩ
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _hasSong
                            ? _playerController.playingSong.title
                            : "Không có gì đang phát",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onInverseSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_hasSong &&
                          _playerController.playingSong.artist.isNotEmpty)
                        Text(
                          _playerController.playingSong.artist,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onInverseSurface.withOpacity(0.7),
                            fontSize: 17,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),

              // Play/Pause button
              Opacity(
                opacity: _hasSong ? 1.0 : 0.5,
                child: GestureDetector(
                  onTapDown:
                      (details) => _handlePlayPauseInteraction(down: details),
                  onTapUp: (_) => _handlePlayPauseInteraction(),
                  onTapCancel: () => _handlePlayPauseInteraction(cancel: true),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 50),
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _isPressed
                              ? Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.1)
                              : Colors.transparent,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Theme.of(context).colorScheme.onInverseSurface,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Song progress bar
        Container(
          height: 4,
          width: double.infinity,
          color: Theme.of(context).colorScheme.inverseSurface,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progress.clamp(0.0, 1.0),
            child: Container(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverImage() {
    String imagePath = _playerController.playingSong.imagePath;

    // Check if it's a network URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => Icon(
              Icons.music_note,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
      );
    }
    // Check if it's an asset path
    else if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => Icon(
              Icons.music_note,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
      );
    }
    // Treat as local file path
    else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => Icon(
              Icons.music_note,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
      );
    }
  }
}
