import 'package:flutter/material.dart';
import 'package:symphonia/models/artist.dart';
import 'package:symphonia/constants/screen_index.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

class ArtistItem extends StatelessWidget {
  final Artist artist;
  final bool showTrailingControls;
  final VoidCallback? onTap;
  final bool isHorizontal;
  final int? index;
  final bool showIndex;
  final VoidCallback? onArtistUpdate;
  final void Function(int, String)? onTabSelected;

  const ArtistItem({
    super.key,
    required this.artist,
    this.showTrailingControls = false,
    this.onTap,
    this.isHorizontal = true,
    this.index,
    this.showIndex = false,
    this.onArtistUpdate,
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
              : _buildImageLeading(context),
      title: Text(
        artist.name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        artist.bio ?? 'Artist',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing:
          showTrailingControls
              ? _buildTrailingControls(context)
              : Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
    );
  }

  Widget _buildIndexedLeading(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
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

  Widget _buildImageLeading(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: _buildArtistImage(context),
      ),
    );
  }

  Widget _buildArtistImage(BuildContext context) {
    String imagePath = artist.artistPicture ?? '';

    if (imagePath.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: Icon(
          Icons.person,
          size: 28,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Icon(
              Icons.person,
              size: 28,
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
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Icon(
              Icons.person,
              size: 28,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        },
      );
    }
    // Treat as relative path from server
    else {
      // If it's a relative path, we need to build the full URL
      // This is a fallback in case the service didn't process the URL correctly
      String fullUrl = _buildFullImageUrl(imagePath);

      if (fullUrl.startsWith('http://') || fullUrl.startsWith('https://')) {
        return Image.network(
          fullUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Container(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Icon(
                Icons.person,
                size: 28,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          },
        );
      } else {
        return Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Icon(
                Icons.person,
                size: 28,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          },
        );
      }
    }
  }

  Widget _buildVerticalLayout(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? _handleDefaultTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 160,
              width: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(80),
                color: Theme.of(context).colorScheme.surfaceVariant,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(80),
                child: _buildArtistImage(context),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 140,
              child: Text(
                artist.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailingControls(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onSelected: _handleMenuSelection,
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'view_artist',
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text('View Artist'),
                dense: true,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'view_albums',
              child: ListTile(
                leading: Icon(Icons.album),
                title: Text('View Albums'),
                dense: true,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'view_songs',
              child: ListTile(
                leading: Icon(Icons.music_note),
                title: Text('View Songs'),
                dense: true,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Share'),
                dense: true,
              ),
            ),
          ],
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'view_artist':
        _handleDefaultTap();
        break;
      case 'view_albums':
        if (onTabSelected != null) {
          // Navigate to a hypothetical artist albums screen
          onTabSelected!(ScreenIndex.home.value, 'artist_albums_${artist.id}');
        }
        break;
      case 'view_songs':
        if (onTabSelected != null) {
          // Navigate to a hypothetical artist songs screen
          onTabSelected!(ScreenIndex.home.value, 'artist_songs_${artist.id}');
        }
        break;
      case 'share':
        _handleShare();
        break;
    }
  }

  void _handleDefaultTap() {
    if (onTabSelected != null) {
      // Navigate to artist detail screen
      onTabSelected!(ScreenIndex.artist.value, artist.id.toString());
    }
  }

  void _handleShare() {
    // Handle sharing artist
    // TODO: Implement actual sharing functionality
  }

  String _buildFullImageUrl(String imagePath) {
    if (imagePath.isEmpty) {
      return '';
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    if (serverUrl.isEmpty) {
      return imagePath;
    }

    // Ensure server URL has proper protocol
    if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
      serverUrl = 'http://$serverUrl';
    }

    // Ensure image path starts with /
    if (!imagePath.startsWith('/')) {
      imagePath = '/$imagePath';
    }

    return '$serverUrl$imagePath';
  }

  // Helper methods for creating artist objects
  static Artist createSimpleArtist({
    required int id,
    required String name,
    String? bio,
    String? artistPicture,
  }) {
    return Artist(id: id, name: name, bio: bio, artistPicture: artistPicture);
  }

  // Create artist from search result
  static Artist createArtistFromSearchResult({
    required int id,
    required String name,
    required String image,
  }) {
    return Artist(
      id: id,
      name: name,
      bio: null,
      artistPicture: image.isNotEmpty ? image : null,
    );
  }
}
