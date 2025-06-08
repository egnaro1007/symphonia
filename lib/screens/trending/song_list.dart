import 'package:flutter/material.dart';
import 'package:symphonia/screens/trending/song_options_bottom_sheet.dart';
import 'package:symphonia/screens/trending/song_player_screen.dart';
import 'package:symphonia/controller/player_controller.dart';

import '../../models/song.dart';

class SongList extends StatelessWidget {
  List<Song> songs;
  SongList({super.key, required this.songs});

  void _showSongDetail(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Square corners
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.2,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return SongOptionsBottomSheet(
              song: song,
              controller: scrollController,
            );
          },
        );
      },
    );
  }

  Widget buildSongItem(
    BuildContext context, {
    required Song song,
    required int rank,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: () {
        // Check if song has valid audio URL before playing
        if (song.getAudioUrl().isNotEmpty) {
          PlayerController.getInstance().loadSong(song);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đang phát "${song.title}"'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Bài hát "${song.title}" không có file âm thanh để phát',
              ),
              backgroundColor: Colors.red.shade400,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        color: isSelected ? Colors.purple : Colors.deepPurple.shade500,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  rank.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Image.network(
                    song.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade800,
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  _showSongDetail(context, song);
                },
                icon: const Icon(Icons.more_vert, color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          for (var i = 0; i < songs.length; i++)
            buildSongItem(
              context,
              rank: i + 1,
              song: songs[i],
              isSelected: i == 0,
            ),
        ],
      ),
    );
  }
}
