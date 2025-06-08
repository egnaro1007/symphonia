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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Check if albumID is valid before making API call
          widget.albumID.isEmpty || widget.albumID == "0"
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.album,
                      size: 64,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Không có album được chọn',
                      style: TextStyle(
                        fontSize: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
              : FutureBuilder<Album>(
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
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Không thể tải album',
                            style: TextStyle(
                              fontSize: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant.withOpacity(
                                0.7,
                              ),
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
                    return _buildAlbumContent(album, context);
                  }
                },
              ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
        onPressed: () {
          widget.onTabSelected(-1, "");
        },
      ),
    );
  }

  Widget _buildAlbumContent(Album album, BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildAlbumHeader(album, context),
            _buildSongsList(album, context),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumHeader(Album album, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surfaceContainerHighest.withOpacity(0.3),
            colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          _buildAlbumCover(album),
          const SizedBox(height: 24),
          _buildAlbumInfo(album, context),
          const SizedBox(height: 12),
          _buildAlbumStats(album, context),
          const SizedBox(height: 24),
          _buildActionButtons(album, context),
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

  Widget _buildAlbumInfo(Album album, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Album title
        Text(
          album.title,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Artist info
        Text(
          album.artistNames,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAlbumStats(Album album, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
              color: colorScheme.onSurfaceVariant,
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
                color: colorScheme.onSurfaceVariant,
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
                color: colorScheme.onSurfaceVariant,
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

  Widget _buildActionButtons(Album album, BuildContext context) {
    return Center(child: _buildPlayButton(album, context));
  }

  Widget _buildPlayButton(Album album, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton.icon(
      onPressed: () => _handlePlayAlbum(album),
      icon: Icon(Icons.play_arrow, color: colorScheme.onPrimary),
      label: Text(
        'PHÁT TẤT CẢ',
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }

  Widget _buildSongsList(Album album, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<Song>>(
      future: AlbumOperations.getAlbumSongs(album.id.toString()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.all(20),
            child: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Không thể tải danh sách bài hát: ${snapshot.error}',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Album này chưa có bài hát nào',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          );
        } else {
          final songs = snapshot.data!;
          return Container(
            color: colorScheme.surface,
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
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          color: colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.album,
            size: 80,
            color: colorScheme.onSurfaceVariant,
          ),
        );
      },
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
        return Builder(
          builder: (context) {
            final colorScheme = Theme.of(context).colorScheme;
            return Container(
              color: colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
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
          SnackBar(
            content: const Text('Album không có bài hát nào'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        return;
      }

      // Check if any song has a valid audio URL
      final playableSongs =
          songs.where((song) => song.getAudioUrl().isNotEmpty).toList();

      if (playableSongs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Album này không có bài hát nào có thể phát'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        return;
      }

      // Find the index of the first playable song in the original list
      int firstPlayableIndex = songs.indexWhere(
        (song) => song.getAudioUrl().isNotEmpty,
      );

      // Use PlayerController to load songs and start from first playable song
      PlayerController.getInstance().loadSongs(songs, firstPlayableIndex);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đang phát album "${album.title}"'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể phát album: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _handleSongTap(List<Song> songs, int index) async {
    try {
      final selectedSong = songs[index];

      // Check if the selected song has a valid audio URL
      if (selectedSong.getAudioUrl().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bài hát "${selectedSong.title}" không có file âm thanh để phát',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      // Use PlayerController to load the entire album playlist and start at selected index
      PlayerController.getInstance().loadSongs(songs, index);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đang phát "${songs[index].title}"'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể phát bài hát: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
