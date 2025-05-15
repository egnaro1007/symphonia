import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:symphonia/services/spotify_token.dart';

import '../models/song.dart';
import 'package:http/http.dart' as http;

class SongOperations {
  SongOperations._();

  static Future<List<Song>> getTrendingSongs() async {
    try {
      final id = '0aiBKNSqiPnhtcw1QlXK5s';
      final token = await SpotifyToken.getTokens();
      final url = Uri.parse('https://api.spotify.com/v1/playlists/$id/tracks');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        // Parse the JSON response
        final data = jsonDecode(response.body);
        var trackData = data['items'];

        // for all JSON in JSONArray songData
        List<Song> songs = [];
        int songID = 0;
        for (var track in trackData) {
          ++songID;
          if (songID > 20) break; // Limit to 10 songs

          songs.add(
            Song(
              // rank: songID.toString(),
              title: track['track']['name'],
              artist: track['track']['artists']
                  .map((artist) => artist['name'])
                  .join(', '),
              imagePath: track['track']['album']['images'][0]['url'],
              audioUrl: track['track']['preview_url'] ?? "",
            ),
          );
        }

        return songs;
      } else {
        throw Exception('Failed to load songs');
      }
    } catch (e) {
      print(e);
      return [];
    }
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
          songs.add(
            Song(
              title: song['title'],
              artist: song['artist'][0]['name'],
              imagePath:
                  song['cover_art'] ??
                  "https://pngimg.com/uploads/music_notes/music_notes_PNG46.png",
              audioUrl: song['audio'],
            ),
          );
        }

        return songs;
      } else {
        throw Exception('Failed to load songs');
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }
}

void main() async {
  List<Song> songs = await SongOperations.getTrendingSongs();
  for (var song in songs) {
    print(
      'Song: ${song.title}, Artist: ${song.artist}, Image: ${song.imagePath}',
    );
  }
}
