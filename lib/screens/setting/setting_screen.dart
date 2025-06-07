import 'package:symphonia/controller/download_controller.dart';
import 'package:symphonia/main.dart';
import 'package:flutter/material.dart';
import 'package:symphonia/widgets/user_avatar.dart';
import 'package:symphonia/services/user_info_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../abstract_navigation_screen.dart';

class SettingScreen extends AbstractScreen {
  @override
  final String title = "Settings";

  @override
  final Icon icon = const Icon(Icons.settings);

  const SettingScreen({super.key, required super.onTabSelected});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  // Controller for các input field
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // State variables
  String _selectedGender = 'Nam';
  DateTime _selectedDate = DateTime(2000, 1, 1);
  String _selectedAudioQuality = '320kbps';
  String _themeMode = 'Hệ thống';
  bool _showLyrics = true;
  bool _showVisualizer = true;
  String _selectedLanguage = 'Tiếng Việt';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          // Account Settings Section
          _buildSectionHeader('Cài đặt tài khoản'),
          _buildAccountSettings(),

          const Divider(thickness: 1),

          // Music Playback Settings Section
          _buildSectionHeader('Cài đặt phát nhạc'),
          _buildMusicPlaybackSettings(),

          const Divider(thickness: 1),

          // Display & Interface Settings
          _buildSectionHeader('Hiển thị & giao diện'),
          _buildDisplaySettings(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal Information
        ListTile(
          title: const Text('Thông tin cá nhân'),
          subtitle: const Text('Thay đổi thông tin cá nhân của bạn'),
          leading: const Icon(Icons.person),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showPersonalInfoDialog();
          },
        ),

        // Change Password
        ListTile(
          title: const Text('Đổi mật khẩu'),
          subtitle: const Text('Thay đổi mật khẩu hiện tại của bạn'),
          leading: const Icon(Icons.lock),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showChangePasswordDialog();
          },
        ),

        // Delete Account
        ListTile(
          title: const Text('Xóa tài khoản'),
          subtitle: const Text('Xóa tài khoản và dữ liệu cá nhân của bạn'),
          leading: Icon(
            Icons.delete_forever,
            color: Theme.of(context).colorScheme.error,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showDeleteAccountDialog();
          },
        ),
      ],
    );
  }

  Widget _buildMusicPlaybackSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Audio Quality
        ListTile(
          title: const Text('Chất lượng tải nhạc (offline)'),
          subtitle: Text(_selectedAudioQuality),
          leading: const Icon(Icons.high_quality),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showAudioQualityDialog();
          },
        ),

        // Delete Account
        ListTile(
          title: const Text('Xóa dữ liệu tải về'),
          leading: const Icon(Icons.delete_forever),
          onTap: () {
            _showDeleteDataDialog();
          },
        ),

        // Auto Play Similar
        // SwitchListTile(
        //   title: const Text('Tự động phát bài tương tự sau khi danh sách kết thúc'),
        //   subtitle: const Text('Phát bài hát tương tự sau khi danh sách phát kết thúc'),
        //   secondary: const Icon(Icons.repeat),
        //   value: _autoPlaySimilar,
        //   onChanged: (value) {
        //     setState(() {
        //       _autoPlaySimilar = value;
        //     });
        //   },
        // ),
      ],
    );
  }

  Widget _buildDisplaySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Theme mode
        ListTile(
          title: const Text('Chế độ giao diện'),
          subtitle: Text(_themeMode),
          leading: const Icon(Icons.dark_mode),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showThemeModeDialog();
          },
        ),

        // Auto Show Lyrics
        SwitchListTile(
          title: const Text('Hiển thị lời bài hát tự động'),
          subtitle: const Text('Tự động hiển thị lời bài hát khi phát nhạc'),
          secondary: const Icon(Icons.lyrics),
          value: _showLyrics,
          onChanged: (value) {
            setState(() {
              _showLyrics = value;
            });
          },
        ),

        // Visualizer Effect
        SwitchListTile(
          title: const Text('Hiệu ứng visualizer khi phát nhạc'),
          subtitle: const Text(
            'Hiển thị hiệu ứng visualizer khi đang phát nhạc',
          ),
          secondary: const Icon(Icons.waves),
          value: _showVisualizer,
          onChanged: (value) {
            setState(() {
              _showVisualizer = value;
            });
          },
        ),

        // Language
        ListTile(
          title: const Text('Ngôn ngữ ứng dụng'),
          subtitle: Text(_selectedLanguage),
          leading: const Icon(Icons.language),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showLanguageDialog();
          },
        ),
      ],
    );
  }

  void _showPersonalInfoDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Thông tin cá nhân'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Display Name
                  TextField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên hiển thị',
                      hintText: 'Nhập tên hiển thị của bạn',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Profile Picture
                  GestureDetector(
                    onTap: () {
                      _showProfilePictureOptions();
                    },
                    child: Row(
                      children: [
                        UserAvatar(
                          radius: 40,
                          isCurrentUser: true,
                          userName: UserInfoManager.username,
                        ),
                        const SizedBox(width: 16),
                        const Text('Thay đổi ảnh đại diện'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Gender
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Giới tính'),
                    value: _selectedGender,
                    items:
                        ['Nam', 'Nữ', 'Khác']
                            .map(
                              (gender) => DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedGender = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date of Birth
                  ListTile(
                    title: const Text('Ngày sinh'),
                    subtitle: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null && picked != _selectedDate) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  // Lưu thông tin người dùng
                  Navigator.of(context).pop();
                },
                child: const Text('Lưu'),
              ),
            ],
          ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Đổi mật khẩu'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current Password
                  TextField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu hiện tại',
                      hintText: 'Nhập mật khẩu hiện tại',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // New Password
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu mới',
                      hintText: 'Nhập mật khẩu mới',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm New Password
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                      hintText: 'Nhập lại mật khẩu mới',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  // Validate and save password
                  Navigator.of(context).pop();
                },
                child: const Text('Lưu'),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xóa tài khoản'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn có chắc chắn muốn xóa tài khoản?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Hành động này sẽ xóa vĩnh viễn tài khoản và tất cả dữ liệu của bạn. Bạn không thể khôi phục lại tài khoản sau khi xóa.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  // Delete account logic
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Xóa tài khoản'),
              ),
            ],
          ),
    );
  }

  void _showAudioQualityDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Chất lượng tải nhạc'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('128kbps'),
                  subtitle: const Text('Tiết kiệm dung lượng'),
                  value: '128kbps',
                  groupValue: _selectedAudioQuality,
                  onChanged: (value) {
                    setState(() {
                      _selectedAudioQuality = value!;
                      Navigator.of(context).pop();
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('320kbps'),
                  subtitle: const Text('Chất lượng cao'),
                  value: '320kbps',
                  groupValue: _selectedAudioQuality,
                  onChanged: (value) {
                    setState(() {
                      _selectedAudioQuality = value!;
                      Navigator.of(context).pop();
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Lossless'),
                  subtitle: const Text('Chất lượng tốt nhất, dung lượng lớn'),
                  value: 'Lossless',
                  groupValue: _selectedAudioQuality,
                  onChanged: (value) {
                    setState(() {
                      _selectedAudioQuality = value!;
                      Navigator.of(context).pop();
                    });
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xóa tài dữ liệu tải xuống'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn có chắc chắn muốn dữ liệu tải xuống?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Hành động này sẽ xóa vĩnh viễn tất cả dữ liệu đã tải xuống. Thao tác này không thể hoàn tác.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  DownloadController.deleteAll();
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );
  }

  void _showThemeModeDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Chế độ giao diện'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Sáng'),
                  value: 'Sáng',
                  groupValue: _themeMode,
                  onChanged: (value) {
                    setState(() {
                      _themeMode = value!;
                      _applyThemeMode(value);
                      Navigator.of(context).pop();
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Tối'),
                  value: 'Tối',
                  groupValue: _themeMode,
                  onChanged: (value) {
                    setState(() {
                      _themeMode = value!;
                      _applyThemeMode(value);
                      Navigator.of(context).pop();
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Hệ thống'),
                  subtitle: const Text('Theo cài đặt hệ thống'),
                  value: 'Hệ thống',
                  groupValue: _themeMode,
                  onChanged: (value) {
                    setState(() {
                      _themeMode = value!;
                      _applyThemeMode(value);
                      Navigator.of(context).pop();
                    });
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _applyThemeMode(String mode) {
    ThemeMode themeMode;
    switch (mode) {
      case 'Sáng':
        themeMode = ThemeMode.light;
        break;
      case 'Tối':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }

    MyApp.of(context).setThemeMode(themeMode);
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ngôn ngữ ứng dụng'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Tiếng Việt'),
                  value: 'Tiếng Việt',
                  groupValue: _selectedLanguage,
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value!;
                      Navigator.of(context).pop();
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('English'),
                  value: 'English',
                  groupValue: _selectedLanguage,
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value!;
                      Navigator.of(context).pop();
                    });
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showProfilePictureOptions() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ảnh đại diện'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Chọn từ thư viện'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImageFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Chụp ảnh mới'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImageFromCamera();
                  },
                ),
                if (UserInfoManager.profilePictureUrl != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Xóa ảnh đại diện',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _deleteProfilePicture();
                    },
                  ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await _updateProfilePicture(File(image.path));
    }
  }

  Future<void> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      await _updateProfilePicture(File(image.path));
    }
  }

  Future<void> _updateProfilePicture(File imageFile) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Đang cập nhật ảnh đại diện...'),
              ],
            ),
          ),
    );

    try {
      bool success = await UserInfoManager.updateProfilePicture(imageFile);
      Navigator.of(context).pop(); // Close loading dialog

      if (success) {
        await UserInfoManager.refreshUserInfo(); // Refresh user info
        setState(() {}); // Refresh UI to show new avatar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật ảnh đại diện thành công'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật ảnh đại diện'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteProfilePicture() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Đang xóa ảnh đại diện...'),
              ],
            ),
          ),
    );

    try {
      bool success = await UserInfoManager.deleteProfilePicture();
      Navigator.of(context).pop(); // Close loading dialog

      if (success) {
        await UserInfoManager.refreshUserInfo(); // Refresh user info
        setState(() {}); // Refresh UI to show default avatar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa ảnh đại diện'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xóa ảnh đại diện'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
