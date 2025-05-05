import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TokenManager {
  static String? _accessToken;
  static String? _refreshToken;


  static Future<void> saveAccessToken(String token) async {
    _accessToken = token;
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/access_token.txt');
    await file.writeAsString(token);
  }

  static Future<void> loadAccessToken() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/access_token.txt');
    if (await file.exists()) {
      _accessToken = await file.readAsString();
    } else {
      _accessToken = null;
    }
  }

  static Future<void> saveRefreshToken(String token) async {
    _refreshToken = token;
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/refresh_token.txt');
    await file.writeAsString(token);
  }

  static Future<void> loadRefreshToken() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/refresh_token.txt');
    if (await file.exists()) {
      _refreshToken = await file.readAsString();
    } else {
      _refreshToken = null;
    }
  }

  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
  }


  static String? get accessToken => _accessToken;

  static String? get refreshToken => _refreshToken;


  static Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final directory = await getApplicationDocumentsDirectory();
    final accessFile = File('${directory.path}/access_token.txt');
    final refreshFile = File('${directory.path}/refresh_token.txt');
    if (await accessFile.exists()) {
      await accessFile.delete();
    }
    if (await refreshFile.exists()) {
      await refreshFile.delete();
    }
  }


  static Future<bool> verifyToken() async {
    await loadAccessToken();
    await loadRefreshToken();

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
        await saveAccessToken(newAccessToken);
        return true;
      }
    }

    return false;
  }

  static Future<void> login(String username, String password) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';

    final response = await http.post(
      Uri.parse('$serverUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data['access'];
      final refreshToken = data['refresh'];
      await saveTokens(accessToken, refreshToken);
    } else {
      throw Exception('Failed to login');
    }
  }

  static Future<void> logout() async {
    await clearTokens();
  }
}