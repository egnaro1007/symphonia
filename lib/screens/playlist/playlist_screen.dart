import 'package:flutter/material.dart';
import 'package:symphonia/models/playlist.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/screens/abstract_navigation_screen.dart';
import 'package:symphonia/services/playlist.dart';
import 'package:symphonia/widgets/song_item.dart';
import 'package:symphonia/controller/player_controller.dart';
import 'package:symphonia/screens/playlist/playlist_edit_screen.dart';
import 'dart:io';

class PlaylistScreen extends AbstractScreen {
  final String playlistID;

  const PlaylistScreen({
    super.key,
    required this.playlistID,
    required super.onTabSelected,
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();

  @override
  Icon get icon => const Icon(Icons.playlist_play);

  @override
  String get title => "Playlist";
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  bool _isDeleteMode = false;
  int _refreshKey = 0;

  void _refreshPlaylist() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          FutureBuilder<PlayList>(
            key: ValueKey(_refreshKey),
            future: PlayListOperations.getLocalPlaylist(widget.playlistID),
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
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Không thể tải playlist',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vui lòng kiểm tra kết nối và thử lại',
                        style: TextStyle(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshPlaylist,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData) {
                return const Center(child: Text('No data available'));
              } else {
                final playlist = snapshot.data!;
                return _buildPlaylistContent(playlist);
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
      leading:
          _isDeleteMode
              ? null
              : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  // Navigate back to the profile screen with symchart parameter
                  widget.onTabSelected(3, "symchart");
                },
              ),
      actions:
          _isDeleteMode
              ? [
                IconButton(
                  icon: const Icon(Icons.done, color: Colors.black),
                  onPressed: _exitDeleteMode,
                ),
              ]
              : null,
    );
  }

  Widget _buildPlaylistContent(PlayList playlist) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [_buildPlaylistHeader(playlist), _buildSongsList(playlist)],
        ),
      ),
    );
  }

  Widget _buildPlaylistHeader(PlayList playlist) {
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
          _buildPlaylistCover(playlist),
          const SizedBox(height: 24),
          _buildPlaylistInfo(playlist),
          const SizedBox(height: 12),
          _buildPlaylistStats(playlist),
          _buildPlayableSongsIndicator(playlist),
          const SizedBox(height: 24),
          _buildActionButtons(playlist),
        ],
      ),
    );
  }

  Widget _buildPlaylistCover(PlayList playlist) {
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
        child: _buildPlaylistImage(playlist),
      ),
    );
  }

  Widget _buildPlaylistInfo(PlayList playlist) {
    return Column(
      children: [
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
              child: const Icon(Icons.person, size: 16, color: Colors.white),
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
      ],
    );
  }

  Widget _buildPlaylistStats(PlayList playlist) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${playlist.songsCount} bài hát • ${playlist.formattedDuration}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Text(' • ', style: TextStyle(fontSize: 14, color: Colors.grey)),
        Icon(
          _getPermissionIcon(playlist.sharePermission),
          size: 16,
          color: _getPermissionColor(playlist.sharePermission),
        ),
        const SizedBox(width: 4),
        Text(
          _getPermissionDisplayText(playlist.sharePermission),
          style: TextStyle(
            fontSize: 14,
            color: _getPermissionColor(playlist.sharePermission),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayableSongsIndicator(PlayList playlist) {
    int playableSongs =
        playlist.songs.where((song) => song.audioUrl.isNotEmpty).length;

    if (playableSongs < playlist.songsCount) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '$playableSongs/${playlist.songsCount} bài có thể phát',
          style: TextStyle(
            fontSize: 12,
            color: Colors.orange.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildActionButtons(PlayList playlist) {
    if (_isDeleteMode) {
      return const SizedBox.shrink(); // Hide all action buttons in delete mode
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.edit_outlined,
          onTap: () => _handleEditPlaylist(playlist),
        ),
        _buildPlayButton(playlist),
        _buildActionButton(icon: Icons.delete_outline, onTap: _enterDeleteMode),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
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

  Widget _buildPlayButton(PlayList playlist) {
    return ElevatedButton.icon(
      onPressed: () => _handlePlayPlaylist(playlist),
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

  Widget _buildSongsList(PlayList playlist) {
    return Container(
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
                isDeleteMode: _isDeleteMode,
                playlistId: playlist.id,
                onTap:
                    _isDeleteMode
                        ? null
                        : () => _handleSongTap(playlist, index),
                onSongDeleted: () => _refreshPlaylist(),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildPlaylistImage(PlayList playlist) {
    String imagePath = _getImagePath(playlist);

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

  String _getImagePath(PlayList playlist) {
    if (playlist.picture.isNotEmpty) {
      return playlist.picture;
    } else if (playlist.songs.isNotEmpty) {
      return playlist.songs[0].imagePath;
    }
    return '';
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.music_note, size: 80, color: Colors.grey),
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
  void _handleEditPlaylist(PlayList playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PlaylistEditScreen(
              playlist: playlist,
              onTabSelected: widget.onTabSelected,
            ),
      ),
    );
  }

  void _handlePlayPlaylist(PlayList playlist) {
    if (playlist.songs.isEmpty) return;

    int firstPlayableIndex = playlist.songs.indexWhere(
      (song) => song.audioUrl.isNotEmpty,
    );

    if (firstPlayableIndex != -1) {
      PlayerController.getInstance().loadPlaylist(playlist, firstPlayableIndex);
    } else {
      _showNoPlayableSongsMessage();
    }
  }

  void _handleSongTap(PlayList playlist, int index) {
    PlayerController.getInstance().loadPlaylist(playlist, index);
  }

  void _showNoPlayableSongsMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Playlist này không có bài hát nào có thể phát'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showDeleteConfirmationDialog(PlayList playlist) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa playlist'),
          content: Text(
            'Bạn có chắc chắn muốn xóa playlist "${playlist.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => _deletePlaylist(playlist),
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePlaylist(PlayList playlist) async {
    Navigator.pop(context); // Close dialog

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      bool success = await PlayListOperations.deletePlaylist(playlist.id);
      Navigator.pop(context); // Close loading

      if (success) {
        _showSuccessMessage('Đã xóa playlist thành công!');
        widget.onTabSelected(-1, ""); // Navigate back to previous screen
      } else {
        _showErrorMessage('Có lỗi xảy ra khi xóa playlist');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      _showErrorMessage('Có lỗi xảy ra khi xóa playlist');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Permission helper methods
  String _getPermissionDisplayText(String? permission) {
    switch (permission?.toLowerCase()) {
      case 'public':
        return 'Công khai';
      case 'friends':
        return 'Chỉ bạn bè';
      case 'private':
        return 'Riêng tư';
      default:
        return 'Riêng tư';
    }
  }

  IconData _getPermissionIcon(String? permission) {
    switch (permission?.toLowerCase()) {
      case 'public':
        return Icons.public;
      case 'friends':
        return Icons.people;
      case 'private':
        return Icons.lock;
      default:
        return Icons.lock;
    }
  }

  Color _getPermissionColor(String? permission) {
    switch (permission?.toLowerCase()) {
      case 'public':
        return Colors.green;
      case 'friends':
        return Colors.blue;
      case 'private':
        return Colors.orange;
      default:
        return Colors.orange;
    }
  }

  // Delete mode methods
  void _enterDeleteMode() {
    setState(() {
      _isDeleteMode = true;
    });
  }

  void _exitDeleteMode() {
    setState(() {
      _isDeleteMode = false;
    });
  }
}
