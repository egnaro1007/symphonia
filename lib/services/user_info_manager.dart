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

  static Future<void> _saveUserInfo(String? username, String? firstName, String? lastName, String? email) async {
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
  }

  static Future<void> loadUserInfo() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_tokenFile');

    if (await file.exists()) {
      final content = await file.readAsString();
      final userInfo = jsonDecode(content);

      _username = userInfo['username'];
      _firstName = userInfo['first_name'];
      _lastName = userInfo['last_name'];
      _email = userInfo['email'];
    } else {
      fetchUserInfo();
    }
  }

  static Future<void> clearUserInfo() async {
    _username = null;
    _firstName = null;
    _lastName = null;
    _email = null;

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_tokenFile');

    if (await file.exists()) {
      await file.delete();
    }
  }

  static String get username {
    if (_username == null) {
      loadUserInfo();
    }
    return _username ?? "Guest";
  }
  static String get firstName {
    if (_firstName == null) {
      loadUserInfo();
    }
    return _firstName ?? "";
  }
  static String get lastName {
    if (_lastName == null) {
      loadUserInfo();
    }
    return _lastName ?? "";
  }
  static String get email {
    if (_email == null) {
      loadUserInfo();
    }
    return _email ?? "";
  }

  static Future<void> fetchUserInfo() async {
    await loadUserInfo();
    await TokenManager.loadTokens();

    if (TokenManager.accessToken == null) {
      return;
    }

    String serverUrl = dotenv.env['SERVER_URL'] ?? '';

    final response = await http.get(
      Uri.parse('$serverUrl/api/auth/get_user_info/'),
      headers: {
        'Authorization': 'Bearer ${TokenManager.accessToken}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _username = data['username'];
      _firstName = data['first_name'];
      _lastName = data['last_name'];
      _email = data['email'];
      await _saveUserInfo(
        _username,
        _firstName,
        _lastName,
        _email
      );
    } else {
      _username = "";
      _firstName = "";
      _lastName = "";
      _email = "";
    }
  }
}