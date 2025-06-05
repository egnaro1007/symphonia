import 'package:flutter/material.dart';
import 'package:symphonia/controller/player_controller.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/services/like.dart';
import 'package:symphonia/services/playlist.dart';
import 'package:symphonia/controller/download_controller.dart';
import 'package:symphonia/models/playlist.dart';
import 'dart:io';

class SongItem extends StatelessWidget {
  final Song song;
  final bool showTrailingControls;
  final VoidCallback? onTap;
  final bool isHorizontal;
  final int? index;
  final bool showIndex;

  const SongItem({
    Key? key,
    required this.song,
    this.showTrailingControls = true,
    this.onTap,
    this.isHorizontal = true,
    this.index,
    this.showIndex = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isHorizontal
        ? _buildHorizontalLayout(context)
        : _buildVerticalLayout(context);
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    return ListTile(
      onTap:
          onTap ??
          () {
            if (song.audioUrl.isNotEmpty) {
              PlayerController.getInstance().loadSong(song);
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading:
          showIndex && index != null
              ? _buildIndexedLeading(context)
              : _buildImageLeading(),
      title: Text(
        song.title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: showTrailingControls ? _buildTrailingControls(context) : null,
    );
  }

  Widget _buildIndexedLeading(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: Center(
        child: Text(
          '${index! + 1}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildImageLeading() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildSongImage(),
      ),
    );
  }

  Widget _buildSongImage() {
    String imagePath = song.imagePath;
    print("SongItem: Building image for '${song.title}'");
    print("SongItem: Image path = '$imagePath'");

    if (imagePath.isEmpty) {
      print("SongItem: Image path is empty, showing placeholder icon");
      return Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.music_note, size: 24, color: Colors.grey),
      );
    }

    // Check if it's a network URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      print("SongItem: Loading network image: $imagePath");
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            print("SongItem: Network image loaded successfully");
            return child;
          }
          print(
            "SongItem: Loading network image... ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}",
          );
          return Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print("SongItem: Error loading network image: $error");
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.music_note, size: 24, color: Colors.grey),
          );
        },
      );
    }
    // Check if it's an asset path
    else if (imagePath.startsWith('assets/')) {
      print("SongItem: Loading asset image: $imagePath");
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("SongItem: Error loading asset image: $error");
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.music_note, size: 24, color: Colors.grey),
          );
        },
      );
    }
    // Treat as local file path
    else {
      print("SongItem: Loading local file image: $imagePath");
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("SongItem: Error loading local file image: $error");
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.music_note, size: 24, color: Colors.grey),
          );
        },
      );
    }
  }

  Widget _buildVerticalLayout(BuildContext context) {
    return GestureDetector(
      onTap:
          onTap ??
          () {
            if (song.audioUrl.isNotEmpty) {
              PlayerController.getInstance().loadSong(song);
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
        width: 160,
        margin: const EdgeInsets.only(right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              width: 160,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildSongImage(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              song.artist,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (showTrailingControls)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      song.audioUrl.isNotEmpty
                          ? Icons.play_circle_outline
                          : Icons.error_outline,
                      size: 28,
                      color:
                          song.audioUrl.isNotEmpty ? null : Colors.red.shade400,
                    ),
                    onPressed:
                        song.audioUrl.isNotEmpty
                            ? () {
                              if (onTap != null) {
                                onTap!();
                              } else {
                                PlayerController.getInstance().loadSong(song);
                              }
                            }
                            : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Bài hát "${song.title}" không có file âm thanh để phát',
                                  ),
                                  backgroundColor: Colors.red.shade400,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showSongOptions(context);
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailingControls(BuildContext context) {
    bool canPlay = song.audioUrl.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show different icon based on playability
        IconButton(
          icon: Icon(
            canPlay ? Icons.play_circle_outline : Icons.error_outline,
            color: canPlay ? null : Colors.red.shade400,
          ),
          onPressed:
              canPlay
                  ? () {
                    if (onTap != null) {
                      onTap!();
                    } else {
                      PlayerController.getInstance().loadSong(song);
                    }
                  }
                  : () {
                    // Show message when song cannot be played
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Bài hát "${song.title}" không có file âm thanh để phát',
                        ),
                        backgroundColor: Colors.red.shade400,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            _showSongOptions(context);
          },
        ),
      ],
    );
  }

  Future<void> _showSongOptions(BuildContext context) async {
    bool isLike = await LikeOperations.getLikeStatus(song);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.queue_play_next),
              title: const Text('Thêm vào danh dách phát tiếp'),
              onTap: () {
                PlayerController.getInstance().loadSong(song, false);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Tải về'),
              onTap: () {
                DownloadController.downloadSong(song);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(isLike ? Icons.favorite : Icons.favorite_border),
              title: Text(isLike ? 'Bỏ khỏi yêu thích' : 'Thêm vào yêu thích'),
              onTap: () async {
                if (isLike) {
                  if (await LikeOperations.unlike(song)) {
                    isLike = false;
                  }
                } else {
                  if (await LikeOperations.like(song)) {
                    isLike = true;
                  }
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Thêm vào playlist'),
              onTap: () async {
                List<PlayList> localPlaylists =
                    await PlayListOperations.getLocalPlaylists();

                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  builder: (_) {
                    return ListView.builder(
                      itemCount: localPlaylists.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(localPlaylists[index].title),
                          onTap: () {
                            PlayListOperations.addSongToPlaylist(
                              localPlaylists[index].id,
                              song.id.toString(),
                            );
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
