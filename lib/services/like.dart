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
      } else {
      }
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
      } else {
      }
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
          int id = songData['id'];
          String title = songData['title'];
          String imagePath = songData['cover_art'] ?? '';
          String audio = songData['audio'] ?? '';
          int durationSeconds = songData['duration_seconds'] ?? 0;

          // Parse artist information
          String artist = '';
          if (songData['artist'] != null && songData['artist'] is List) {
            List<dynamic> artists = songData['artist'];
            if (artists.isNotEmpty) {
              // Join multiple artists with comma
              artist = artists
                  .map((a) => a['name'] ?? '')
                  .where((name) => name.isNotEmpty)
                  .join(', ');
            }
          }

          if (imagePath.isNotEmpty) {
            imagePath = '$serverUrl$imagePath';
          }
          if (audio.isNotEmpty) {
            audio = '$serverUrl$audio';
          }

          songs.add(
            Song(
              id: id,
              title: title,
              artist: artist,
              imagePath: imagePath,
              audioUrl: audio,
              durationSeconds: durationSeconds,
            ),
          );
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
