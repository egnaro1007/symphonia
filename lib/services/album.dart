import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:symphonia/models/album.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/models/artist.dart';

class AlbumOperations {
  AlbumOperations._();

  // Get album by ID with songs
  static Future<Album> getAlbum(String id) async {
    // Validate ID before making API call
    if (id.isEmpty || id == "0") {
      throw Exception('Invalid album ID: $id');
    }

    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      final url = Uri.parse('$serverUrl/api/library/albums/$id/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final albumData = jsonDecode(response.body);

        // Process cover art URL
        if (albumData['cover_art'] != null &&
            albumData['cover_art'].isNotEmpty) {
          String coverArt = albumData['cover_art'];
          if (!coverArt.startsWith('http://') &&
              !coverArt.startsWith('https://')) {
            // Build full URL for relative paths
            String baseUrl = serverUrl;
            if (!baseUrl.startsWith('http://') &&
                !baseUrl.startsWith('https://')) {
              baseUrl = 'http://$baseUrl';
            }
            albumData['cover_art'] = '$baseUrl$coverArt';
          }
        }

        // Process songs cover art URLs if they exist
        if (albumData['songs'] != null && albumData['songs'] is List) {
          for (var songData in albumData['songs']) {
            if (songData['cover_art'] != null &&
                songData['cover_art'].isNotEmpty) {
              String coverArt = songData['cover_art'];
              if (!coverArt.startsWith('http://') &&
                  !coverArt.startsWith('https://')) {
                String baseUrl = serverUrl;
                if (!baseUrl.startsWith('http://') &&
                    !baseUrl.startsWith('https://')) {
                  baseUrl = 'http://$baseUrl';
                }
                songData['cover_art'] = '$baseUrl$coverArt';
              }
            }
          }
        }

        return Album.fromJson(albumData);
      } else {
        throw Exception('Failed to load album: ${response.statusCode}');
      }
    } catch (e) {
      print("Error getting album: $e");
      throw Exception('Failed to load album');
    }
  }

  // Get albums list
  static Future<List<Album>> getAlbums() async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      final url = Uri.parse('$serverUrl/api/library/albums/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> albumsData = jsonDecode(response.body);

        // Process cover art URLs for each album
        for (var albumData in albumsData) {
          if (albumData['cover_art'] != null &&
              albumData['cover_art'].isNotEmpty) {
            String coverArt = albumData['cover_art'];
            if (!coverArt.startsWith('http://') &&
                !coverArt.startsWith('https://')) {
              String baseUrl = serverUrl;
              if (!baseUrl.startsWith('http://') &&
                  !baseUrl.startsWith('https://')) {
                baseUrl = 'http://$baseUrl';
              }
              albumData['cover_art'] = '$baseUrl$coverArt';
            }
          }
        }

        return albumsData
            .map((albumData) => Album.fromJson(albumData))
            .toList();
      } else {
        throw Exception('Failed to load albums: ${response.statusCode}');
      }
    } catch (e) {
      print("Error getting albums: $e");
      throw Exception('Failed to load albums');
    }
  }

  // Get songs from album (through album detail API)
  static Future<List<Song>> getAlbumSongs(String albumId) async {
    try {
      // Get album details which includes songs
      Album album = await getAlbum(albumId);

      // If album songs don't have complete info, load full song details
      List<Song> completeSongs = [];
      String serverUrl = dotenv.env['SERVER_URL'] ?? '';

      for (Song song in album.songs) {
        if (song.artist.isEmpty || song.getAudioUrl().isEmpty) {
          // Load complete song details
          try {
            final url = Uri.parse('$serverUrl/api/library/songs/${song.id}/');
            final response = await http.get(url);

            if (response.statusCode == 200) {
              final songData = jsonDecode(response.body);

              // Process relative URLs to full URLs (similar to SongOperations)
              String serverBase = serverUrl;
              if (!serverBase.startsWith('http://') &&
                  !serverBase.startsWith('https://')) {
                serverBase = 'http://$serverBase';
              }

              // Process cover_art URL
              if (songData['cover_art'] != null &&
                  songData['cover_art'].toString().isNotEmpty &&
                  !songData['cover_art'].toString().startsWith('http://') &&
                  !songData['cover_art'].toString().startsWith('https://')) {
                songData['cover_art'] = '$serverBase${songData['cover_art']}';
              }

              // Process audio URLs in audio_urls map
              if (songData['audio_urls'] != null) {
                Map<String, dynamic> audioUrls = Map<String, dynamic>.from(
                  songData['audio_urls'],
                );
                audioUrls.forEach((key, value) {
                  if (value != null &&
                      value.toString().isNotEmpty &&
                      !value.toString().startsWith('http://') &&
                      !value.toString().startsWith('https://')) {
                    audioUrls[key] = '$serverBase$value';
                  }
                });
                songData['audio_urls'] = audioUrls;
              }

              // Process legacy audio URL
              if (songData['audio'] != null &&
                  songData['audio'].toString().isNotEmpty &&
                  !songData['audio'].toString().startsWith('http://') &&
                  !songData['audio'].toString().startsWith('https://')) {
                songData['audio'] = '$serverBase${songData['audio']}';
              }

              // Use Song.fromJson to create Song objects with quality support
              completeSongs.add(Song.fromJson(songData));
            } else {
              // If can't load full details, keep the basic song info
              completeSongs.add(song);
            }
          } catch (e) {
            print('Error loading song details for ${song.id}: $e');
            completeSongs.add(song);
          }
        } else {
          completeSongs.add(song);
        }
      }

      return completeSongs;
    } catch (e) {
      print("Error getting album songs: $e");
      throw Exception('Failed to load album songs');
    }
  }

  // Get albums by artist
  static Future<List<Album>> getAlbumsByArtist(String artistId) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      final url = Uri.parse('$serverUrl/api/library/artists/$artistId/albums/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> albumsData = jsonDecode(response.body);
        return albumsData
            .map((albumData) => Album.fromJson(albumData))
            .toList();
      } else {
        throw Exception('Failed to load artist albums: ${response.statusCode}');
      }
    } catch (e) {
      print("Error getting artist albums: $e");
      throw Exception('Failed to load artist albums');
    }
  }

  // Search albums (using the search endpoint)
  static Future<List<Album>> searchAlbums(String query) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      final url = Uri.parse('$serverUrl/api/library/search/?query=$query');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final searchData = jsonDecode(response.body);
        // Assuming search returns albums in 'albums' field
        if (searchData['albums'] != null) {
          final List<dynamic> albumsData = searchData['albums'];
          return albumsData
              .map((albumData) => Album.fromJson(albumData))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to search albums: ${response.statusCode}');
      }
    } catch (e) {
      print("Error searching albums: $e");
      throw Exception('Failed to search albums');
    }
  }

  // Create a simple album from search result for compatibility
  static Album createSimpleAlbum({
    required int id,
    required String title,
    required String artist,
    String? coverArt,
    DateTime? releaseDate,
  }) {
    return Album(
      id: id,
      title: title,
      artist: [Artist(id: 0, name: artist)],
      coverArt: coverArt,
      releaseDate: releaseDate,
      songs: [],
    );
  }
}
