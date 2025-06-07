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
        for (var song in jsonData) {
          // Parse artist information
          String artist = '';
          if (song['artist'] != null && song['artist'] is List) {
            List<dynamic> artists = song['artist'];
            if (artists.isNotEmpty) {
              // Join multiple artists with comma
              artist = artists
                  .map((a) => a['name'] ?? '')
                  .where((name) => name.isNotEmpty)
                  .join(', ');
            }
          }

          String audioUrl = song['audio'] ?? '';
          if (audioUrl.isEmpty) {
            // Fallback: try to build URL if audio field is empty
            // Ensure proper protocol
            String baseUrl = serverUrl ?? '';
            if (!baseUrl.startsWith('http://') &&
                !baseUrl.startsWith('https://')) {
              baseUrl = 'http://$baseUrl';
            }
            audioUrl = '$baseUrl/api/library/songs/${song['id']}/';
          } else {}

          // Handle cover art similar to audio URL
          String imagePath = song['cover_art'] ?? '';
          if (imagePath.isEmpty) {
            // Use default placeholder
            imagePath = '';
          } else if (!imagePath.startsWith('http://') &&
              !imagePath.startsWith('https://')) {
            // If cover_art is a relative path, build full URL
            String baseUrl = serverUrl ?? '';
            if (!baseUrl.startsWith('http://') &&
                !baseUrl.startsWith('https://')) {
              baseUrl = 'http://$baseUrl';
            }
            imagePath = '$baseUrl$imagePath';
          }

          songs.add(
            Song(
              id: song['id'],
              title: song['title'],
              artist: artist,
              imagePath: imagePath,
              audioUrl: audioUrl,
              durationSeconds: song['duration_seconds'] ?? 0, // Parse duration
            ),
          );
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
