import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class SpotifyToken {
  SpotifyToken._();

  static Future<String> getTokens() async {
    String clientId = dotenv.env['CLIENT_ID'] ?? '';
    String clientSecret = dotenv.env['CLIENT_SECRET'] ?? '';


    String urlStringBasic = 'https://accounts.spotify.com/api/token';

    String market = 'VN'; // Thay đổi mã quốc gia tại đây
    String urlString = '$urlStringBasic?market=$market';

    try {
      final response = await http.post(
        Uri.parse(urlString),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
        },
        body: {'grant_type': 'client_credentials'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String accessToken = data['access_token'];

        return accessToken;
      } else {
        throw Exception('Failed to get access token');
      }
    } catch (e) {
      return "";
    }
  }
}