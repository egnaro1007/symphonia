import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:symphonia/services/spotify_token.dart';
import 'package:http/http.dart' as http;

import '../models/search_result.dart';

class Searching {
  Searching._();

  // Mock function for search suggestions
  static Future<List<String>> searchSuggestions(String word) async {
    if (word.isEmpty) {
      return [];
    }

    final String encodedWord = Uri.encodeComponent(word);
    final token = await SpotifyToken.getTokens();
    // Fetch a few of each type for a mix of suggestions
    final url = Uri.parse(
      'https://api.spotify.com/v1/search?q=$encodedWord&type=track,artist,album&limit=5',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> suggestions = [];

        if (data['tracks'] != null && data['tracks']['items'] != null) {
          for (var track in data['tracks']['items']) {
            if (track['name'] != null) {
              suggestions.add(track['name']);
            }
          }
        }

        if (data['artists'] != null && data['artists']['items'] != null) {
          for (var artist in data['artists']['items']) {
            if (artist['name'] != null) {
              suggestions.add(artist['name']);
            }
          }
        }

        if (data['albums'] != null && data['albums']['items'] != null) {
          for (var album in data['albums']['items']) {
            if (album['name'] != null) {
              suggestions.add(album['name']);
            }
          }
        }
        // Remove duplicates and return
        return suggestions.toSet().toList();
      } else {
        print('Failed to load suggestions: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<List<SearchResult>> searchResults(String word) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    final String encodedWord = Uri.encodeComponent(word);
    final int maxResults = 5;

    List<SearchResult> results = [];

    final uri = Uri.parse(
      '$serverUrl/api/library/search/?query=$encodedWord&max_results=$maxResults',
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        for (var song in data['songs']) {
          results.add(
            SongSearchResult(
              id: song['id'],
              name: song['title'],
              artist: song['artist'].map((artist) => artist['name']).join(', '),
              image:
                  song['cover_art'] != null && song['cover_art'].isNotEmpty
                      ? serverUrl + song['cover_art']
                      : '',
              audio_url: serverUrl + song['audio'],
            ),
          );
        }

        for (var artist in data['artists']) {
          results.add(
            ArtistSearchResult(
              id: artist['id'],
              name: artist['name'],
              image: artist['artist_picture'] ?? '',
            ),
          );
        }

        for (var song in data['albums']) {
          results.add(
            AlbumSearchResult(
              id: song['id'],
              name: song['title'],
              artist: song['artist'].map((artist) => artist['name']).join(', '),
              image: song['cover_art'] ?? '',
            ),
          );
        }
      }
      return results;
    } catch (e) {
      return [];
    }
  }

  static Future<List<SongSearchResult>> getSongSearchResults(
    String word,
  ) async {
    final String encodedWord = Uri.encodeComponent(word);
    final token = await SpotifyToken.getTokens();
    final url = Uri.parse(
      'https://api.spotify.com/v1/search?q=$encodedWord&type=track&limit=10',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var trackData = data['tracks']['items'];

        List<SongSearchResult> songs = [];
        for (var track in trackData) {
          songs.add(
            SongSearchResult(
              id: track['id'],
              name: track['name'],
              artist: track['artists']
                  .map((artist) => artist['name'])
                  .join(', '),
              image: track['album']['images'][0]['url'],
              audio_url: 'example.com',
            ),
          );
        }
        return songs;
      } else {
        throw Exception('Failed to load songs');
      }
    } catch (e) {
      return [];
    }
  }

  static Future<List<ArtistSearchResult>> getArtistSearchResults(
    String word,
  ) async {
    final String encodedWord = Uri.encodeComponent(word);
    final token = await SpotifyToken.getTokens();
    final url = Uri.parse(
      'https://api.spotify.com/v1/search?q=$encodedWord&type=artist&limit=10',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var artistData = data['artists']['items'];

        List<ArtistSearchResult> artists = [];
        for (var artist in artistData) {
          artists.add(
            ArtistSearchResult(
              id: artist['id'],
              name: artist['name'],
              image: artist['images'][0]['url'],
            ),
          );
        }
        return artists;
      } else {
        throw Exception('Failed to load artists');
      }
    } catch (e) {
      return [];
    }
  }

  static Future<List<PlaylistSearchResult>> getPlaylistSearchResults(
    String word,
  ) async {
    final String encodedWord = Uri.encodeComponent(word);
    final token = await SpotifyToken.getTokens();
    final url = Uri.parse(
      'https://api.spotify.com/v1/search?q=$encodedWord&type=playlist&limit=10',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        var playlistData = data['playlists']['items'];

        List<PlaylistSearchResult> playlists = [];
        for (var playlist in playlistData) {
          if (playlist == null) {
            continue;
          }

          playlists.add(
            PlaylistSearchResult(
              id: playlist['id'],
              name: playlist['name'],
              image: playlist['images'][0]['url'],
              artist: playlist['owner']['display_name'],
            ),
          );
        }
        return playlists;
      } else {
        throw Exception('Failed to load playlists');
      }
    } catch (e) {
      return [];
    }
  }
}
