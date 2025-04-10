import 'package:flutter/material.dart';
import '/controller/player_controller.dart';
import 'package:audioplayers/audioplayers.dart';

class PlayerScreen extends StatefulWidget {
  final VoidCallback closePlayer;

  const PlayerScreen({super.key, required this.closePlayer});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final PlayerController _playerController = PlayerController.getInstance();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Load the song
    _playerController.loadSongFromUrl("http://192.168.1.111:8000/song.mp3");
    // _playerController.loadSongFromFile(filePath);

    // Listen to position updates
    _playerController.onPositionChanged.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });

    // Listen to state changes
    _playerController.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    // Listen to total duration
    _playerController.onDurationChanged.listen((duration) {
      setState(() {
        _totalDuration = duration;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: Icon(Icons.expand_more, color: Colors.white),
              onPressed: widget.closePlayer,
            ),
            title: Text("Player", style: TextStyle(color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.music_note, size: 100, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Slider(
                  value: _currentPosition.inSeconds.toDouble(),
                  max: _totalDuration.inSeconds.toDouble(),
                  onChanged: (value) {
                    _playerController.seek(Duration(seconds: value.toInt()));
                  },
                  activeColor: Colors.white,
                  inactiveColor: Colors.grey,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      _formatDuration(_totalDuration),
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Handle previous
                      },
                      icon: Icon(Icons.skip_previous, size: 50, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_isPlaying) {
                          _playerController.pause();
                        } else {
                          _playerController.play();
                        }
                      },
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
                        size: 70,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Handle next
                      },
                      icon: Icon(Icons.skip_next, size: 50, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}