import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:symphonia/services/spotify_token.dart';
import 'package:http/http.dart' as http;

import '../models/search_result.dart';

class Searching {
  Searching._();

  // Mock function for search suggestions
  static List<String> searchSuggestions(String word) {
    // This would typically be an API call or database query
    if (word.toLowerCase().contains("sự")) {
      return [
        "sự nghiệp chướng",
        "sự thật sau một lời hứa",
        "sự thật đã bỏ quên"
      ];
    } else if (word.isEmpty) {
      return [];
    } else {
      // Return different suggestions for different searches
      return ["$word mới", "$word hay", "$word nổi tiếng"];
    }
  }

  static Future<List<SearchResult>> searchResults(String word) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    final String encodedWord = Uri.encodeComponent(word);
    final int maxResults = 5;

    List<SearchResult> results = [];

    final uri = Uri.parse(
        '$serverUrl/api/library/search/?query=$encodedWord&max_results=$maxResults');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        for (var song in data['songs']) {
          results.add(SongSearchResult(
            id: song['id'],
            name: song['title'],
            artist: song['artist']
                .map((artist) => artist['name'])
                .join(', '),
            image: song['cover_art'] ?? '',
            audio_url: song['audio']
          ));
        }

        for (var artist in data['artists']) {
          results.add(ArtistSearchResult(
              id: artist['id'],
              name: artist['name'],
              image: artist['artist_picture'] ?? ''
          ));
        }

        for (var song in data['albums']) {
          results.add(AlbumSearchResult(
              id: song['id'],
              name: song['title'],
              artist: song['artist']
                  .map((artist) => artist['name'])
                  .join(', '),
              image: song['cover_art'] ?? ''
          ));
        }
      }
      print (results);
      return results;
    }
    catch (e) {
      print(e);
      return [];
    }
  }

  static Future<List<SongSearchResult>> getSongSearchResults(String word) async {
    final String encodedWord = Uri.encodeComponent(word);
    final token = await SpotifyToken.getTokens();
    final url = Uri.parse(
        'https://api.spotify.com/v1/search?q=$encodedWord&type=track&limit=10');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var trackData = data['tracks']['items'];

        List<SongSearchResult> songs = [];
        for (var track in trackData) {
          songs.add(SongSearchResult(
            id: track['id'],
            name: track['name'],
            artist: track['artists']
                .map((artist) => artist['name'])
                .join(', '),
            image: track['album']['images'][0]['url'],
            audio_url: 'example.com',
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

  static Future<List<ArtistSearchResult>> getArtistSearchResults(String word) async {
    final String encodedWord = Uri.encodeComponent(word);
    final token = await SpotifyToken.getTokens();
    final url = Uri.parse(
        'https://api.spotify.com/v1/search?q=$encodedWord&type=artist&limit=10');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var artistData = data['artists']['items'];

        List<ArtistSearchResult> artists = [];
        for (var artist in artistData) {
          artists.add(ArtistSearchResult(
            id: artist['id'],
            name: artist['name'],
            image: artist['images'][0]['url'],
          ));
        }
        return artists;
      } else {
        throw Exception('Failed to load artists');
      }
    } catch (e) {
      print(e);
      return [];
    }
  }

  static Future<List<PlaylistSearchResult>> getPlaylistSearchResults(String word) async {
    final String encodedWord = Uri.encodeComponent(word);
    final token = await SpotifyToken.getTokens();
    final url = Uri.parse(
        'https://api.spotify.com/v1/search?q=$encodedWord&type=playlist&limit=10');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        var playlistData = data['playlists']['items'];

        List<PlaylistSearchResult> playlists = [];
        for (var playlist in playlistData) {
          if (playlist == null) {
            continue;
          }

          playlists.add(PlaylistSearchResult(
            id: playlist['id'],
            name: playlist['name'],
            image: playlist['images'][0]['url'],
            artist: playlist['owner']['display_name'],
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
}