import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  // Add playlist
  static Future<bool> addPlaylist(String name, bool public) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      final url = Uri.parse('$serverUrl/api/library/playlists/');  // Removed trailing slash
        print("Url: $url");

        final response = await http.post(
          url,
          headers: {
            "Authorization": "Bearer ${dotenv.env['ACCESS_TOKEN']}",
            "Content-Type": "application/json",  // Added content type header
          },
          body: jsonEncode({
            'name': name,
            'description': 'Playlist is created by API',
            'songs': [],
            'share_permission': (public) ? 'public' : 'private',
          }),
        );

      print("Response: $response");

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Failed to add playlist: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error adding playlist: $e');
      return false;
    }
  }

  static Future<List<PlayList>> getLocalPlaylists() async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      final url = Uri.parse('$serverUrl/api/library/playlists');
      print("Url: $url");
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${dotenv.env['ACCESS_TOKEN']}',
        },
      );

      print("Response: $response");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("Data: $data");
        List<PlayList> playlists = [];
        for (var playlist in data) {
          playlists.add(PlayList(
            id: playlist['id'].toString(),
            title: playlist['name'],
            description: playlist['description'],
            duration: 0,
            picture: '', //playlist['picture'],
            creator: 'Thanh', //playlist['creator'],
            songs: []
          ));
        }

        return playlists;
      } else {
        print('Failed to load local playlists: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching local playlists: $e');
      return []; // Fallback to mock data
    }
  }

  static Future<PlayList> getLocalPlaylist(String id) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      final url = Uri.parse('$serverUrl/api/library/playlists/$id');
      print("Url: $url");
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${dotenv.env['ACCESS_TOKEN']}',
        },
      );

      print("Response: $response");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print("Data: $data");

        var playlist = PlayList(
            id: data['id'].toString(),
            title: data['name'],
            description: data['description'],
            duration: 0,
            picture: '',
            //playlist['picture'],
            creator: 'Thanh',
            //playlist['creator'],
            songs: []
        );

        for (var song in data['songs']) {
          int id = song['id'];

          playlist.songs.add(Song(
            title: song['title'],
            artist: song['artist'][0]['name'],
            imagePath: song['cover_art'] ?? 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/Image_created_with_a_mobile_phone.png/1280px-Image_created_with_a_mobile_phone.png',
            audioUrl: 'http://${dotenv.env['SERVER_URL']}/api/library/songs/$id/',
          ));
        }

        return playlist;
      } else {
        print('Failed to load local playlists: ${response.statusCode}');
        return PlayList(
            id: id,
            title: '',
            description: '',
            duration: 0,
            picture: '',
            //playlist['picture'],
            creator: 'Thanh',
            //playlist['creator'],
            songs: []
        );
      }
    } catch (e) {
      print('Error fetching local playlists: $e');
      return PlayList(
          id: id,
          title: '',
          description: '',
          duration: 0,
          picture: '',
          //playlist['picture'],
          creator: 'Thanh',
          //playlist['creator'],
          songs: []
      ); // Fallback to mock data
    }
  }

  static Future<bool> addSongToPlaylist(String playlistID, String songID) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      final url = Uri.parse('$serverUrl/api/library/add-song-to-playlist/');
      print("Url: $url");

      print("Song ID: $songID");
      print("Playlist ID: $playlistID");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${dotenv.env['ACCESS_TOKEN']}",
          "Content-Type": "application/json",  // Added content type header
        },
        body: jsonEncode({
          'song_id': songID,
          'playlist_id': playlistID,
        }),
      );

      print("Response: $response");

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('Failed to add song to playlist: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error adding song to playlist: $e');
      return false;
    }
  }
}