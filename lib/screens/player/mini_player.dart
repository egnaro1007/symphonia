import 'package:flutter/material.dart';
import 'player_screen.dart';
import '/controller/player_controller.dart';

class MiniPlayer extends StatefulWidget {
  final void Function(bool) expandPlayerCallback;

  const MiniPlayer({super.key, required this.expandPlayerCallback});

  @override
  MiniPlayerState createState() => MiniPlayerState();
}

class MiniPlayerState extends State<MiniPlayer> with SingleTickerProviderStateMixin {
  final PlayerController _playerController = PlayerController.getInstance();
  late AnimationController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _togglePlayer() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _controller.forward() : _controller.reverse();
    });
    widget.expandPlayerCallback(_isExpanded);
  }

  bool _isPressed = false;

  void _handlePlayPauseInteraction({TapDownDetails? down, bool cancel = false}) {
    setState(() {
      if (down != null) {
        _isPressed = true;
      } else if (!cancel) {
        _isPressed = false;
        _playerController.isPlaying() ? _playerController.pause() : _playerController.play();
      } else {
        _isPressed = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: _isExpanded ? MediaQuery.of(context).size.height : 80, // Expands to full height
      width: MediaQuery.of(context).size.width,
      child: GestureDetector(
        onTap: _togglePlayer,
        child: _isExpanded ? PlayerScreen(closePlayer: _togglePlayer) : _buildMiniPlayer(),
      ),
    );
  }


  Widget _buildMiniPlayer() {
    return Container(
      height: 80,
      padding: const EdgeInsets.only(left: 15, right: 15), // Tăng padding bên trái
      decoration: BoxDecoration(
        color: const Color(0xFF202020), // Màu nền nhạt hơn một chút
      ),
      child: Row(
        children: [
          // Ảnh cover vuông góc
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.only(right: 15), // Tăng khoảng cách giữa ảnh và text
            color: Colors.black,
            child: Icon(Icons.music_note, color: Colors.white),
          ),

          // Tiêu đề "Không có gì đang phát"
          Expanded(
            child: Text(
              "Không có gì đang phát",
              style: TextStyle(color: Colors.white, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          GestureDetector(
            onTapDown: (details) => _handlePlayPauseInteraction(down: details),
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
                _playerController.isPlaying() ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
            ),
          )

        ],
      ),
    );
  }
}
