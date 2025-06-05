import 'package:flutter/material.dart';

import '../../models/song.dart';

class SongOptionsBottomSheet extends StatelessWidget {
  final Song song;
  final ScrollController controller;

  const SongOptionsBottomSheet({
    Key? key,
    required this.song,
    required this.controller,
  }) : super(key: key);

  Widget _buildOptionItem(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label),
      textColor: Colors.white,
      minLeadingWidth: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1F1033),
        borderRadius: BorderRadius.zero,
      ),
      child: ListView(
        controller: controller,
        children: [
          // Song info
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 56,
                height: 56,
                color: Colors.grey[800],
                child: Center(
                  child: Icon(Icons.music_note, color: Colors.grey[600]),
                ),
              ),
            ),
            title: Text(
              song.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              song.artist,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            trailing: const Icon(Icons.share, color: Colors.white),
          ),

          const Divider(color: Colors.white24),

          // Options
          _buildOptionItem(Icons.download, "Tải về"),
          _buildOptionItem(Icons.favorite_border, "Thêm vào thư viện"),
          _buildOptionItem(Icons.playlist_add, "Thêm vào playlist"),
          _buildOptionItem(Icons.shuffle, "Phát bài hát & nội dung tương tự"),
          _buildOptionItem(Icons.playlist_play, "Thêm vào danh sách phát"),
        ],
      ),
    );
  }
}
