import 'package:flutter/material.dart';

class PlayListComponent extends StatefulWidget {
  const PlayListComponent({super.key});

  @override
  State<PlayListComponent> createState() => _PlayListComponentState();
}

class _PlayListComponentState extends State<PlayListComponent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlaylistHeader(),

          const Divider(),
          _buildCreatePlaylistTile(),

          _buildPlaylistTile('My playlist', 'Thanh', 'assets/album1.jpg'),
          _buildPlaylistTile('download', 'Thanh', 'assets/album2.jpg'),

          const SizedBox(height: 16),
          _buildRecommendedPlaylistHeader(),

          _buildRecommendedPlaylist('Flow Này Mượt Phết', 'Zing MP3'),
          _buildRecommendedPlaylist('Lofi Hits', 'Zing MP3'),
          _buildRecommendedPlaylist('Nhạc Chill Hay Nhất', 'Zing MP3'),
          _buildRecommendedPlaylist('Lofi Một Chút Thôi', 'Zing MP3'),
          _buildRecommendedPlaylist('Nhẹ Nhàng Cùng V-Pop', 'Zing MP3'),
        ],
      ),
    );
  }

  Widget _buildPlaylistHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Playlist',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCreatePlaylistTile() {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.add, color: Colors.grey),
      ),
      title: const Text(
        'Tạo playlist',
        style: TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {},
    );
  }

  Widget _buildPlaylistTile(String title, String creator, String image) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey[300],
        ),
        // Replace with actual image
        child: const Center(child: Icon(Icons.music_note)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(creator),
      onTap: () {},
    );
  }

  Widget _buildRecommendedPlaylistHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Playlist gợi ý',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Đang được nghe nhiều',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedPlaylist(String title, String source) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey[300],
        ),
        // Replace with actual image
        child: const Center(child: Icon(Icons.music_note)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(source),
      trailing: IconButton(
        icon: const Icon(Icons.favorite_border),
        onPressed: () {},
      ),
      onTap: () {},
    );
  }
}