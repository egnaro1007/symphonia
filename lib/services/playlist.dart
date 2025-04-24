import 'dart:convert';

import 'package:symphonia/models/playlist.dart';
import 'package:http/http.dart' as http;
import 'package:symphonia/models/song.dart';
import 'package:symphonia/services/song.dart';
import 'package:symphonia/services/spotify_token.dart';

class PlayListOperations {
  PlayListOperations._();

  static Future<List<BriefPlayList>> getPlaylists() async {
    try {
      final username = 'midnightstudios'; // 'chilledcow';
      final limit = 10;
      final offset = 0;
      final token = await SpotifyToken.getTokens();
      final url = Uri.parse('https://api.spotify.com/v1/users/$username/playlists?limit=$limit&offset=$offset');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        }
      );

      if (response.statusCode == 200) {
        // Parse the JSON response
        final data = jsonDecode(response.body);
        var playlistData = data['items'];

        // for all JSON in JSONArray songData
        List<BriefPlayList> playlists = [];
        int maxPlaylists = 10;
        for (var playlist in playlistData) {
          if (playlists.length >= maxPlaylists) break; // Limit to 10 songs

          playlists.add(BriefPlayList(
            id: playlist['id'],
            title: playlist['name'],
            picture: playlist['images'][0]['url'],
            creator: 'symphonia' // playlist['user']['name'],
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

  static Future<PlayList> getPlaylist(String id) async {
    if (id == "symchart") {
      return getTrendingPlaylist(id);
    }

    try {
      final token = await SpotifyToken.getTokens();
      final url = Uri.parse("https://api.spotify.com/v1/playlists/$id");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
        }
      );

      if (response.statusCode == 200) {
        // Parse the JSON response
        final data = jsonDecode(response.body);
        var playlistData = data;

        List<Song> songs = [];
        var songID = 0;
        int duration = 0;
        
        print("Data: $data");

        for (var track in playlistData['tracks']['items']) {
          ++songID;
          print("Song ID: $songID");

          duration += track['track']['duration_ms'] as int;

          songs.add(Song(
            // rank: songID.toString(),
            title: track['track']['name'],
            artist: track['track']['artists']
                .map((artist) => artist['name'])
                .join(', '),
            imagePath: track['track']['album']['images'][0]['url'],
            audioUrl: "",
          ));
        }

        PlayList playlists = PlayList(
          id: playlistData['id'],
          title: playlistData['name'],
          description: playlistData['description'],
          duration: duration,
          picture: playlistData['images'][0]['url'],
          creator: playlistData['owner']['display_name'],
          songs: songs,
        );

        return playlists;
      } else {
        throw Exception('Failed to load playlists');
      }
    } catch (e) {
      print("Error: $e");
      throw Exception('Failed to load playlists');
    }
  }

  static Future<PlayList> getTrendingPlaylist(String id) async {
    try {
      List<Song> songs = await SongOperations.getTrendingSongs();

      PlayList playlists = PlayList(
        id: '0aiBKNSqiPnhtcw1QlXK5s',
        title: '#symchart',
        description: '#symchart là BXH thời gian thực của Symphonia, được cập nhật hàng giờ.',
        duration: 3600,
        picture: 'https://as2.ftcdn.net/v2/jpg/01/43/42/83/1000_F_143428338_gcxw3Jcd0tJpkvvb53pfEztwtU9sxsgT.jpg',
        creator: 'Symphonia',
        songs: songs,
      );

      return playlists;
    } catch (e) {
      print("Error: $e");
      throw Exception('Failed to load playlists');
    }
  }
}