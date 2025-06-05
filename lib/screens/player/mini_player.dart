import 'package:flutter/material.dart';
import 'player_screen.dart';
import '/controller/player_controller.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';

class MiniPlayer extends StatefulWidget {
  final void Function(bool) expandPlayerCallback;

  const MiniPlayer({super.key, required this.expandPlayerCallback});

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
    _songChangeSubscription = _playerController.onSongChange.listen((_) {
      if (mounted) {
        setState(() {
          _progress = 0.0;
          _currentPosition = Duration.zero;
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
      if (mounted && _playerController.hasSong) {
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

    // Get initial duration
    _playerController.getDuration().then((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
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
    if (!_playerController.hasSong) return;

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
                child: PlayerScreen(closePlayer: _togglePlayer),
              )
              : GestureDetector(
                onTap: _playerController.hasSong ? _togglePlayer : null,
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
          decoration: BoxDecoration(color: Colors.grey[900]),
          child: Row(
            children: [
              // Ảnh cover
              Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(right: 15),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child:
                    _playerController.hasSong &&
                            _playerController.playingSong.imagePath.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: _buildCoverImage(),
                        )
                        : Icon(Icons.music_note, color: Colors.white),
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
                        _playerController.hasSong
                            ? _playerController.playingSong.title
                            : "Không có gì đang phát",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_playerController.hasSong &&
                          _playerController.playingSong.artist.isNotEmpty)
                        Text(
                          _playerController.playingSong.artist,
                          style: TextStyle(
                            color: Colors.grey[400],
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
                opacity: _playerController.hasSong ? 1.0 : 0.5,
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
                      color: _isPressed ? Colors.white24 : Colors.transparent,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
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
          color: Colors.grey[900],
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progress.clamp(0.0, 1.0),
            child: Container(color: Colors.red),
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
            (context, error, stackTrace) =>
                Icon(Icons.music_note, color: Colors.white),
      );
    }
    // Check if it's an asset path
    else if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) =>
                Icon(Icons.music_note, color: Colors.white),
      );
    }
    // Treat as local file path
    else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) =>
                Icon(Icons.music_note, color: Colors.white),
      );
    }
  }
}
