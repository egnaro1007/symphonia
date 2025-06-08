import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:symphonia/controller/player_controller.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/services/like.dart';
import 'package:symphonia/services/playlist.dart';
import 'package:symphonia/controller/download_controller.dart';
import 'package:symphonia/models/playlist.dart';
import 'package:symphonia/services/playlist_notifier.dart';
import 'dart:io';

class SongItem extends StatelessWidget {
  final Song song;
  final bool showTrailingControls;
  final VoidCallback? onTap;
  final bool isHorizontal;
  final int? index;
  final bool showIndex;
  final VoidCallback? onPlaylistUpdate; // New callback for playlist updates
  final bool isDeleteMode; // New parameter for delete mode
  final String? playlistId; // New parameter for playlist ID when deleting
  final VoidCallback? onSongDeleted; // New callback when song is deleted
  final bool isDragMode; // New parameter for drag mode
  final bool showDeleteIcon; // New parameter to show delete icon
  final VoidCallback? onDeletePressed; // New callback for delete action

  const SongItem({
    super.key,
    required this.song,
    this.showTrailingControls = true,
    this.onTap,
    this.isHorizontal = true,
    this.index,
    this.showIndex = false,
    this.onPlaylistUpdate, // New callback
    this.isDeleteMode = false, // Default to false
    this.playlistId, // Can be null when not needed
    this.onSongDeleted, // Can be null when not needed
    this.isDragMode = false, // Default to false
    this.showDeleteIcon = false, // Default to false
    this.onDeletePressed, // Can be null when not needed
  });

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
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
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
                children:
                    isDeleteMode
                        ? [
                          // In delete mode, show only delete icon
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 28,
                            ),
                            onPressed: () => _handleDeleteSong(context),
                          ),
                        ]
                        : [
                          // Normal mode - show play and options icons
                          IconButton(
                            icon: Icon(
                              song.audioUrl.isNotEmpty
                                  ? Icons.play_circle_outline
                                  : Icons.error_outline,
                              size: 28,
                              color:
                                  song.audioUrl.isNotEmpty
                                      ? null
                                      : Colors.red.shade400,
                            ),
                            onPressed:
                                song.audioUrl.isNotEmpty
                                    ? () {
                                      if (onTap != null) {
                                        onTap!();
                                      } else {
                                        PlayerController.getInstance().loadSong(
                                          song,
                                        );
                                      }
                                    }
                                    : () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
    // In delete mode, show only delete icon
    if (isDeleteMode) {
      return IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () => _handleDeleteSong(context),
      );
    }

    // In drag mode, show drag handle with optional delete icon
    if (isDragMode) {
      if (showDeleteIcon) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              onPressed: onDeletePressed,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            ReorderableDragStartListener(
              index: index ?? 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.drag_handle,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ),
            ),
          ],
        );
      } else {
        return ReorderableDragStartListener(
          index: index ?? 0,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(Icons.drag_handle, color: Colors.grey[600], size: 24),
          ),
        );
      }
    }

    // Normal mode - show play and options icons
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

  Future<void> _handleDeleteSong(BuildContext context) async {
    if (playlistId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xóa bài hát: thiếu thông tin playlist'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      bool success = await PlayListOperations.removeSongFromPlaylist(
        playlistId!,
        song.id.toString(),
      );

      Navigator.pop(context); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa "${song.title}" khỏi playlist'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Trigger callbacks
        if (onSongDeleted != null) {
          onSongDeleted!();
        }
        if (onPlaylistUpdate != null) {
          onPlaylistUpdate!();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xóa bài hát khỏi playlist'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra khi xóa bài hát'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
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
              title: Text(AppLocalizations.of(context)!.addToPlayNext),
              onTap: () async {
                final playerController = PlayerController.getInstance();
                final wasPlaying = playerController.hasSong;

                // Check if this is the currently playing song
                final isCurrentlyPlaying =
                    wasPlaying &&
                    playerController.currentPlaylist.songs.isNotEmpty &&
                    playerController.currentSongIndex <
                        playerController.currentPlaylist.songs.length &&
                    playerController
                            .currentPlaylist
                            .songs[playerController.currentSongIndex]
                            .id ==
                        song.id;

                if (isCurrentlyPlaying) {
                  // Show message that operation was cancelled
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${AppLocalizations.of(context)!.songCurrentlyPlaying}: "${song.title}"',
                      ),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                await playerController.addSongToPlayNext(song);
                Navigator.pop(context);

                // Show appropriate confirmation message
                final message =
                    wasPlaying
                        ? 'Đã thêm "${song.title}" vào phát tiếp'
                        : 'Đang phát: "${song.title}"';

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: Text(AppLocalizations.of(context)!.download),
              onTap: () {
                DownloadController.downloadSong(song);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(isLike ? Icons.favorite : Icons.favorite_border),
              title: Text(
                isLike
                    ? AppLocalizations.of(context)!.removeFromFavorites
                    : AppLocalizations.of(context)!.addToFavorites,
              ),
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
              title: Text(AppLocalizations.of(context)!.addToPlaylist),
              onTap: () async {
                List<PlayList> localPlaylists =
                    await PlayListOperations.getLocalPlaylists();

                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  builder: (_) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Chọn playlist',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const Divider(height: 1),

                        // Playlist list
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: localPlaylists.length,
                            itemBuilder: (context, index) {
                              final playlist = localPlaylists[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.grey[300],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child:
                                        playlist.picture.isNotEmpty
                                            ? Image.network(
                                              playlist.picture,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return const Center(
                                                  child: Icon(
                                                    Icons.music_note,
                                                    color: Colors.grey,
                                                  ),
                                                );
                                              },
                                              loadingBuilder: (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                );
                                              },
                                            )
                                            : const Center(
                                              child: Icon(
                                                Icons.music_note,
                                                color: Colors.grey,
                                              ),
                                            ),
                                  ),
                                ),
                                title: Text(
                                  playlist.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  playlist.creator,
                                  style: TextStyle(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () async {
                                  bool success =
                                      await PlayListOperations.addSongToPlaylist(
                                        playlist.id,
                                        song.id.toString(),
                                      );
                                  Navigator.pop(
                                    context,
                                  ); // Close playlist selection
                                  Navigator.pop(context); // Close song options

                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Đã thêm "${song.title}" vào "${playlist.title}"',
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );

                                    // Trigger playlist refresh if callback is provided
                                    if (onPlaylistUpdate != null) {
                                      onPlaylistUpdate!();
                                    }

                                    // Also notify globally for playlist list refresh
                                    PlaylistUpdateNotifier()
                                        .notifyPlaylistUpdate();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Không thể thêm bài hát vào playlist',
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
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
