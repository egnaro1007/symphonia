import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'token_manager.dart';

class UserInfoManager {
  static String? _userId;
  static String? _username;
  static String? _firstName;
  static String? _lastName;
  static String? _email;
  static String? _profilePictureUrl;

  static final String _tokenFile = 'user-info.json';

  static Future<void> _saveUserInfo(
    String? userId,
    String? username,
    String? firstName,
    String? lastName,
    String? email,
    String? profilePictureUrl,
  ) async {
    try {
      _userId = userId ?? "";
      _username = username ?? "";
      _firstName = firstName ?? "";
      _lastName = lastName ?? "";
      _email = email ?? "";
      _profilePictureUrl = profilePictureUrl;

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_tokenFile');

      final userInfo = {
        'user_id': _userId,
        'username': _username,
        'first_name': _firstName,
        'last_name': _lastName,
        'email': _email,
        'profile_picture_url': _profilePictureUrl,
      };

      await file.writeAsString(jsonEncode(userInfo));
    } catch (e) {
      // If we can't save to file, at least keep the data in memory
      _userId = userId ?? "";
      _username = username ?? "";
      _firstName = firstName ?? "";
      _lastName = lastName ?? "";
      _email = email ?? "";
      _profilePictureUrl = profilePictureUrl;
    }
  }

  static Future<void> loadUserInfo() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_tokenFile');

    if (await file.exists()) {
      try {
        final content = await file.readAsString();

        // Check if content is empty or invalid
        if (content.trim().isEmpty) {
          await clearUserInfo();
          return;
        }

        final userInfo = jsonDecode(content);

        _userId = userInfo['user_id'];
        _username = userInfo['username'];
        _firstName = userInfo['first_name'];
        _lastName = userInfo['last_name'];
        _email = userInfo['email'];
        _profilePictureUrl = userInfo['profile_picture_url'];
      } catch (e) {
        // If there's an error parsing the file, clear it and reset user info
        await clearUserInfo();
      }
    } else {
      // File doesn't exist, try to fetch from server if we have a token
      if (TokenManager.accessToken != null) {
        await fetchUserInfo();
      }
    }
  }

  static Future<void> clearUserInfo() async {
    // Clear in-memory data first
    _userId = null;
    _username = null;
    _firstName = null;
    _lastName = null;
    _email = null;
    _profilePictureUrl = null;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_tokenFile');

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Even if file deletion fails, we've cleared the in-memory data
    }
  }

  static String get userId {
    return _userId ?? "";
  }

  static String get username {
    return _username ?? "";
  }

  static String get firstName {
    return _firstName ?? "";
  }

  static String get lastName {
    return _lastName ?? "";
  }

  static String get email {
    return _email ?? "";
  }

  static String? get profilePictureUrl {
    return _profilePictureUrl;
  }

  // Get profile picture URL with server URL prefix if needed
  static String? get fullProfilePictureUrl {
    if (_profilePictureUrl == null ||
        _profilePictureUrl!.isEmpty ||
        _profilePictureUrl == 'null') {
      return null;
    }

    // If URL already starts with http, return as is
    if (_profilePictureUrl!.startsWith('http://') ||
        _profilePictureUrl!.startsWith('https://')) {
      return _profilePictureUrl;
    }

    // Add server URL prefix for relative paths
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    if (serverUrl.isNotEmpty && _profilePictureUrl!.startsWith('/')) {
      // Ensure server URL doesn't end with slash
      if (serverUrl.endsWith('/')) {
        serverUrl = serverUrl.substring(0, serverUrl.length - 1);
      }
      return '$serverUrl$_profilePictureUrl';
    }

    return _profilePictureUrl;
  }

  static Future<void> fetchUserInfo() async {
    await TokenManager.loadTokens();

    if (TokenManager.accessToken == null) {
      // No token available, clear user info
      _userId = "";
      _username = "";
      _firstName = "";
      _lastName = "";
      _email = "";
      _profilePictureUrl = null;
      return;
    }

    String serverUrl = dotenv.env['SERVER_URL'] ?? '';

    try {
      final response = await http.get(
        Uri.parse('$serverUrl/api/auth/get_user_info/'),
        headers: {'Authorization': 'Bearer ${TokenManager.accessToken}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _userId = data['id']?.toString() ?? "";
        _username = data['username'] ?? "";
        _firstName = data['first_name'] ?? "";
        _lastName = data['last_name'] ?? "";
        _email = data['email'] ?? "";

        // Handle profile_picture_url properly
        var profilePictureData = data['profile_picture_url'];
        if (profilePictureData == null ||
            profilePictureData.toString().isEmpty) {
          _profilePictureUrl = null;
        } else {
          _profilePictureUrl = profilePictureData.toString();
        }

        await _saveUserInfo(
          _userId,
          _username,
          _firstName,
          _lastName,
          _email,
          _profilePictureUrl,
        );
      } else {
        print('Failed to fetch user info: ${response.statusCode}');
        // Clear user info if request failed
        _userId = "";
        _username = "";
        _firstName = "";
        _lastName = "";
        _email = "";
        _profilePictureUrl = null;
      }
    } catch (e) {
      // Clear user info if there's an error
      _userId = "";
      _username = "";
      _firstName = "";
      _lastName = "";
      _email = "";
      _profilePictureUrl = null;
    }
  }

  // Method to update profile picture
  static Future<bool> updateProfilePicture(File imageFile) async {
    await TokenManager.loadTokens();

    if (TokenManager.accessToken == null) {
      return false;
    }

    String serverUrl = dotenv.env['SERVER_URL'] ?? '';

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$serverUrl/api/auth/update_profile_picture/'),
      );

      request.headers['Authorization'] = 'Bearer ${TokenManager.accessToken}';
      request.files.add(
        await http.MultipartFile.fromPath('profile_picture', imageFile.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        _profilePictureUrl = data['profile_picture_url'];
        await _saveUserInfo(
          _userId,
          _username,
          _firstName,
          _lastName,
          _email,
          _profilePictureUrl,
        );
        return true;
      } else {
        print('Failed to update profile picture: ${response.statusCode}');
        print('Response: $responseBody');
        return false;
      }
    } catch (e) {
      print('Error updating profile picture: $e');
      return false;
    }
  }

  // Method to delete profile picture
  static Future<bool> deleteProfilePicture() async {
    await TokenManager.loadTokens();

    if (TokenManager.accessToken == null) {
      return false;
    }

    String serverUrl = dotenv.env['SERVER_URL'] ?? '';

    try {
      final response = await http.delete(
        Uri.parse('$serverUrl/api/auth/update_profile_picture/'),
        headers: {'Authorization': 'Bearer ${TokenManager.accessToken}'},
      );

      if (response.statusCode == 200) {
        // Profile picture deleted, set to null
        _profilePictureUrl = null;
        await _saveUserInfo(
          _userId,
          _username,
          _firstName,
          _lastName,
          _email,
          _profilePictureUrl,
        );
        return true;
      } else {
        print('Failed to delete profile picture: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting profile picture: $e');
      return false;
    }
  }

  // Method to refresh user info from server
  static Future<void> refreshUserInfo() async {
    await fetchUserInfo();
  }
}
