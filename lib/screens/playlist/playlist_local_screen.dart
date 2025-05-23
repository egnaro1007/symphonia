import 'package:flutter/material.dart';
import 'package:symphonia/models/playlist.dart';
import 'package:symphonia/screens/abstract_navigation_screen.dart';
import 'package:symphonia/screens/navigation_bar_screen.dart';
import 'package:symphonia/services/playlist.dart';

class PlaylistLocalScreen extends AbstractScreen {
  final String playlistID;
  const PlaylistLocalScreen({
    super.key,
    required this.playlistID,
    required super.onTabSelected,
  });

  @override
  State<PlaylistLocalScreen> createState() => _PlaylistLocalScreenState();

  @override
  // TODO: implement icon
  Icon get icon => const Icon(Icons.playlist_play);

  @override
  // TODO: implement title
  String get title => "Playlist";
}

class _PlaylistLocalScreenState extends State<PlaylistLocalScreen> {
  @override
  Widget build(BuildContext context) {
    // Print the playlist ID for debugging
    print("Playlist ID: ${widget.playlistID}");

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Navigate back to the previous screen
            widget.onTabSelected(3, "symchart");
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
          children: [
            FutureBuilder(
                future: PlayListOperations.getLocalPlaylist(widget.playlistID),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData) {
                    return const Center(child: Text('No data available'));
                  } else {
                    final playlist = snapshot.data!;
                    return _buildPlaylistBody(playlist);
                  }
                }
            )
          ]
      ),
      // bottomNavigationBar: NavigationBarScreen(hasBody: false,),
    );
  }

  Widget _buildPlaylistBody(PlayList playlist) {
    return // Main content - Scrollable
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Album header section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Album title
                    Text(
                      playlist.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Platform
                    Text(
                      playlist.creator,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Number of songs and duration
                    Text(
                      '${playlist.songs.length} bài hát • ${playlist.duration ~/ 3600} giờ ${(playlist.duration % 3600) ~/ 60} phút',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Download button
                        Column(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Icon(Icons.download_outlined),
                            ),
                            const SizedBox(height: 4),
                            const Text('Tải xuống', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(width: 24),
                        // Play button
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'PHÁT NGẪU NHIÊN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Add button
                        Column(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Icon(Icons.add),
                            ),
                            const SizedBox(height: 4),
                            const Text('Thêm vào', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Playlist description
                    Text(
                      playlist.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // Song list
              Column(
                children: playlist.songs.map((song) {
                  return _buildSongItem(
                    song.title,
                    song.artist,
                    song.imagePath,
                  );
                }).toList(),
              )
            ],
          ),
        ),
      );
  }

  Widget _buildSongItem(String title, String artists, String imageUrl) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        artists,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: const Icon(Icons.more_vert),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}