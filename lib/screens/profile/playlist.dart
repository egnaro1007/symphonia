import 'package:flutter/material.dart';
import 'package:symphonia/models/playlist.dart';
import 'package:symphonia/screens/playlist/playlist_screen.dart';
import 'package:symphonia/services/playlist.dart';

import '../playlist/playlist_creation_screen.dart';

class PlayListComponent extends StatefulWidget {
  final void Function(int, String) onTabSelected;

  const PlayListComponent({super.key, required this.onTabSelected});

  @override
  State<PlayListComponent> createState() => _PlayListComponentState();
}

class _PlayListComponentState extends State<PlayListComponent> {
  late List<PlayList> playlists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final loadedPlaylists = await PlayListOperations.getLocalPlaylists();
    setState(() {
      playlists = loadedPlaylists;
    });
  }

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

          const Divider(),
          ...playlists.map((playlist) {
            return _buildPlaylistTile(
              playlist
            );
          }).toList(),

          const SizedBox(height: 16),
          _buildRecommendedPlaylistHeader(),

          FutureBuilder<List<BriefPlayList>>(
            future: PlayListOperations.getPlaylists(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No playlists available');
              } else {
                return Column(
                  children: snapshot.data!.map((playlist) {
                    return _buildRecommendedPlaylist(
                      playlist.id,
                      playlist.title,
                      playlist.picture,
                      playlist.creator,
                    );
                  }).toList(),
                );
              }
            },
          )
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistCreationScreen(),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistTile(PlayList playlist) {
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
        playlist.title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(playlist.creator),
      onTap: () {
        widget.onTabSelected(6, playlist.id);
      },
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

  Widget _buildRecommendedPlaylist(String id, String title, String picture, String creator) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey[300],
        ),
        // Image network
        child: Image.network(picture, fit: BoxFit.cover),
      ),

      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),

      subtitle: Text(creator),

      trailing: IconButton(
        icon: const Icon(Icons.favorite_border),
        onPressed: () {},
      ),
      onTap: () => {
        widget.onTabSelected(5, id),
      },
    );
  }
}