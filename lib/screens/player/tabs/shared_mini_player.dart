import 'package:flutter/material.dart';
import '../../../controller/player_controller.dart';
import 'dart:io';

class SharedMiniPlayer extends StatefulWidget {
  final VoidCallback onTap;

  const SharedMiniPlayer({super.key, required this.onTap});

  @override
  State<SharedMiniPlayer> createState() => _SharedMiniPlayerState();
}

class _SharedMiniPlayerState extends State<SharedMiniPlayer> {
  final PlayerController _playerController = PlayerController.getInstance();
  bool _isPlaying = false;
  bool _hasSong = false;

  @override
  void initState() {
    super.initState();
    _isPlaying = _playerController.isPlaying();
    _hasSong = _playerController.hasSong;

    // Listen for player state changes
    _playerController.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    // Listen for song changes
    _playerController.onSongChange.listen((song) {
      if (mounted) {
        setState(() {
          _hasSong = _playerController.hasSong;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 80,
        padding: const EdgeInsets.only(left: 15, right: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.inverseSurface,
        ),
        child: Row(
          children: [
            // Album cover
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child:
                  _hasSong && _playerController.playingSong.imagePath.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: _buildCoverImage(),
                      )
                      : Icon(
                        Icons.music_note,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
            ),

            // Title and artist
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
            IconButton(
              onPressed: () {
                if (_isPlaying) {
                  _playerController.pause();
                } else {
                  _playerController.play();
                }
              },
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Theme.of(context).colorScheme.onInverseSurface,
                size: 30,
              ),
            ),
          ],
        ),
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
