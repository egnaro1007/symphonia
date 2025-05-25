import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'token_manager.dart';

class UserInfoManager {
  static String? _username;
  static String? _firstName;
  static String? _lastName;
  static String? _email;

  static final String _tokenFile = 'user-info.json';

  static Future<void> _saveUserInfo(
    String? username,
    String? firstName,
    String? lastName,
    String? email,
  ) async {
    try {
      _username = username ?? "";
      _firstName = firstName ?? "";
      _lastName = lastName ?? "";
      _email = email ?? "";

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_tokenFile');

      final userInfo = {
        'username': _username,
        'first_name': _firstName,
        'last_name': _lastName,
        'email': _email,
      };

      await file.writeAsString(jsonEncode(userInfo));
    } catch (e) {
      print('Error saving user info: $e');
      // If we can't save to file, at least keep the data in memory
      _username = username ?? "";
      _firstName = firstName ?? "";
      _lastName = lastName ?? "";
      _email = email ?? "";
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
          print('User info file is empty, clearing user info');
          await clearUserInfo();
          return;
        }

        final userInfo = jsonDecode(content);

        _username = userInfo['username'];
        _firstName = userInfo['first_name'];
        _lastName = userInfo['last_name'];
        _email = userInfo['email'];
      } catch (e) {
        print('Error loading user info: $e');
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
    _username = null;
    _firstName = null;
    _lastName = null;
    _email = null;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_tokenFile');

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error clearing user info file: $e');
      // Even if file deletion fails, we've cleared the in-memory data
    }
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

  static Future<void> fetchUserInfo() async {
    await TokenManager.loadTokens();

    if (TokenManager.accessToken == null) {
      // No token available, clear user info
      _username = "";
      _firstName = "";
      _lastName = "";
      _email = "";
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
        _username = data['username'] ?? "";
        _firstName = data['first_name'] ?? "";
        _lastName = data['last_name'] ?? "";
        _email = data['email'] ?? "";
        await _saveUserInfo(_username, _firstName, _lastName, _email);
      } else {
        print('Failed to fetch user info: ${response.statusCode}');
        // Clear user info if request failed
        _username = "";
        _firstName = "";
        _lastName = "";
        _email = "";
      }
    } catch (e) {
      print('Error fetching user info: $e');
      // Clear user info if there's an error
      _username = "";
      _firstName = "";
      _lastName = "";
      _email = "";
    }
  }
}
