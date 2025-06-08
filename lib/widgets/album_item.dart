import 'package:flutter/material.dart';
import 'package:symphonia/models/album.dart';
import 'package:symphonia/constants/screen_index.dart';
import 'package:symphonia/controller/player_controller.dart';
import 'package:symphonia/services/album.dart';
import 'dart:io';

class AlbumItem extends StatelessWidget {
  final Album album;
  final bool showTrailingControls;
  final VoidCallback? onTap;
  final bool isHorizontal;
  final int? index;
  final bool showIndex;
  final VoidCallback? onAlbumUpdate;
  final void Function(int, String)? onTabSelected;

  const AlbumItem({
    super.key,
    required this.album,
    this.showTrailingControls = true,
    this.onTap,
    this.isHorizontal = true,
    this.index,
    this.showIndex = false,
    this.onAlbumUpdate,
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return isHorizontal
        ? _buildHorizontalLayout(context)
        : _buildVerticalLayout(context);
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    return ListTile(
      onTap: onTap ?? _handleDefaultTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading:
          showIndex && index != null
              ? _buildIndexedLeading(context)
              : _buildImageLeading(),
      title: Text(
        album.title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        album.releaseDate != null
            ? '${album.artistNames} • ${album.releaseDate!.year}'
            : album.artistNames,
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
        child: _buildAlbumImage(),
      ),
    );
  }

  Widget _buildAlbumImage() {
    String imagePath = album.coverArt ?? '';

    if (imagePath.isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.album, size: 24, color: Colors.grey),
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
            child: const Icon(Icons.album, size: 24, color: Colors.grey),
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
            child: const Icon(Icons.album, size: 24, color: Colors.grey),
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
            child: const Icon(Icons.album, size: 24, color: Colors.grey),
          );
        },
      );
    }
  }

  Widget _buildVerticalLayout(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? _handleDefaultTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Album cover image
            Container(
              height: 160,
              width: 160,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildAlbumImage(),
              ),
            ),
            const SizedBox(height: 5),

            // Text content with fixed height to prevent overflow
            SizedBox(
              height: 50, // Fixed height for 3 lines of text
              child: Padding(
                padding: const EdgeInsets.only(left: 3.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Line 1: Album title
                    Text(
                      album.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Line 2: Artist name and Release year
                    Text(
                      album.releaseDate != null
                          ? '${album.artistNames} • ${album.releaseDate!.year}'
                          : album.artistNames,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailingControls(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.play_circle_outline),
      onPressed: () => _handlePlayAlbum(context),
    );
  }

  void _handlePlayAlbum(BuildContext context) async {
    try {
      // Load album songs and play from the beginning
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

      // Use PlayerController to load and play the album
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

  void _handleDefaultTap() {
    if (onTabSelected != null) {
      // Navigate to album screen
      onTabSelected!(ScreenIndex.album.value, album.id.toString());
    }
  }
}
