

import 'dart:convert';

import 'package:symphonia/services/spotify_token.dart';

import '../models/song.dart';
import 'package:http/http.dart' as http;

class SongOperations {
  SongOperations._();

  static Future<List<Song>> getSongs() async {
    try {
      final id = '0aiBKNSqiPnhtcw1QlXK5s';
      final token = await SpotifyToken.getTokens();
      final url = Uri.parse('https://api.spotify.com/v1/playlists/$id/tracks');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
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

          songs.add(Song(
            rank: songID.toString(),
            title: track['track']['name'],
            artist: track['track']['artists']
                    .map((artist) => artist['name'])
                    .join(', '),
            imagePath: track['track']['album']['images'][0]['url'],
          ));
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
}

void main() async {
  List<Song> songs = await SongOperations.getSongs();
  for (var song in songs) {
    print('Song: ${song.title}, Artist: ${song.artist}, Image: ${song.imagePath}');
  }
}