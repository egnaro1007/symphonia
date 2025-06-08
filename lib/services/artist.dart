import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:symphonia/models/artist.dart';
import 'package:symphonia/models/album.dart';
import 'package:symphonia/models/song.dart';

class ArtistOperations {
  ArtistOperations._();

  // Get all artists
  static Future<List<Artist>> getArtists() async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      final url = Uri.parse('$serverUrl/api/library/artists/');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> artistsData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        // Process artist picture URLs
        for (var artistData in artistsData) {
          if (artistData['artist_picture'] != null &&
              artistData['artist_picture'].isNotEmpty) {
            String artistPicture = artistData['artist_picture'];
            if (!artistPicture.startsWith('http://') &&
                !artistPicture.startsWith('https://')) {
              String baseUrl = serverUrl;
              if (!baseUrl.startsWith('http://') &&
                  !baseUrl.startsWith('https://')) {
                baseUrl = 'http://$baseUrl';
              }
              artistData['artist_picture'] = '$baseUrl$artistPicture';
            }
          }
        }

        return artistsData
            .map((artistData) => Artist.fromJson(artistData))
            .toList();
      } else {
        throw Exception('Failed to load artists: ${response.statusCode}');
      }
    } catch (e) {
      print("Error getting artists: $e");
      throw Exception('Failed to load artists');
    }
  }

  // Get artist by ID
  static Future<Artist> getArtist(String id) async {
    // Validate ID before making API call
    if (id.isEmpty || id == "0") {
      throw Exception('Invalid artist ID: $id');
    }

    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      final url = Uri.parse('$serverUrl/api/library/artists/$id/');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final artistData = jsonDecode(utf8.decode(response.bodyBytes));

        // Process artist picture URL
        if (artistData['artist_picture'] != null &&
            artistData['artist_picture'].isNotEmpty) {
          String artistPicture = artistData['artist_picture'];
          if (!artistPicture.startsWith('http://') &&
              !artistPicture.startsWith('https://')) {
            String baseUrl = serverUrl;
            if (!baseUrl.startsWith('http://') &&
                !baseUrl.startsWith('https://')) {
              baseUrl = 'http://$baseUrl';
            }
            artistData['artist_picture'] = '$baseUrl$artistPicture';
          }
        }

        return Artist.fromJson(artistData);
      } else {
        throw Exception('Failed to load artist: ${response.statusCode}');
      }
    } catch (e) {
      print("Error getting artist: $e");
      throw Exception('Failed to load artist');
    }
  }

  // Get artist albums (using the search endpoint to get albums by artist)
  static Future<List<Album>> getArtistAlbums(String artistId) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      // Get all albums first
      final url = Uri.parse('$serverUrl/api/library/albums/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> albumsData = jsonDecode(response.body);
        List<Album> artistAlbums = [];

        // Filter albums by artist ID
        for (var albumData in albumsData) {
          if (albumData['artist'] != null && albumData['artist'] is List) {
            List<dynamic> artists = albumData['artist'];
            bool hasArtist = artists.any(
              (artist) => artist['id'].toString() == artistId,
            );

            if (hasArtist) {
              // Process cover art URL
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

              artistAlbums.add(Album.fromJson(albumData));
            }
          }
        }

        return artistAlbums;
      } else {
        throw Exception('Failed to load artist albums: ${response.statusCode}');
      }
    } catch (e) {
      print("Error getting artist albums: $e");
      throw Exception('Failed to load artist albums');
    }
  }

  // Get artist songs (using the search endpoint or filtering all songs)
  static Future<List<Song>> getArtistSongs(String artistId) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      // Get all songs first
      final url = Uri.parse('$serverUrl/api/library/songs/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> songsData = jsonDecode(response.body);
        List<Song> artistSongs = [];

        // Filter songs by artist ID
        for (var songData in songsData) {
          if (songData['artist'] != null && songData['artist'] is List) {
            List<dynamic> artists = songData['artist'];
            bool hasArtist = artists.any(
              (artist) => artist['id'].toString() == artistId,
            );

            if (hasArtist) {
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
              artistSongs.add(Song.fromJson(songData));
            }
          }
        }

        return artistSongs;
      } else {
        throw Exception('Failed to load artist songs: ${response.statusCode}');
      }
    } catch (e) {
      print("Error getting artist songs: $e");
      throw Exception('Failed to load artist songs');
    }
  }

  // Search artists by name
  static Future<List<Artist>> searchArtists(String query) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        '$serverUrl/api/library/search/?query=$encodedQuery',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final searchData = jsonDecode(response.body);

        if (searchData['artists'] != null) {
          final List<dynamic> artistsData = searchData['artists'];

          // Process artist picture URLs
          for (var artistData in artistsData) {
            if (artistData['artist_picture'] != null &&
                artistData['artist_picture'].isNotEmpty) {
              String artistPicture = artistData['artist_picture'];
              if (!artistPicture.startsWith('http://') &&
                  !artistPicture.startsWith('https://')) {
                String baseUrl = serverUrl;
                if (!baseUrl.startsWith('http://') &&
                    !baseUrl.startsWith('https://')) {
                  baseUrl = 'http://$baseUrl';
                }
                artistData['artist_picture'] = '$baseUrl$artistPicture';
              }
            }
          }

          return artistsData
              .map((artistData) => Artist.fromJson(artistData))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to search artists: ${response.statusCode}');
      }
    } catch (e) {
      print("Error searching artists: $e");
      throw Exception('Failed to search artists');
    }
  }

  // Get popular artists (returns first N artists for now - can be enhanced later)
  static Future<List<Artist>> getPopularArtists({int limit = 10}) async {
    try {
      List<Artist> allArtists = await getArtists();
      return allArtists.take(limit).toList();
    } catch (e) {
      print("Error getting popular artists: $e");
      throw Exception('Failed to load popular artists');
    }
  }

  // Get artist full URL for picture
  static String? getArtistPictureUrl(String? artistPicture) {
    if (artistPicture == null || artistPicture.isEmpty) {
      return null;
    }

    if (artistPicture.startsWith('http://') ||
        artistPicture.startsWith('https://')) {
      return artistPicture;
    }

    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
      serverUrl = 'http://$serverUrl';
    }

    return '$serverUrl$artistPicture';
  }

  // Create a simple artist object for compatibility
  static Artist createSimpleArtist({
    required int id,
    required String name,
    String? bio,
    String? artistPicture,
  }) {
    return Artist(id: id, name: name, bio: bio, artistPicture: artistPicture);
  }
}
