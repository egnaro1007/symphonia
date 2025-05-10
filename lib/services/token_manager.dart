import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'user_info_manager.dart';

class TokenManager {
  static String? _accessToken;
  static String? _refreshToken;

  static final String _tokenFile = 'tokens.json';

  static Future<void> _saveTokens(String accessToken, [String? refreshToken]) async {
    _accessToken = accessToken;

    if (refreshToken == null) {
      if (_refreshToken == null) {
        throw Exception('Refresh token is required');
      } else {
        refreshToken = _refreshToken;
      }
    } else {
      _refreshToken = refreshToken;
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_tokenFile');

    final tokens = {
      'access_token': accessToken,
      'refresh_token': refreshToken,
    };

    await file.writeAsString(jsonEncode(tokens));
  }

  static Future<void> loadTokens() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_tokenFile');

    if (await file.exists()) {
      final content = await file.readAsString();
      final tokens = jsonDecode(content);

      _accessToken = tokens['access_token'];
      _refreshToken = tokens['refresh_token'];
    } else {
      _accessToken = null;
      _refreshToken = null;
    }
  }

  static Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_tokenFile');

    if (await file.exists()) {
      await file.delete();
    }
  }


  static String? get accessToken => _accessToken;
  static String? get refreshToken => _refreshToken;


  static Future<bool> verifyToken() async {
    await loadTokens();

    final String? accessToken = TokenManager.accessToken;
    final String? refreshToken = TokenManager.refreshToken;
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';

    if (accessToken == null || refreshToken == null) {
      return false;
    }

    // Verify the access token
    final verifyResponse = await http.post(
      Uri.parse('$serverUrl/api/auth/token/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': accessToken}),
    );

    if (verifyResponse.statusCode == 200) {
      return true;
    } else if (verifyResponse.statusCode == 401) {
      // Refresh the token
      final refreshResponse = await http.post(
        Uri.parse('$serverUrl/api/auth/token/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (refreshResponse.statusCode == 200) {
        final data = jsonDecode(refreshResponse.body);
        final newAccessToken = data['access'];
        await _saveTokens(newAccessToken);
        return true;
      }
    }

    await _clearTokens();
    return false;
  }

  static Future<void> signup(String username, String password) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';

    final response = await http.post(
      Uri.parse('$serverUrl/api/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to signup');
    }
  }

  static Future<void> login(String username, String password) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';

    final response = await http.post(
      Uri.parse('$serverUrl/api/auth/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data['access'];
      final refreshToken = data['refresh'];
      await _saveTokens(accessToken, refreshToken);

      UserInfoManager.fetchUserInfo();
    } else {
      throw Exception('Failed to login');
    }
  }

  static Future<void> logout() async {
    await _clearTokens();
    await UserInfoManager.clearUserInfo();
  }
}