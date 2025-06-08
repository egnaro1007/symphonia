import 'dart:convert';
import 'dart:math';

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
      // Try to get 9 random songs for suggestions
      final response = await http.get(
        Uri.parse('$serverUrl/api/library/songs/random?limit=9'),
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
      } else if (response.statusCode == 404) {
        // Fallback: If random endpoint doesn't exist, get all songs and shuffle locally
        print('Random endpoint not available, using fallback...');
        return await _getAllSongsAndShuffle();
      } else {
        print('Failed to load songs: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error: $e');
      // Fallback: Try to get all songs and shuffle locally
      print('Attempting fallback method...');
      try {
        return await _getAllSongsAndShuffle();
      } catch (fallbackError) {
        print('Fallback error: $fallbackError');
        return [];
      }
    }
  }

  static Future<List<Song>> _getAllSongsAndShuffle() async {
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

        // Shuffle the songs and take first 9
        songs.shuffle();
        return songs.take(9).toList();
      } else {
        print('Failed to load songs from fallback');
        return [];
      }
    } catch (e) {
      print('Fallback error: $e');
      return [];
    }
  }
}
