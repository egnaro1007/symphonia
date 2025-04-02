import 'package:flutter/material.dart';
import '../screens/player/player_screen.dart';

class MiniPlayer extends StatefulWidget {
  final void Function(bool) expandPlayerCallback;

  const MiniPlayer({super.key, required this.expandPlayerCallback});

  @override
  MiniPlayerState createState() => MiniPlayerState();
}

class MiniPlayerState extends State<MiniPlayer> with SingleTickerProviderStateMixin {
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

  bool get isExpanded => _isExpanded;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: _isExpanded ? MediaQuery.of(context).size.height : 80, // Expands to full height
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(_isExpanded ? 0 : 12)),
      ),
      child: GestureDetector(
        onTap: _togglePlayer,
        child: _isExpanded ? PlayerScreen(closePlayer: _togglePlayer) : _buildMiniPlayer(),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return Row(
      children: [
        Container(
          width: 120,
          height: 80,
          color: Colors.red,
          child: Icon(Icons.play_arrow, color: Colors.white, size: 40),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text("Now Playing", style: TextStyle(color: Colors.white)),
          ),
        ),
        Icon(Icons.expand_less, color: Colors.white),
      ],
    );
  }
}
