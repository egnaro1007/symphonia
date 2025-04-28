import 'package:flutter/material.dart';
import 'package:symphonia/screens/player/player_screen.dart';
import 'package:symphonia/screens/trending/song_options_bottom_sheet.dart';
import 'package:symphonia/screens/trending/song_player_screen.dart';

import '../../models/song.dart';

class SongList extends StatelessWidget {
  List<Song> songs;
  SongList({Key? key, required this.songs}) : super(key: key);

  void _showSongDetail(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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

  Widget buildSongItem(BuildContext context, {
    required Song song,
    required int rank,
    bool isSelected = false
  }) {
    return
      InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SongPlayerScreen(song: song),
              )
          );
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
                          child: const Icon(Icons.music_note, color: Colors.white),
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
                )
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
        )
    );
  }
}