import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:symphonia/models/song.dart';
import 'package:symphonia/services/token_manager.dart';
import 'package:symphonia/services/data_event_manager.dart';

class HistoryOperations {
  HistoryOperations._();

  static Future<List<Song>> getRecentlyPlayedSongs() async {
    String? serverUrl = dotenv.env['SERVER_URL'];
    if (serverUrl == null) {
      print("Error: SERVER_URL is not defined in the environment variables.");
      return [];
    }

    try {
      final url = Uri.parse('$serverUrl/api/library/history/');

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

        for (dynamic historyData in data) {
          var songData = historyData['song'];
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

  static Future<bool> addToHistory(int songId, {int position = 0}) async {
    String? serverUrl = dotenv.env['SERVER_URL'];
    if (serverUrl == null) {
      print("Error: SERVER_URL is not defined in the environment variables.");
      return false;
    }

    try {
      final url = Uri.parse('$serverUrl/api/library/update-position/');

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${TokenManager.accessToken}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({'song_id': songId, 'position': position}),
      );

      bool success = response.statusCode == 200 || response.statusCode == 201;
      if (success) {
        DataEventManager.instance.notifyHistoryChanged(songId: songId);
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeFromHistory(int songId) async {
    String? serverUrl = dotenv.env['SERVER_URL'];
    if (serverUrl == null) {
      print("Error: SERVER_URL is not defined in the environment variables.");
      return false;
    }

    try {
      final url = Uri.parse('$serverUrl/api/library/update-position/');

      final response = await http.delete(
        url,
        headers: {
          "Authorization": "Bearer ${TokenManager.accessToken}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({'song_id': songId}),
      );

      bool success = response.statusCode == 204;
      if (success) {
        DataEventManager.instance.notifyHistoryChanged(songId: songId);
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}
