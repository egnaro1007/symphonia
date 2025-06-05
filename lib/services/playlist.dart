import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:symphonia/models/playlist.dart';
import 'package:http/http.dart' as http;
import 'package:symphonia/models/song.dart';
import 'package:symphonia/services/song.dart';
import 'package:symphonia/services/spotify_token.dart';
import 'package:symphonia/services/token_manager.dart';

class PlayListOperations {
  PlayListOperations._();

  static Future<List<BriefPlayList>> getPlaylists() async {
    try {
      final username = 'midnightstudios'; // 'chilledcow';
      final limit = 10;
      final offset = 0;
      final token = await SpotifyToken.getTokens();
      final url = Uri.parse(
        'https://api.spotify.com/v1/users/$username/playlists?limit=$limit&offset=$offset',
      );
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
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

          playlists.add(
            BriefPlayList(
              id: playlist['id'],
              title: playlist['name'],
              picture: playlist['images'][0]['url'],
              creator: 'symphonia', // playlist['user']['name'],
            ),
          );
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
        headers: {"Authorization": "Bearer $token"},
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

          songs.add(
            Song(
              // rank: songID.toString(),
              title: track['track']['name'],
              artist: track['track']['artists']
                  .map((artist) => artist['name'])
                  .join(', '),
              imagePath: track['track']['album']['images'][0]['url'],
              audioUrl: "",
            ),
          );
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
        description:
            '#symchart là BXH thời gian thực của Symphonia, được cập nhật hàng giờ.',
        duration: 3600,
        picture:
            'https://as2.ftcdn.net/v2/jpg/01/43/42/83/1000_F_143428338_gcxw3Jcd0tJpkvvb53pfEztwtU9sxsgT.jpg',
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
      final url = Uri.parse(
        '$serverUrl/api/library/playlists/',
      ); // Removed trailing slash
      print("Url: $url");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${TokenManager.accessToken}",
          "Content-Type": "application/json", // Added content type header
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

  // Delete playlist
  static Future<bool> deletePlaylist(String id) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      final url = Uri.parse(
        '$serverUrl/api/library/playlists/$id/',
      ); // Removed trailing slash
      print("Url: $url");

      final response = await http.delete(
        url,
        headers: {"Authorization": "Bearer ${TokenManager.accessToken}"},
      );

      print("Response: $response");

      if (response.statusCode == 204) {
        return true;
      } else {
        print('Failed to delete playlist: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error deleting playlist: $e');
      return false;
    }
  }

  static Future<List<PlayList>> getLocalPlaylists() async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      final url = Uri.parse('$serverUrl/api/library/playlists/');
      print("Url: $url");
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${TokenManager.accessToken}'},
      );

      print("Response: $response");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("Data: $data");
        List<PlayList> playlists = [];
        for (var playlist in data) {
          playlists.add(
            PlayList(
              id: playlist['id'].toString(),
              title: playlist['name'],
              description: playlist['description'],
              duration:
                  playlist['total_duration_seconds'] ??
                  0, // Use duration from API
              picture:
                  'https://wallpapers.com/images/featured/picture-en3dnh2zi84sgt3t.jpg', //playlist['picture'],
              creator:
                  playlist['owner_name'] ??
                  'Unknown', // Use owner_name from API
              songs: [],
              sharePermission:
                  playlist['share_permission'] ??
                  'private', // Added share permission
            ),
          );
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
        headers: {'Authorization': 'Bearer ${TokenManager.accessToken}'},
      );

      print("Response: $response");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print("Data: $data");

        var playlist = PlayList(
          id: data['id'].toString(),
          title: data['name'],
          description: data['description'],
          duration:
              data['total_duration_seconds'] ?? 0, // Use duration from API
          picture: '',
          //playlist['picture'],
          creator: data['owner_name'] ?? 'Unknown', // Use owner_name from API
          songs: [],
          sharePermission:
              data['share_permission'] ?? 'private', // Added share permission
        );

        // Parse songs if they exist in the response
        if (data['songs'] != null && data['songs'] is List) {
          for (var song in data['songs']) {
            int id = song['id'];
            print("Processing song: ${song['title']} (ID: $id)");
            print("Available fields: ${song.keys}");
            print("Audio field value: ${song['audio']}");
            print("Cover art field value: ${song['cover_art']}");

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
              String baseUrl = serverUrl;
              if (!baseUrl.startsWith('http://') &&
                  !baseUrl.startsWith('https://')) {
                baseUrl = 'http://$baseUrl';
              }
              audioUrl = '$baseUrl/api/library/songs/$id/';
              print("Audio field empty, using fallback URL: $audioUrl");
            } else {
              print("Using audio URL from API: $audioUrl");
            }

            // Handle cover art similar to audio URL
            String imagePath = song['cover_art'] ?? '';
            if (imagePath.isEmpty) {
              // Use default placeholder
              imagePath =
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/Image_created_with_a_mobile_phone.png/1280px-Image_created_with_a_mobile_phone.png';
              print("Cover art field empty, using placeholder image");
            } else if (!imagePath.startsWith('http://') &&
                !imagePath.startsWith('https://')) {
              // If cover_art is a relative path, build full URL
              String baseUrl = serverUrl;
              if (!baseUrl.startsWith('http://') &&
                  !baseUrl.startsWith('https://')) {
                baseUrl = 'http://$baseUrl';
              }
              imagePath = '$baseUrl$imagePath';
              print(
                "Cover art is relative path, building full URL: $imagePath",
              );
            } else {
              print("Using cover art URL from API: $imagePath");
            }

            playlist.songs.add(
              Song(
                id: id,
                title: song['title'],
                artist: artist,
                imagePath: imagePath,
                audioUrl: audioUrl,
                durationSeconds:
                    song['duration_seconds'] ?? 0, // Parse duration from API
              ),
            );
          }
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
          creator: 'Unknown', // Fallback value
          //playlist['creator'],
          songs: [],
          sharePermission: 'private', // Added share permission
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
        creator: 'Unknown', // Fallback value
        songs: [],
        sharePermission: 'private', // Added share permission
      ); // Fallback to mock data
    }
  }

  static Future<bool> addSongToPlaylist(
    String playlistID,
    String songID,
  ) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      final url = Uri.parse('$serverUrl/api/library/add-song-to-playlist/');
      print("Url: $url");

      print("Song ID: $songID");
      print("Playlist ID: $playlistID");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${TokenManager.accessToken}",
          "Content-Type": "application/json", // Added content type header
        },
        body: jsonEncode({'song_id': songID, 'playlist_id': playlistID}),
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

  // New method to get playlists of a specific user (friends/public only)
  static Future<List<PlayList>> getUserPlaylists(String userId) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      final url = Uri.parse('$serverUrl/api/library/user-playlists/$userId/');
      print("Fetching user playlists from: $url");
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${TokenManager.accessToken}'},
      );

      print("Response: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("User playlists data: $data");
        List<PlayList> playlists = [];
        for (var playlist in data) {
          // Only include playlists that are friends or public
          String sharePermission = playlist['share_permission'] ?? 'private';
          if (sharePermission == 'friends' || sharePermission == 'public') {
            playlists.add(
              PlayList(
                id: playlist['id'].toString(),
                title: playlist['name'],
                description: playlist['description'] ?? '',
                duration: 0,
                picture:
                    playlist['picture'] ??
                    'https://wallpapers.com/images/featured/picture-en3dnh2zi84sgt3t.jpg',
                creator: playlist['creator'] ?? 'Unknown',
                songs: [],
                sharePermission: sharePermission,
              ),
            );
          }
        }

        return playlists;
      } else {
        print('Failed to load user playlists: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching user playlists: $e');
      return []; // Return empty list on error
    }
  }
}
