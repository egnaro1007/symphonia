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
