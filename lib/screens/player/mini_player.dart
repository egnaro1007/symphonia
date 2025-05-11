import 'package:flutter/material.dart';
import 'player_screen.dart';
import '/controller/player_controller.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

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
  StreamSubscription? _songChangeSubscription;
  StreamSubscription? _playerStateSubscription;

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
        setState(() {});
      }
    });

    // Listen for player state changes
    _playerStateSubscription = _playerController.onPlayerStateChanged.listen((
      state,
    ) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Initialize playing state
    _isPlaying = _playerController.isPlaying();
  }

  @override
  void dispose() {
    _controller.dispose();
    _songChangeSubscription?.cancel();
    _playerStateSubscription?.cancel();
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
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height:
          _isExpanded
              ? MediaQuery.of(context).size.height
              : 80, // Expands to full height
      width: MediaQuery.of(context).size.width,
      child: GestureDetector(
        onTap: _playerController.hasSong ? _togglePlayer : null,
        child:
            _isExpanded
                ? PlayerScreen(closePlayer: _togglePlayer)
                : _buildMiniPlayer(),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return Container(
      height: 80,
      padding: const EdgeInsets.only(left: 15, right: 15),
      decoration: BoxDecoration(color: const Color(0xFF202020)),
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
                    ? Image.network(
                      _playerController.playingSong.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              Icon(Icons.music_note, color: Colors.white),
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
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_playerController.hasSong &&
                      _playerController.playingSong.artist.isNotEmpty)
                    Text(
                      _playerController.playingSong.artist,
                      style: TextStyle(color: Colors.grey[400], fontSize: 17),
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
    );
  }
}
