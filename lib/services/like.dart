import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:symphonia/models/song.dart';
import 'package:symphonia/services/token_manager.dart';
import 'package:symphonia/services/data_event_manager.dart';

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
      } else {
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

      bool success = response.statusCode == 200;
      if (success) {
        DataEventManager.instance.notifyLikeChanged(songId: song.id);
      } else {}
      return success;
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

      bool success = response.statusCode == 200;
      if (success) {
        DataEventManager.instance.notifyLikeChanged(songId: song.id);
      } else {}
      return success;
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

  static Future<List<Song>> getLikeSongs() async {
    String? serverUrl = dotenv.env['SERVER_URL'];
    if (serverUrl == null) {
      print("Error: SERVER_URL is not defined in the environment variables.");
      return [];
    }

    try {
      final url = Uri.parse('$serverUrl/api/library/like/');

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${TokenManager.accessToken}",
          "Content-Type": "application/json",
        },
      );

      final List<Song> songs = [];
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        for (dynamic songData in data) {
          // Process relative URLs to full URLs (similar to SongOperations)
          String serverBase = serverUrl;
          if (!serverBase.startsWith('http://') &&
              !serverBase.startsWith('https://')) {
            serverBase = 'http://$serverBase';
          }

          // Process cover_art URL
          if (songData['cover_art'] != null &&
              songData['cover_art'].toString().isNotEmpty &&
              !songData['cover_art'].toString().startsWith('http://') &&
              !songData['cover_art'].toString().startsWith('https://')) {
            songData['cover_art'] = '$serverBase${songData['cover_art']}';
          }

          // Process audio URLs in audio_urls map
          if (songData['audio_urls'] != null) {
            Map<String, dynamic> audioUrls = Map<String, dynamic>.from(
              songData['audio_urls'],
            );
            audioUrls.forEach((key, value) {
              if (value != null &&
                  value.toString().isNotEmpty &&
                  !value.toString().startsWith('http://') &&
                  !value.toString().startsWith('https://')) {
                audioUrls[key] = '$serverBase$value';
              }
            });
            songData['audio_urls'] = audioUrls;
          }

          // Process legacy audio URL
          if (songData['audio'] != null &&
              songData['audio'].toString().isNotEmpty &&
              !songData['audio'].toString().startsWith('http://') &&
              !songData['audio'].toString().startsWith('https://')) {
            songData['audio'] = '$serverBase${songData['audio']}';
          }

          // Use Song.fromJson to create Song objects with quality support
          songs.add(Song.fromJson(songData));
        }
      } else {
        print('Error: ${response.statusCode}');
      }

      return songs;
    } catch (e) {
      return [];
    }
  }
}
