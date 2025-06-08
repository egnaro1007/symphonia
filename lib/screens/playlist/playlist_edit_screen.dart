import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:symphonia/models/playlist.dart';
import 'package:symphonia/services/playlist.dart';
import 'package:symphonia/services/playlist_notifier.dart';
import 'package:symphonia/constants/screen_index.dart';
import '../abstract_navigation_screen.dart';

class PlaylistEditScreen extends AbstractScreen {
  final PlayList playlist;

  const PlaylistEditScreen({
    super.key,
    required this.playlist,
    required super.onTabSelected,
  });

  @override
  String get title => 'Chỉnh sửa Playlist';

  @override
  Icon get icon => const Icon(Icons.edit);

  @override
  State<PlaylistEditScreen> createState() => _PlaylistEditScreenState();
}

enum SharePermission { public, friendsOnly, private }

class _PlaylistEditScreenState extends State<PlaylistEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  SharePermission _sharePermission = SharePermission.private;
  bool _isButtonActive = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  String? _currentImagePath;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_checkButtonState);
    _initializeForm();
  }

  void _initializeForm() {
    // Initialize form with current playlist data
    _nameController.text = widget.playlist.title;
    _currentImagePath = widget.playlist.picture;

    // Set share permission
    switch (widget.playlist.sharePermission) {
      case 'public':
        _sharePermission = SharePermission.public;
        break;
      case 'friends':
        _sharePermission = SharePermission.friendsOnly;
        break;
      case 'private':
      default:
        _sharePermission = SharePermission.private;
        break;
    }

    _checkButtonState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _checkButtonState() {
    setState(() {
      _isButtonActive =
          _nameController.text.isNotEmpty &&
              _nameController.text.trim() != widget.playlist.title ||
          _imageChanged ||
          _getPermissionString() != widget.playlist.sharePermission;
    });
  }

  String _getPermissionString() {
    switch (_sharePermission) {
      case SharePermission.public:
        return 'public';
      case SharePermission.friendsOnly:
        return 'friends';
      case SharePermission.private:
        return 'private';
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageChanged = true;
        });
        _checkButtonState();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Có lỗi xảy ra khi chọn ảnh'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageChanged = true;
    });
    _checkButtonState();
  }

  Widget _buildSharePermissionTile(
    SharePermission permission,
    String title,
    String description,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _sharePermission == permission;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
      trailing: Radio<SharePermission>(
        value: permission,
        groupValue: _sharePermission,
        onChanged: (SharePermission? value) {
          setState(() {
            _sharePermission = value!;
          });
          _checkButtonState();
        },
        activeColor: colorScheme.primary,
      ),
      onTap: () {
        setState(() {
          _sharePermission = permission;
        });
        _checkButtonState();
      },
    );
  }

  Widget _buildCurrentImage() {
    if (_selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.cover);
    } else if (_currentImagePath != null &&
        _currentImagePath!.isNotEmpty &&
        !_imageChanged) {
      if (_currentImagePath!.startsWith('http://') ||
          _currentImagePath!.startsWith('https://')) {
        return Image.network(_currentImagePath!, fit: BoxFit.cover);
      } else if (_currentImagePath!.startsWith('assets/')) {
        return Image.asset(_currentImagePath!, fit: BoxFit.cover);
      } else {
        return Image.file(File(_currentImagePath!), fit: BoxFit.cover);
      }
    } else {
      return Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          return Container(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image,
                  size: 40,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Chạm để chọn ảnh',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // App bar with done button
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    // Navigate back to playlist screen with refresh
                    Navigator.pop(context);
                    widget.onTabSelected(
                      ScreenIndex.playlist.value,
                      widget.playlist.id,
                    );
                  },
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),

            // Main content - Scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Cover image section
                    Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.image,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ảnh bìa',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Centered image preview
                        Center(
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colorScheme.outline,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: _buildCurrentImage(),
                                  ),
                                ),
                              ),
                              if (_selectedImage != null ||
                                  (_currentImagePath != null &&
                                      _currentImagePath!.isNotEmpty &&
                                      !_imageChanged))
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: _removeImage,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: colorScheme.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: colorScheme.onError,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Playlist name section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.edit,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tên Playlist',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outline),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Nhập tên playlist...',
                              hintStyle: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Share permission section
                    Text(
                      'Quyền chia sẻ',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildSharePermissionTile(
                            SharePermission.public,
                            'Công khai',
                            'Mọi người đều có thể xem và tìm kiếm',
                            Icons.public,
                          ),
                          Divider(height: 1, color: colorScheme.outline),
                          _buildSharePermissionTile(
                            SharePermission.friendsOnly,
                            'Chỉ bạn bè',
                            'Chỉ những người bạn theo dõi mới có thể xem',
                            Icons.people,
                          ),
                          Divider(height: 1, color: colorScheme.outline),
                          _buildSharePermissionTile(
                            SharePermission.private,
                            'Riêng tư',
                            'Chỉ bạn có thể xem playlist này',
                            Icons.lock,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom update button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _isButtonActive
                          ? () async {
                            // Validate playlist name
                            if (_nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Tên playlist không thể để trống',
                                  ),
                                  backgroundColor: colorScheme.error,
                                ),
                              );
                              return;
                            }

                            // Show loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            );

                            try {
                              String playlistName = _nameController.text.trim();
                              String sharePermissionString =
                                  _getPermissionString();

                              bool success =
                                  await PlayListOperations.updatePlaylist(
                                    widget.playlist.id,
                                    playlistName,
                                    sharePermissionString,
                                    _imageChanged ? _selectedImage : null,
                                    _imageChanged &&
                                        _selectedImage ==
                                            null, // Remove image flag
                                  );

                              Navigator.pop(context); // Close loading dialog

                              if (success) {
                                // Notify playlist list to refresh
                                PlaylistUpdateNotifier().notifyPlaylistUpdate();

                                // Success
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Playlist đã được cập nhật thành công!',
                                    ),
                                    backgroundColor: colorScheme.tertiary,
                                  ),
                                );

                                // Update the current state to reflect saved changes
                                setState(() {
                                  // Update the playlist data with new values
                                  widget.playlist.title = playlistName;
                                  widget.playlist.sharePermission =
                                      sharePermissionString;

                                  // Reset change tracking
                                  _imageChanged = false;
                                  if (_selectedImage != null) {
                                    _currentImagePath = _selectedImage!.path;
                                    _selectedImage = null;
                                  }

                                  // Update button state
                                  _checkButtonState();
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Có lỗi xảy ra khi cập nhật playlist',
                                    ),
                                    backgroundColor: colorScheme.error,
                                  ),
                                );
                              }
                            } catch (e) {
                              Navigator.pop(context); // Close loading dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Có lỗi xảy ra khi cập nhật playlist',
                                  ),
                                  backgroundColor: colorScheme.error,
                                ),
                              );
                            }
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isButtonActive
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                    foregroundColor:
                        _isButtonActive
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'CẬP NHẬT PLAYLIST',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
