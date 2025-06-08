import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/song.dart';
import 'package:http/http.dart' as http;

class SongOperations {
  SongOperations._();

  static Future<List<Song>> getTrendingSongs() async {
    // Now returns local trending songs instead of Spotify data
    return getSuggestedSongs();
  }

  static Future<List<Song>> getSuggestedSongs() async {
    var serverUrl = dotenv.env['SERVER_URL'];

    try {
      final response = await http.get(
        Uri.parse('$serverUrl/api/library/songs'),
      );

      if (response.statusCode == 200) {
        var data = response.body;
        var jsonData = jsonDecode(data);

        List<Song> songs = [];
        for (var songJson in jsonData) {
          // Process relative URLs to full URLs
          String serverBase = serverUrl ?? '';
          if (!serverBase.startsWith('http://') &&
              !serverBase.startsWith('https://')) {
            serverBase = 'http://$serverBase';
          }

          // Process cover_art URL
          if (songJson['cover_art'] != null &&
              songJson['cover_art'].toString().isNotEmpty &&
              !songJson['cover_art'].toString().startsWith('http://') &&
              !songJson['cover_art'].toString().startsWith('https://')) {
            songJson['cover_art'] = '$serverBase${songJson['cover_art']}';
          }

          // Process audio URLs in audio_urls map
          if (songJson['audio_urls'] != null) {
            Map<String, dynamic> audioUrls = Map<String, dynamic>.from(
              songJson['audio_urls'],
            );
            audioUrls.forEach((key, value) {
              if (value != null &&
                  value.toString().isNotEmpty &&
                  !value.toString().startsWith('http://') &&
                  !value.toString().startsWith('https://')) {
                audioUrls[key] = '$serverBase$value';
              }
            });
            songJson['audio_urls'] = audioUrls;
          }

          // Process legacy audio URL
          if (songJson['audio'] != null &&
              songJson['audio'].toString().isNotEmpty &&
              !songJson['audio'].toString().startsWith('http://') &&
              !songJson['audio'].toString().startsWith('https://')) {
            songJson['audio'] = '$serverBase${songJson['audio']}';
          }

          // Use Song.fromJson to create Song objects with quality support
          songs.add(Song.fromJson(songJson));
        }

        return songs;
      } else {
        print('Failed to load songs');
        return [];
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }
}
