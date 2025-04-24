import 'package:flutter/material.dart';
import '/controller/player_controller.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:symphonia/models/song.dart';

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

  @override
  void initState() {
    super.initState();

    // Load the song
    // _playerController.loadSongFromUrl("http://192.168.1.111:8000/song.mp3");
    // _playerController.loadSongFromFile(filePath);

    _isPlaying = _playerController.isPlaying();
    _playerController.getDuration().then((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    // Listen to position updates
    _playerController.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
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
        });
      }
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
            child: Column(
              children: [
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _playerController.playingSong.imagePath.isEmpty
                    ? Icon(Icons.music_note, size: 100, color: Colors.white)
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        _playerController.playingSong.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.music_note, size: 100, color: Colors.white),
                      ),
                    ),
                ),
                const SizedBox(height: 10),
                Text(
                  _playerController.playingSong.title,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  _playerController.playingSong.artist,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Slider(
                  value: _totalDuration.inSeconds > 0 ? _currentPosition.inSeconds.toDouble() : 0.0,
                  max: _totalDuration.inSeconds > 0 ? _totalDuration.inSeconds.toDouble() : 1.0,
                  onChanged: (value) {
                    if (_totalDuration.inSeconds > 0) {
                      _playerController.seek(Duration(seconds: value.toInt()));
                    }
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