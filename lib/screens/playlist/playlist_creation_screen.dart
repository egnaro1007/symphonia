import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:symphonia/services/playlist.dart';
import 'package:symphonia/services/playlist_notifier.dart';
import '../abstract_navigation_screen.dart';

class PlaylistCreationScreen extends AbstractScreen {
  const PlaylistCreationScreen({super.key, required super.onTabSelected});

  @override
  String get title => 'Tạo Playlist';

  @override
  Icon get icon => const Icon(Icons.playlist_add);

  @override
  State<PlaylistCreationScreen> createState() => _PlaylistCreationScreenState();
}

enum SharePermission { public, friendsOnly, private }

class _PlaylistCreationScreenState extends State<PlaylistCreationScreen> {
  final TextEditingController _nameController = TextEditingController();
  SharePermission _sharePermission =
      SharePermission.private; // Default to private
  bool _isButtonActive = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_checkButtonState);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _checkButtonState() {
    setState(() {
      _isButtonActive = _nameController.text.isNotEmpty;
    });
  }

  void _resetForm() {
    setState(() {
      // Reset text field
      _nameController.clear();

      // Reset selected image
      _selectedImage = null;

      // Reset permission to default (private)
      _sharePermission = SharePermission.private;

      // Reset button state
      _isButtonActive = false;
    });

    print("Form reset to default state");
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
        });
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
        },
        activeColor: colorScheme.primary,
      ),
      onTap: () {
        setState(() {
          _sharePermission = permission;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // App bar with close button
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.close, color: colorScheme.onSurface),
                  onPressed: () {
                    // Navigate back using the navigation system
                    widget.onTabSelected(-1, "");
                  },
                ),
              ),
            ),

            // Main content - Now scrollable
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
                        // Section title with better styling
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
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withOpacity(
                                  0.3,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outline,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.shadow.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child:
                                  _selectedImage != null
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                      : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 40,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Thêm ảnh bìa',
                                            style: TextStyle(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Action buttons row (centered under image)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: const Text('Chọn ảnh'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primaryContainer,
                                foregroundColor: colorScheme.onPrimaryContainer,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            if (_selectedImage != null) ...[
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedImage = null;
                                  });
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                label: const Text('Xóa ảnh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.errorContainer,
                                  foregroundColor: colorScheme.onErrorContainer,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Playlist name section with better styling
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.title,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tên playlist',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Enhanced text field
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.outline,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Nhập tên của Playlist',
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

                    // Add bottom padding to ensure content doesn't get hidden behind the button
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom create button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _isButtonActive
                          ? () async {
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
                              // Get the playlist name
                              String playlistName = _nameController.text;

                              bool success = false;
                              String? playlistId;

                              // Convert share permission to string based on backend API
                              String sharePermissionString;
                              switch (_sharePermission) {
                                case SharePermission.public:
                                  sharePermissionString = 'public';
                                  break;
                                case SharePermission.friendsOnly:
                                  sharePermissionString = 'friends';
                                  break;
                                case SharePermission.private:
                                  sharePermissionString = 'private';
                                  break;
                              }

                              if (_selectedImage != null) {
                                // Create playlist with cover image
                                playlistId =
                                    await PlayListOperations.addPlaylistWithCoverAndPermission(
                                      playlistName,
                                      sharePermissionString,
                                      _selectedImage,
                                    );
                                success = playlistId != null;
                              } else {
                                // Create playlist without cover image
                                success =
                                    await PlayListOperations.addPlaylistWithPermission(
                                      playlistName,
                                      sharePermissionString,
                                    );
                              }

                              Navigator.pop(context); // Close loading dialog

                              if (success) {
                                // Notify playlist list to refresh
                                PlaylistUpdateNotifier().notifyPlaylistUpdate();

                                // Reset the form to default state
                                _resetForm();

                                // Success
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Playlist đã được tạo thành công!',
                                    ),
                                    backgroundColor: colorScheme.tertiary,
                                  ),
                                );

                                // Navigate back to previous screen
                                widget.onTabSelected(-1, "");
                              } else {
                                // Failed
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Có lỗi xảy ra khi tạo playlist',
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
                                    'Có lỗi xảy ra khi tạo playlist',
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
                    'TẠO PLAYLIST',
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
