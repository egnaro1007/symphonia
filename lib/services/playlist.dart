import 'dart:convert';

import 'package:symphonia/models/playlist.dart';
import 'package:http/http.dart' as http;
import 'package:symphonia/models/song.dart';

class PlayListOperations {
  PlayListOperations._();

  static Future<List<BriefPlayList>> getPlaylists() async {
    // fetch this link: https://api.deezer.com/chart
    final url = Uri.parse('https://api.deezer.com/chart');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Parse the JSON response
        final data = jsonDecode(response.body);
        var playlistData = data['playlists']['data'];

        // for all JSON in JSONArray songData
        List<BriefPlayList> playlists = [];
        int maxPlaylists = 10;
        for (var playlist in playlistData) {
          if (playlists.length >= maxPlaylists) break; // Limit to 10 songs

          playlists.add(BriefPlayList(
            id: playlist['id'],
            title: playlist['title'],
            picture: playlist['picture'],
            creator: playlist['user']['name'],
          ));
        }

        return playlists;
      } else {
        throw Exception('Failed to load playlists');
      }
    } catch (e) {
      print(e);
      return [];
    }
  }

  static Future<PlayList> getPlaylist(int id) async {
    // fetch this link: https://api.deezer.com/playlist/{id}
    final url = Uri.parse('https://api.deezer.com/playlist/$id');

    print(url);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Parse the JSON response
        final data = jsonDecode(response.body);
        var playlistData = data;

        List<Song> songs = [];
        for (var song in playlistData['tracks']['data']) {
          songs.add(Song(
            rank: song['rank'].toString(),
            title: song['title'],
            artist: song['artist']['name'],
            imagePath: song['album']['cover'],
          ));
        }

        PlayList playlists = PlayList(
          id: playlistData['id'],
          title: playlistData['title'],
          description: playlistData['description'],
          duration: playlistData['duration'],
          picture: playlistData['picture'],
          creator: playlistData['creator']['name'],
          songs: songs,
        );

        return playlists;
      } else {
        throw Exception('Failed to load playlists');
      }
    } catch (e) {
      throw Exception('Failed to load playlists');
    }
  }
}