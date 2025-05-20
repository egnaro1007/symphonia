import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:symphonia/models/song.dart';
import 'package:symphonia/services/token_manager.dart';

class LikeOperations {
  LikeOperations._();

  static Future<bool> getLikeStatus(Song song) async {
    String? serverUrl = dotenv.env['SERVER_URL'];
    if (serverUrl == null) {
      print("Error: SERVER_URL is not defined in the environment variables.");
      return false;
    }

    try {
      final url = Uri.parse('$serverUrl/api/library/like/${song.id}/');

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${TokenManager.accessToken}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['liked'] ?? false;
      }
      else {
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  static Future<bool> like(Song song) async {
    String? serverUrl = dotenv.env['SERVER_URL'];
    if (serverUrl == null) {
      print("Error: SERVER_URL is not defined in the environment variables.");
      return false;
    }

    try {
      final url = Uri.parse('$serverUrl/api/library/like/${song.id}/');

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${TokenManager.accessToken}",
          "Content-Type": "application/json",
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  static Future<bool> unlike(Song song) async {
    String? serverUrl = dotenv.env['SERVER_URL'];
    if (serverUrl == null) {
      print("Error: SERVER_URL is not defined in the environment variables.");
      return false;
    }

    try {
      final url = Uri.parse('$serverUrl/api/library/like/${song.id}/');

      final response = await http.delete(
        url,
        headers: {
          "Authorization": "Bearer ${TokenManager.accessToken}",
          "Content-Type": "application/json",
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  static Future<void> toggleLike(Song song, bool isLiked) async {
    if (isLiked) {
      await unlike(song);
    } else {
      await like(song);
    }
  }


}
