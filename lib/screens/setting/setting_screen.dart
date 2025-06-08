import 'package:symphonia/main.dart';
import 'package:flutter/material.dart';
import '../abstract_navigation_screen.dart';
import 'package:symphonia/services/user_info_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:symphonia/services/token_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:symphonia/services/preferences_service.dart';

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
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // State variables
  String _themeMode = 'Hệ thống';
  String _selectedLanguage = 'Tiếng Việt';
  bool _isChangePasswordLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final languageCode = await PreferencesService.getLanguage();
    final theme = await PreferencesService.getTheme();

    setState(() {
      // Set language display text
      _selectedLanguage = languageCode == 'en' ? 'English' : 'Tiếng Việt';

      // Set theme display text based on current locale
      switch (theme) {
        case 'light':
          _themeMode = languageCode == 'en' ? 'Light' : 'Sáng';
          break;
        case 'dark':
          _themeMode = languageCode == 'en' ? 'Dark' : 'Tối';
          break;
        default:
          _themeMode = languageCode == 'en' ? 'System' : 'Hệ thống';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.settings)),
      body: ListView(
        children: [
          // Account Settings Section
          _buildSectionHeader(localizations.accountSettings),
          _buildAccountSettings(),

          const Divider(thickness: 1),

          // Display & Interface Settings
          _buildSectionHeader(localizations.displayInterface),
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
    final localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal Information
        ListTile(
          title: Text(localizations.personalInfo),
          subtitle: Text(localizations.changePersonalInfo),
          leading: const Icon(Icons.person),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showEditPersonalInfoDialog();
          },
        ),

        // Change Password
        ListTile(
          title: Text(localizations.changePassword),
          subtitle: Text(localizations.changeCurrentPassword),
          leading: const Icon(Icons.lock),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showChangePasswordDialog();
          },
        ),

        // Delete Account
        ListTile(
          title: Text(localizations.deleteAccount),
          subtitle: Text(localizations.deleteAccountWarning),
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

  Widget _buildDisplaySettings() {
    final localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Theme mode
        ListTile(
          title: Text(localizations.interfaceMode),
          subtitle: Text(_themeMode),
          leading: const Icon(Icons.dark_mode),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showThemeModeDialog();
          },
        ),

        // Language
        ListTile(
          title: Text(localizations.appLanguage),
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

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Đổi mật khẩu'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Current Password
                        TextField(
                          controller: _currentPasswordController,
                          obscureText: true,
                          enabled: !_isChangePasswordLoading,
                          decoration: const InputDecoration(
                            labelText: 'Mật khẩu hiện tại *',
                            hintText: 'Nhập mật khẩu hiện tại',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // New Password
                        TextField(
                          controller: _newPasswordController,
                          obscureText: true,
                          enabled: !_isChangePasswordLoading,
                          decoration: const InputDecoration(
                            labelText: 'Mật khẩu mới *',
                            hintText: 'Nhập mật khẩu mới (tối thiểu 6 ký tự)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm New Password
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          enabled: !_isChangePasswordLoading,
                          decoration: const InputDecoration(
                            labelText: 'Xác nhận mật khẩu mới *',
                            hintText: 'Nhập lại mật khẩu mới',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          _isChangePasswordLoading
                              ? null
                              : () {
                                _currentPasswordController.clear();
                                _newPasswordController.clear();
                                _confirmPasswordController.clear();
                                Navigator.of(context).pop();
                              },
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed:
                          _isChangePasswordLoading
                              ? null
                              : () async {
                                await _changePassword(setState);
                              },
                      child:
                          _isChangePasswordLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Lưu'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _changePassword(StateSetter setState) async {
    // Validation
    String currentPassword = _currentPasswordController.text.trim();
    String newPassword = _newPasswordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mật khẩu hiện tại'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mật khẩu mới'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu mới phải có ít nhất 6 ký tự'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu mới và xác nhận mật khẩu không khớp'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (currentPassword == newPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu mới phải khác mật khẩu hiện tại'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isChangePasswordLoading = true;
    });

    try {
      String serverUrl = dotenv.env['SERVER_URL'] ?? '';

      final response = await http.post(
        Uri.parse('$serverUrl/api/auth/change-password/'),
        headers: {
          'Authorization': 'Bearer ${TokenManager.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      setState(() {
        _isChangePasswordLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Clear the text fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        if (mounted) {
          Navigator.of(context).pop(); // Close dialog

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đổi mật khẩu thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        String errorMessage = 'Không thể đổi mật khẩu';

        try {
          var errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic>) {
            if (errorData.containsKey('current_password')) {
              List<dynamic> errors = errorData['current_password'];
              errorMessage =
                  errors.isNotEmpty
                      ? errors[0]
                      : 'Mật khẩu hiện tại không đúng';
            } else if (errorData.containsKey('new_password')) {
              List<dynamic> errors = errorData['new_password'];
              errorMessage =
                  errors.isNotEmpty ? errors[0] : 'Mật khẩu mới không hợp lệ';
            } else if (errorData.containsKey('detail')) {
              errorMessage = errorData['detail'];
            } else if (errorData.containsKey('error')) {
              errorMessage = errorData['error'];
            } else {
              errorMessage = 'Không thể đổi mật khẩu';
            }
          }
        } catch (e) {
          errorMessage = 'Lỗi server không xác định';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isChangePasswordLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  void _showThemeModeDialog() async {
    final localizations = AppLocalizations.of(context)!;
    final currentLanguage = await PreferencesService.getLanguage();

    // Create theme option texts based on current language
    final lightText = currentLanguage == 'en' ? 'Light' : 'Sáng';
    final darkText = currentLanguage == 'en' ? 'Dark' : 'Tối';
    final systemText = currentLanguage == 'en' ? 'System' : 'Hệ thống';
    final systemSubtitle =
        currentLanguage == 'en'
            ? 'Follow system setting'
            : 'Theo cài đặt hệ thống';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations.interfaceMode),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: Text(lightText),
                  value: lightText,
                  groupValue: _themeMode,
                  onChanged: (value) {
                    setState(() {
                      _themeMode = value!;
                      _applyThemeMode('light');
                      Navigator.of(context).pop();
                    });
                  },
                ),
                RadioListTile<String>(
                  title: Text(darkText),
                  value: darkText,
                  groupValue: _themeMode,
                  onChanged: (value) {
                    setState(() {
                      _themeMode = value!;
                      _applyThemeMode('dark');
                      Navigator.of(context).pop();
                    });
                  },
                ),
                RadioListTile<String>(
                  title: Text(systemText),
                  subtitle: Text(systemSubtitle),
                  value: systemText,
                  groupValue: _themeMode,
                  onChanged: (value) {
                    setState(() {
                      _themeMode = value!;
                      _applyThemeMode('system');
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
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }

    MyApp.of(context).setThemeMode(themeMode);
  }

  void _showLanguageDialog() {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(localizations.appLanguage),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: Text(localizations.vietnamese),
                  value: 'Tiếng Việt',
                  groupValue: _selectedLanguage,
                  onChanged: (value) async {
                    setState(() {
                      _selectedLanguage = value!;
                    });
                    // Change app locale
                    MyApp.of(context).setLocale(const Locale('vi'));
                    // Update theme mode text based on new language
                    await _updateThemeModeText('vi');
                    Navigator.of(context).pop();
                  },
                ),
                RadioListTile<String>(
                  title: Text(localizations.english),
                  value: 'English',
                  groupValue: _selectedLanguage,
                  onChanged: (value) async {
                    setState(() {
                      _selectedLanguage = value!;
                    });
                    // Change app locale
                    MyApp.of(context).setLocale(const Locale('en'));
                    // Update theme mode text based on new language
                    await _updateThemeModeText('en');
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _updateThemeModeText(String languageCode) async {
    final theme = await PreferencesService.getTheme();
    setState(() {
      switch (theme) {
        case 'light':
          _themeMode = languageCode == 'en' ? 'Light' : 'Sáng';
          break;
        case 'dark':
          _themeMode = languageCode == 'en' ? 'Dark' : 'Tối';
          break;
        default:
          _themeMode = languageCode == 'en' ? 'System' : 'Hệ thống';
      }
    });
  }

  void _showEditPersonalInfoDialog() {
    // Controllers for input fields
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();

    // State variables
    String selectedGender = 'Nam';
    DateTime selectedDate = DateTime(2000, 1, 1);
    bool isLoading = false;
    File? selectedProfileImage;
    bool deleteAvatar = false;

    // Load current user data
    firstNameController.text = UserInfoManager.firstName;
    lastNameController.text = UserInfoManager.lastName;
    emailController.text = UserInfoManager.email;

    // Load gender
    String userGender = UserInfoManager.gender;
    switch (userGender) {
      case 'M':
        selectedGender = 'Nam';
        break;
      case 'F':
        selectedGender = 'Nữ';
        break;
      case 'O':
        selectedGender = 'Khác';
        break;
      default:
        selectedGender = 'Nam';
    }

    // Load birth date
    String userBirthDate = UserInfoManager.birthDate;
    if (userBirthDate.isNotEmpty) {
      try {
        List<String> dateParts = userBirthDate.split('-');
        if (dateParts.length == 3) {
          int year = int.parse(dateParts[0]);
          int month = int.parse(dateParts[1]);
          int day = int.parse(dateParts[2]);
          selectedDate = DateTime(year, month, day);
        }
      } catch (e) {
        selectedDate = DateTime(2000, 1, 1);
      }
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Transform.translate(
                  offset: const Offset(0, -50),
                  child: AlertDialog(
                    title: const Text('Thông tin cá nhân'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Profile Picture Section
                            GestureDetector(
                              onTap:
                                  () => _showProfilePictureOptionsInDialog(
                                    context,
                                    setState,
                                    selectedProfileImage,
                                    (file, shouldDelete) {
                                      setState(() {
                                        selectedProfileImage = file;
                                        deleteAvatar = shouldDelete;
                                      });
                                    },
                                  ),
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundImage:
                                        selectedProfileImage != null
                                            ? FileImage(selectedProfileImage!)
                                            : (!deleteAvatar &&
                                                    UserInfoManager
                                                            .fullProfilePictureUrl !=
                                                        null
                                                ? NetworkImage(
                                                  UserInfoManager
                                                      .fullProfilePictureUrl!,
                                                )
                                                : null),
                                    backgroundColor: Colors.grey[400],
                                    child:
                                        selectedProfileImage == null &&
                                                (deleteAvatar ||
                                                    UserInfoManager
                                                            .fullProfilePictureUrl ==
                                                        null)
                                            ? Text(
                                              UserInfoManager
                                                      .username
                                                      .isNotEmpty
                                                  ? UserInfoManager.username[0]
                                                      .toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                color: Colors.white,
                                              ),
                                            )
                                            : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // First Name
                            TextField(
                              controller: firstNameController,
                              decoration: const InputDecoration(
                                labelText: 'Tên *',
                                border: OutlineInputBorder(),
                              ),
                              enabled: !isLoading,
                            ),
                            const SizedBox(height: 12),

                            // Last Name
                            TextField(
                              controller: lastNameController,
                              decoration: const InputDecoration(
                                labelText: 'Họ *',
                                border: OutlineInputBorder(),
                              ),
                              enabled: !isLoading,
                            ),
                            const SizedBox(height: 12),

                            // Email
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                              enabled: !isLoading,
                            ),
                            const SizedBox(height: 12),

                            // Gender
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Giới tính',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedGender,
                              items:
                                  ['Nam', 'Nữ', 'Khác']
                                      .map(
                                        (gender) => DropdownMenuItem(
                                          value: gender,
                                          child: Text(gender),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  isLoading
                                      ? null
                                      : (value) {
                                        if (value != null) {
                                          setState(() {
                                            selectedGender = value;
                                          });
                                        }
                                      },
                            ),
                            const SizedBox(height: 12),

                            // Date of Birth
                            InkWell(
                              onTap:
                                  isLoading
                                      ? null
                                      : () async {
                                        final DateTime? picked =
                                            await showDatePicker(
                                              context: context,
                                              initialDate: selectedDate,
                                              firstDate: DateTime(1900),
                                              lastDate: DateTime.now(),
                                            );
                                        if (picked != null &&
                                            picked != selectedDate) {
                                          setState(() {
                                            selectedDate = picked;
                                          });
                                        }
                                      },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ngày sinh',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    const Icon(Icons.calendar_today),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed:
                            isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed:
                            isLoading
                                ? null
                                : () async {
                                  // Validation
                                  if (firstNameController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Tên không được để trống',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  if (lastNameController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Họ không được để trống'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() {
                                    isLoading = true;
                                  });

                                  await _savePersonalInfo(
                                    firstNameController.text.trim(),
                                    lastNameController.text.trim(),
                                    emailController.text.trim(),
                                    selectedGender,
                                    selectedDate,
                                    selectedProfileImage,
                                    deleteAvatar,
                                    () => setState(() => isLoading = false),
                                  );
                                },
                        child:
                            isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Lưu'),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Future<void> _savePersonalInfo(
    String firstName,
    String lastName,
    String email,
    String selectedGender,
    DateTime selectedDate,
    File? selectedProfileImage,
    bool deleteAvatar,
    VoidCallback setLoadingFalse,
  ) async {
    try {
      String serverUrl = dotenv.env['SERVER_URL'] ?? '';

      // Convert gender to backend format
      String genderCode = '';
      switch (selectedGender) {
        case 'Nam':
          genderCode = 'M';
          break;
        case 'Nữ':
          genderCode = 'F';
          break;
        case 'Khác':
          genderCode = 'O';
          break;
      }

      // Format birth date as YYYY-MM-DD
      String birthDateString =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

      final response = await http.put(
        Uri.parse('$serverUrl/api/auth/update_profile/'),
        headers: {
          'Authorization': 'Bearer ${TokenManager.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'gender': genderCode,
          'birth_date': birthDateString,
        }),
      );

      setLoadingFalse();

      if (response.statusCode == 200) {
        // Update profile picture if selected
        if (selectedProfileImage != null) {
          await UserInfoManager.updateProfilePicture(selectedProfileImage);
        } else if (deleteAvatar) {
          await UserInfoManager.deleteProfilePicture();
        }

        // Update local user info
        await UserInfoManager.fetchUserInfo();

        if (mounted) {
          Navigator.of(context).pop(); // Close dialog

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật thông tin thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        var errorData = jsonDecode(response.body);
        String errorMessage = 'Không thể cập nhật thông tin';

        if (errorData is Map<String, dynamic>) {
          List<String> errors = [];
          errorData.forEach((key, value) {
            if (value is List) {
              errors.addAll(value.map((e) => e.toString()));
            } else {
              errors.add(value.toString());
            }
          });
          if (errors.isNotEmpty) {
            errorMessage = errors.join(', ');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setLoadingFalse();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProfilePictureOptionsInDialog(
    BuildContext context,
    StateSetter setState,
    File? currentSelectedImage,
    Function(File?, bool) onImageSelected,
  ) {
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
                  onTap: () async {
                    Navigator.of(context).pop();
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      onImageSelected(File(image.path), false);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Chụp ảnh mới'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (image != null) {
                      onImageSelected(File(image.path), false);
                    }
                  },
                ),
                if (currentSelectedImage != null ||
                    UserInfoManager.profilePictureUrl != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Xóa ảnh đại diện',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      onImageSelected(null, true);
                    },
                  ),
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
