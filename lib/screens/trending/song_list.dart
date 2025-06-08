import 'package:flutter/material.dart';
import 'package:symphonia/screens/trending/song_options_bottom_sheet.dart';
import 'package:symphonia/widgets/song_item.dart';

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
    return Container(
      color: Colors.deepPurple.shade500,
      child: Row(
        children: [
          // Rank number container
          SizedBox(
            width: 40,
            height: 72, // Match typical ListTile height
            child: Center(
              child: Text(
                rank.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Song item with custom theme
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                listTileTheme: ListTileTheme.of(context).copyWith(
                  textColor: Colors.white,
                  iconColor: Colors.white60,
                  tileColor: Colors.transparent,
                ),
                textTheme: Theme.of(context).textTheme.copyWith(
                  titleMedium: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  bodyMedium: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
                iconTheme: IconTheme.of(
                  context,
                ).copyWith(color: Colors.white60),
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  onSurface: Colors.white,
                  onSurfaceVariant: Colors.grey.shade400,
                ),
              ),
              child: SongItem(
                song: song,
                showTrailingControls: true,
                isHorizontal: true,
              ),
            ),
          ),
        ],
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
