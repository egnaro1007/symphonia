import 'package:flutter/material.dart';
import 'package:symphonia/models/playlist.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/screens/abstract_navigation_screen.dart';
import 'package:symphonia/services/playlist.dart';
import 'package:symphonia/widgets/song_item.dart';
import 'package:symphonia/controller/player_controller.dart';
import 'dart:io';

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
            },
          ),
        ],
      ),
      // bottomNavigationBar: NavigationBarScreen(hasBody: false,),
    );
  }

  Widget _buildPlaylistBody(PlayList playlist) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Modern playlist header section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey.shade100, Colors.white],
                ),
              ),
              child: Column(
                children: [
                  // Large album cover image
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildPlaylistImage(playlist),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Playlist title
                  Text(
                    playlist.title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Creator info with avatar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.deepPurple.shade300,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        playlist.creator,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stats
                  Text(
                    '${playlist.songsCount} bài hát • ${playlist.formattedDuration} • Riêng tư',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Add playable songs indicator
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      int playableSongs =
                          playlist.songs
                              .where((song) => song.audioUrl.isNotEmpty)
                              .length;
                      if (playableSongs < playlist.songsCount) {
                        return Text(
                          '$playableSongs/${playlist.songsCount} bài có thể phát',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 24),

                  // Action buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Download button
                      _buildActionButton(
                        icon: Icons.download_outlined,
                        label: '',
                        onTap: () {},
                      ),

                      // Edit button
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        label: '',
                        onTap: () {},
                      ),

                      // Play button (large)
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.deepPurple,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () {
                            // Play playlist from the beginning
                            if (playlist.songs.isNotEmpty) {
                              // Find first playable song
                              int firstPlayableIndex = playlist.songs
                                  .indexWhere(
                                    (song) => song.audioUrl.isNotEmpty,
                                  );
                              if (firstPlayableIndex != -1) {
                                PlayerController.getInstance().loadPlaylist(
                                  playlist,
                                  firstPlayableIndex,
                                );
                              } else {
                                // No playable songs
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Playlist này không có bài hát nào có thể phát',
                                    ),
                                    backgroundColor: Colors.orange,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),

                      // Add songs button
                      _buildActionButton(
                        icon: Icons.add,
                        label: '',
                        onTap: () {},
                      ),

                      // More options button
                      _buildActionButton(
                        icon: Icons.more_vert,
                        label: '',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Song list section
            Container(
              color: Colors.white,
              child: Column(
                children:
                    playlist.songs.asMap().entries.map((entry) {
                      int index = entry.key;
                      Song song = entry.value;
                      return SongItem(
                        song: song,
                        showTrailingControls: true,
                        isHorizontal: true,
                        index: index,
                        showIndex: true,
                        onTap: () {
                          // Load playlist starting from the selected song
                          PlayerController.getInstance().loadPlaylist(
                            playlist,
                            index,
                          );
                        },
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
        ),
        child: Icon(icon, color: Colors.black87, size: 24),
      ),
    );
  }

  Widget _buildPlaylistImage(PlayList playlist) {
    String imagePath = '';

    // Priority: playlist cover image > first song's image > placeholder
    if (playlist.picture.isNotEmpty) {
      imagePath = playlist.picture;
    } else if (playlist.songs.isNotEmpty) {
      imagePath = playlist.songs[0].imagePath;
    }

    if (imagePath.isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.music_note, size: 80, color: Colors.grey),
      );
    }

    // Check if it's a network URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.music_note, size: 80, color: Colors.grey),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            color: Colors.grey.shade300,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      );
    }
    // Check if it's an asset path
    else if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.music_note, size: 80, color: Colors.grey),
          );
        },
      );
    }
    // Treat as local file path
    else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.music_note, size: 80, color: Colors.grey),
          );
        },
      );
    }
  }
}
