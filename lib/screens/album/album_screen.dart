import 'package:flutter/material.dart';
import 'package:symphonia/models/album.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/screens/abstract_navigation_screen.dart';
import 'package:symphonia/services/album.dart';
import 'package:symphonia/widgets/song_item.dart';
import 'package:symphonia/controller/player_controller.dart';
import 'dart:io';

class AlbumScreen extends AbstractScreen {
  final String albumID;

  const AlbumScreen({
    super.key,
    required this.albumID,
    required super.onTabSelected,
  });

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();

  @override
  Icon get icon => const Icon(Icons.album);

  @override
  String get title => "Album";
}

class _AlbumScreenState extends State<AlbumScreen> {
  final int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          FutureBuilder<Album>(
            key: ValueKey(_refreshKey),
            future: AlbumOperations.getAlbum(widget.albumID),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không thể tải album',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData) {
                return const Center(child: Text('Không có dữ liệu'));
              } else {
                final album = snapshot.data!;
                return _buildAlbumContent(album);
              }
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          widget.onTabSelected(-1, "");
        },
      ),
    );
  }

  Widget _buildAlbumContent(Album album) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [_buildAlbumHeader(album), _buildSongsList(album)],
        ),
      ),
    );
  }

  Widget _buildAlbumHeader(Album album) {
    return Container(
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
          _buildAlbumCover(album),
          const SizedBox(height: 24),
          _buildAlbumInfo(album),
          const SizedBox(height: 12),
          _buildAlbumStats(album),
          const SizedBox(height: 24),
          _buildActionButtons(album),
        ],
      ),
    );
  }

  Widget _buildAlbumCover(Album album) {
    return Container(
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
        child: _buildAlbumImage(album),
      ),
    );
  }

  Widget _buildAlbumInfo(Album album) {
    return Column(
      children: [
        // Album title
        Text(
          album.title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Artist info
        Text(
          album.artistNames,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAlbumStats(Album album) {
    return FutureBuilder<List<Song>>(
      future: AlbumOperations.getAlbumSongs(album.id.toString()),
      builder: (context, snapshot) {
        String durationText = '';

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          durationText = _getAlbumDurationFromSongs(snapshot.data!);
        } else {
          durationText = '0s';
        }

        List<Widget> statsItems = [
          Text(
            '${album.trackCount} bài hát',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ];

        // Add duration if available
        if (durationText != '0s') {
          statsItems.add(
            Text(
              ' • $durationText',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        // Add release year if available
        if (album.releaseDate != null) {
          statsItems.add(
            Text(
              ' • ${album.releaseDate!.year}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: statsItems,
        );
      },
    );
  }

  String _getAlbumDurationFromSongs(List<Song> songs) {
    int totalSeconds = songs
        .map((song) => song.durationSeconds)
        .fold(0, (prev, duration) => prev + duration);

    if (totalSeconds <= 0) return "0s";

    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;

    if (hours > 0) {
      return "${hours}h ${minutes}m ${seconds}s";
    } else if (minutes > 0) {
      return "${minutes}m ${seconds}s";
    } else {
      return "${seconds}s";
    }
  }

  Widget _buildActionButtons(Album album) {
    return Center(child: _buildPlayButton(album));
  }

  Widget _buildPlayButton(Album album) {
    return ElevatedButton.icon(
      onPressed: () => _handlePlayAlbum(album),
      icon: const Icon(Icons.play_arrow, color: Colors.white),
      label: const Text(
        'PHÁT TẤT CẢ',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }

  Widget _buildSongsList(Album album) {
    return FutureBuilder<List<Song>>(
      future: AlbumOperations.getAlbumSongs(album.id.toString()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Không thể tải danh sách bài hát: ${snapshot.error}',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Album này chưa có bài hát nào',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        } else {
          final songs = snapshot.data!;
          return Container(
            color: Colors.white,
            child: Column(
              children:
                  songs.asMap().entries.map((entry) {
                    int index = entry.key;
                    Song song = entry.value;
                    return SongItem(
                      song: song,
                      showTrailingControls: true,
                      isHorizontal: true,
                      index: index,
                      showIndex: true,
                      onTap: () => _handleSongTap(songs, index),
                    );
                  }).toList(),
            ),
          );
        }
      },
    );
  }

  Widget _buildAlbumImage(Album album) {
    String imagePath = album.coverArt ?? '';

    if (imagePath.isEmpty) {
      return _buildPlaceholderImage();
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return _buildNetworkImage(imagePath);
    } else if (imagePath.startsWith('assets/')) {
      return _buildAssetImage(imagePath);
    } else {
      return _buildFileImage(imagePath);
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.album, size: 80, color: Colors.grey),
    );
  }

  Widget _buildNetworkImage(String imagePath) {
    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
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

  Widget _buildAssetImage(String imagePath) {
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
    );
  }

  Widget _buildFileImage(String imagePath) {
    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
    );
  }

  // Event handlers
  void _handlePlayAlbum(Album album) async {
    try {
      // Load full song details first
      final songs = await AlbumOperations.getAlbumSongs(album.id.toString());

      if (songs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Album không có bài hát nào'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Use PlayerController instead of direct AudioHandler
      PlayerController.getInstance().loadSongs(songs);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đang phát album "${album.title}"'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể phát album: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleSongTap(List<Song> songs, int index) async {
    try {
      // Use PlayerController to load the entire album playlist and start at selected index
      PlayerController.getInstance().loadSongs(songs, index);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đang phát "${songs[index].title}"'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể phát bài hát: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
