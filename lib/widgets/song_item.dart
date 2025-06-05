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
            PlayerController.getInstance().loadSong(song);
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

    if (imagePath.isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.music_note, size: 24, color: Colors.grey),
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
            child: const Icon(Icons.music_note, size: 24, color: Colors.grey),
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
            child: const Icon(Icons.music_note, size: 24, color: Colors.grey),
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
            PlayerController.getInstance().loadSong(song);
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
                    icon: const Icon(Icons.play_circle_outline, size: 28),
                    onPressed: () {
                      PlayerController.getInstance().loadSong(song);
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.play_circle_outline),
          onPressed: () {
            PlayerController.getInstance().loadSong(song);
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
