import 'package:flutter/material.dart';
import 'package:symphonia/models/playlist.dart';
import 'package:symphonia/services/playlist.dart';
import 'package:symphonia/services/user_info_manager.dart';
import 'dart:io';

class PlaylistItem extends StatelessWidget {
  final PlayList playlist;
  final bool showTrailingControls;
  final VoidCallback? onTap;
  final bool isHorizontal;
  final int? index;
  final bool showIndex;
  final VoidCallback? onPlaylistUpdate;
  final bool isDeleteMode;
  final VoidCallback? onPlaylistDeleted;

  const PlaylistItem({
    super.key,
    required this.playlist,
    this.showTrailingControls = true,
    this.onTap,
    this.isHorizontal = true,
    this.index,
    this.showIndex = false,
    this.onPlaylistUpdate,
    this.isDeleteMode = false,
    this.onPlaylistDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return isHorizontal
        ? _buildHorizontalLayout(context)
        : _buildVerticalLayout(context);
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading:
          showIndex && index != null
              ? _buildIndexedLeading(context)
              : _buildImageLeading(),
      title: Text(
        playlist.title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        playlist.creator,
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
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
        child: _buildPlaylistImage(),
      ),
    );
  }

  Widget _buildPlaylistImage() {
    String imagePath = playlist.picture;

    if (imagePath.isEmpty) {
      return Builder(
        builder:
            (context) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.queue_music,
                size: 24,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
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
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.queue_music,
              size: 24,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.queue_music,
              size: 24,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.queue_music,
              size: 24,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        },
      );
    }
  }

  Widget _buildVerticalLayout(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                child: _buildPlaylistImage(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              playlist.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              playlist.creator,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (showTrailingControls)
              Builder(
                builder: (context) {
                  // Check if current user is the owner of the playlist
                  bool isOwner = playlist.ownerId == UserInfoManager.userId;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:
                        isDeleteMode
                            ? [
                              // In delete mode, show only delete icon if user is the owner
                              if (isOwner)
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Theme.of(context).colorScheme.error,
                                    size: 28,
                                  ),
                                  onPressed:
                                      () => _handleDeletePlaylist(context),
                                ),
                            ]
                            : [
                              // Normal mode - show play and options icons
                              IconButton(
                                icon: const Icon(
                                  Icons.play_circle_outline,
                                  size: 28,
                                ),
                                onPressed: () {
                                  if (onTap != null) {
                                    onTap!();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () {
                                  _showPlaylistOptions(context);
                                },
                              ),
                            ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailingControls(BuildContext context) {
    // Check if current user is the owner of the playlist
    bool isOwner = playlist.ownerId == UserInfoManager.userId;

    // In delete mode, show only delete icon if user is the owner
    if (isDeleteMode) {
      if (isOwner) {
        return IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => _handleDeletePlaylist(context),
        );
      } else {
        return const SizedBox.shrink(); // Hide delete button for non-owners
      }
    }

    // Normal mode - show play and options icons
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play button
        IconButton(
          icon: const Icon(Icons.play_circle_outline),
          onPressed: () {
            if (onTap != null) {
              onTap!();
            }
          },
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            _showPlaylistOptions(context);
          },
        ),
      ],
    );
  }

  Future<void> _handleDeletePlaylist(BuildContext context) async {
    // Show confirmation dialog
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa playlist'),
          content: Text(
            'Bạn có chắc chắn muốn xóa playlist "${playlist.title}"? Hành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      bool success = await PlayListOperations.deletePlaylist(playlist.id);

      Navigator.pop(context); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa playlist "${playlist.title}"'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );

        // Trigger callbacks
        if (onPlaylistDeleted != null) {
          onPlaylistDeleted!();
        }
        if (onPlaylistUpdate != null) {
          onPlaylistUpdate!();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể xóa playlist'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Có lỗi xảy ra khi xóa playlist'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showPlaylistOptions(BuildContext context) async {
    // Check if current user is the owner of the playlist
    bool isOwner = playlist.ownerId == UserInfoManager.userId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Phát playlist'),
              onTap: () {
                Navigator.pop(context);
                if (onTap != null) {
                  onTap!();
                }
              },
            ),
            // Only show delete option if user is the owner
            if (isOwner)
              Builder(
                builder:
                    (context) => ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        'Xóa playlist',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _handleDeletePlaylist(context);
                      },
                    ),
              ),
          ],
        );
      },
    );
  }
}
