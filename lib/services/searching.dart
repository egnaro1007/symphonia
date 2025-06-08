import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:symphonia/services/spotify_token.dart';
import 'package:symphonia/services/token_manager.dart';
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
      if (token.isEmpty) {
        print('No Spotify token available for suggestions');
        return [];
      }

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> suggestions = [];

        // Handle tracks
        if (data['tracks'] != null &&
            data['tracks']['items'] != null &&
            data['tracks']['items'] is List) {
          for (var track in data['tracks']['items']) {
            if (track != null && track['name'] != null) {
              suggestions.add(track['name'].toString());
            }
          }
        }

        // Handle artists
        if (data['artists'] != null &&
            data['artists']['items'] != null &&
            data['artists']['items'] is List) {
          for (var artist in data['artists']['items']) {
            if (artist != null && artist['name'] != null) {
              suggestions.add(artist['name'].toString());
            }
          }
        }

        // Handle albums
        if (data['albums'] != null &&
            data['albums']['items'] != null &&
            data['albums']['items'] is List) {
          for (var album in data['albums']['items']) {
            if (album != null && album['name'] != null) {
              suggestions.add(album['name'].toString());
            }
          }
        }

        // Remove duplicates and return
        return suggestions.toSet().toList();
      } else {
        print('Failed to load suggestions: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error in searchSuggestions: $e');
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

    print('Search URI: $uri'); // Debug log

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${TokenManager.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      print('Search response status: ${response.statusCode}'); // Debug log
      print('Search response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('Parsed search data: $data'); // Debug log

        // Check if songs exist in response
        if (data['songs'] != null) {
          print('Songs found: ${data['songs'].length}'); // Debug log
          for (var song in data['songs']) {
            print(
              'Processing song: ID=${song['id']}, Title=${song['title']}',
            ); // Debug log

            try {
              // Handle artist parsing more carefully - only get name, ignore bio
              String artistName = '';
              if (song['artist'] != null) {
                print(
                  'Artist data exists, type: ${song['artist'].runtimeType}',
                ); // Debug log
                if (song['artist'] is List) {
                  try {
                    print(
                      'Processing artist list with ${song['artist'].length} items',
                    ); // Debug log
                    List<String> artistNames = [];
                    for (var artist in song['artist']) {
                      print(
                        'Processing artist item: ${artist.runtimeType}',
                      ); // Debug log
                      if (artist is Map && artist['name'] != null) {
                        String name = artist['name'].toString().trim();
                        print('Found artist name: "$name"'); // Debug log
                        if (name.isNotEmpty) {
                          artistNames.add(name);
                        }
                      } else {
                        print('Artist item invalid: $artist'); // Debug log
                      }
                    }
                    artistName = artistNames.join(', ');
                    print('Final artist name: "$artistName"'); // Debug log
                    if (artistName.isEmpty) {
                      artistName = 'Unknown Artist';
                    }
                  } catch (e) {
                    print('Error parsing artist list: $e');
                    artistName = 'Unknown Artist';
                  }
                } else if (song['artist'] is String) {
                  artistName = song['artist'].toString().trim();
                  print('Artist is string: "$artistName"'); // Debug log
                } else {
                  print('Unknown artist format: ${song['artist']}');
                  artistName = 'Unknown Artist';
                }
              } else {
                print('No artist data found'); // Debug log
                artistName = 'Unknown Artist';
              }

              print(
                'About to create SongSearchResult with artist: "$artistName"',
              ); // Debug log

              // Handle audio URL safely
              String audioUrl = '';
              if (song['audio'] != null &&
                  song['audio'].toString().isNotEmpty) {
                audioUrl = serverUrl + song['audio'];
              } else {
                // Try to get from audio_urls if available
                if (song['audio_urls'] != null && song['audio_urls'] is Map) {
                  Map<String, dynamic> audioUrls = song['audio_urls'];
                  // Prefer higher quality first
                  if (audioUrls['320kbps'] != null) {
                    audioUrl = serverUrl + audioUrls['320kbps'];
                  } else if (audioUrls['128kbps'] != null) {
                    audioUrl = serverUrl + audioUrls['128kbps'];
                  } else if (audioUrls['lossless'] != null) {
                    audioUrl = serverUrl + audioUrls['lossless'];
                  } else if (audioUrls['legacy'] != null) {
                    audioUrl = serverUrl + audioUrls['legacy'];
                  }
                }
              }

              print('Audio URL: "$audioUrl"'); // Debug log

              results.add(
                SongSearchResult(
                  id: song['id'],
                  name: song['title'],
                  artist: artistName,
                  image:
                      song['cover_art'] != null && song['cover_art'].isNotEmpty
                          ? serverUrl + song['cover_art']
                          : '',
                  audio_url: audioUrl,
                ),
              );
              print(
                'Successfully created SongSearchResult for: ${song['title']} by $artistName',
              );
            } catch (e) {
              print('ERROR parsing song: ${e.toString()}');
              print('Song data that caused error: $song');
            }
          }
        } else {
          print('No songs found in response'); // Debug log
        }

        // Check if artists exist in response
        if (data['artists'] != null) {
          print('Artists found: ${data['artists'].length}'); // Debug log
          for (var artist in data['artists']) {
            String artistImage = artist['artist_picture'] ?? '';
            // Process artist picture URL to make it full URL
            if (artistImage.isNotEmpty &&
                !artistImage.startsWith('http://') &&
                !artistImage.startsWith('https://')) {
              artistImage = serverUrl + artistImage;
            }

            results.add(
              ArtistSearchResult(
                id: artist['id'],
                name: artist['name'],
                image: artistImage,
              ),
            );
          }
        } else {
          print('No artists found in response'); // Debug log
        }

        // Check if albums exist in response
        if (data['albums'] != null) {
          print('Albums found: ${data['albums'].length}'); // Debug log
          for (var song in data['albums']) {
            try {
              DateTime? releaseDate;
              if (song['release_date'] != null) {
                releaseDate = DateTime.parse(song['release_date']);
              }

              // Handle artist parsing more carefully - only get name, ignore bio
              String artistName = '';
              if (song['artist'] != null) {
                if (song['artist'] is List) {
                  try {
                    List<String> artistNames = [];
                    for (var artist in song['artist']) {
                      if (artist is Map && artist['name'] != null) {
                        String name = artist['name'].toString().trim();
                        if (name.isNotEmpty) {
                          artistNames.add(name);
                        }
                      }
                    }
                    artistName = artistNames.join(', ');
                    if (artistName.isEmpty) {
                      artistName = 'Unknown Artist';
                    }
                  } catch (e) {
                    print('Error parsing artist list: $e');
                    artistName = 'Unknown Artist';
                  }
                } else if (song['artist'] is String) {
                  artistName = song['artist'].toString().trim();
                } else {
                  print('Unknown album artist format: ${song['artist']}');
                  artistName = 'Unknown Artist';
                }
              } else {
                artistName = 'Unknown Artist';
              }

              results.add(
                AlbumSearchResult(
                  id: song['id'],
                  name: song['title'],
                  artist: artistName,
                  image:
                      song['cover_art'] != null && song['cover_art'].isNotEmpty
                          ? serverUrl + song['cover_art']
                          : '',
                  releaseDate: releaseDate,
                ),
              );
              print(
                'Successfully created AlbumSearchResult for: ${song['title']}',
              );
            } catch (e) {
              print('Error parsing album: $song, error: $e');
            }
          }
        } else {
          print('No albums found in response'); // Debug log
        }
      } else {
        print('Search failed with status: ${response.statusCode}'); // Debug log
        print('Error response: ${response.body}'); // Debug log
      }

      print('Total search results: ${results.length}'); // Debug log
      return results;
    } catch (e) {
      print('Search error: $e'); // Debug log
      return [];
    }
  }

  // New method to get raw song data for proper Song object creation
  static Future<Map<String, dynamic>?> getRawSearchData(String word) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    final String encodedWord = Uri.encodeComponent(word);
    final int maxResults = 5;

    final uri = Uri.parse(
      '$serverUrl/api/library/search/?query=$encodedWord&max_results=$maxResults',
    );

    print('Raw search URI: $uri'); // Debug log

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${TokenManager.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      print('Raw search response status: ${response.statusCode}'); // Debug log

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Raw search data: $data'); // Debug log
        return data;
      } else {
        print(
          'Raw search failed with status: ${response.statusCode}',
        ); // Debug log
        print('Raw search error response: ${response.body}'); // Debug log
      }
      return null;
    } catch (e) {
      print('Raw search error: $e'); // Debug log
      return null;
    }
  }

  static Future<List<SongSearchResult>> getSongSearchResults(
    String word,
  ) async {
    if (word.isEmpty) return [];

    try {
      final String encodedWord = Uri.encodeComponent(word);
      final token = await SpotifyToken.getTokens();

      if (token.isEmpty) {
        print('No Spotify token available for song search');
        return [];
      }

      final url = Uri.parse(
        'https://api.spotify.com/v1/search?q=$encodedWord&type=track&limit=10',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['tracks'] == null ||
            data['tracks']['items'] == null ||
            data['tracks']['items'] is! List) {
          return [];
        }

        var trackData = data['tracks']['items'] as List;
        List<SongSearchResult> songs = [];

        for (var track in trackData) {
          if (track == null) continue;

          try {
            // Safely get artist names
            String artistNames = '';
            if (track['artists'] != null && track['artists'] is List) {
              List<String> names = [];
              for (var artist in track['artists']) {
                if (artist != null && artist['name'] != null) {
                  names.add(artist['name'].toString());
                }
              }
              artistNames = names.join(', ');
            }

            // Safely get image URL
            String imageUrl = '';
            if (track['album'] != null &&
                track['album']['images'] != null &&
                track['album']['images'] is List &&
                (track['album']['images'] as List).isNotEmpty &&
                track['album']['images'][0] != null &&
                track['album']['images'][0]['url'] != null) {
              imageUrl = track['album']['images'][0]['url'].toString();
            }

            songs.add(
              SongSearchResult(
                id: track['id'] ?? '',
                name: track['name']?.toString() ?? 'Unknown Song',
                artist: artistNames.isNotEmpty ? artistNames : 'Unknown Artist',
                image: imageUrl,
                audio_url: '', // Spotify doesn't provide actual audio URLs
              ),
            );
          } catch (e) {
            print('Error processing track: $e');
            continue;
          }
        }
        return songs;
      } else {
        print('Failed to load songs: ${response.statusCode}');
        print('Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error in getSongSearchResults: $e');
      return [];
    }
  }

  static Future<List<ArtistSearchResult>> getArtistSearchResults(
    String word,
  ) async {
    if (word.isEmpty) return [];

    try {
      final String encodedWord = Uri.encodeComponent(word);
      final token = await SpotifyToken.getTokens();

      if (token.isEmpty) {
        print('No Spotify token available for artist search');
        return [];
      }

      final url = Uri.parse(
        'https://api.spotify.com/v1/search?q=$encodedWord&type=artist&limit=10',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['artists'] == null ||
            data['artists']['items'] == null ||
            data['artists']['items'] is! List) {
          return [];
        }

        var artistData = data['artists']['items'] as List;
        List<ArtistSearchResult> artists = [];

        for (var artist in artistData) {
          if (artist == null) continue;

          try {
            // Safely get image URL
            String imageUrl = '';
            if (artist['images'] != null &&
                artist['images'] is List &&
                (artist['images'] as List).isNotEmpty &&
                artist['images'][0] != null &&
                artist['images'][0]['url'] != null) {
              imageUrl = artist['images'][0]['url'].toString();
            }

            artists.add(
              ArtistSearchResult(
                id: artist['id'] ?? '',
                name: artist['name']?.toString() ?? 'Unknown Artist',
                image: imageUrl,
              ),
            );
          } catch (e) {
            print('Error processing artist: $e');
            continue;
          }
        }
        return artists;
      } else {
        print('Failed to load artists: ${response.statusCode}');
        print('Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error in getArtistSearchResults: $e');
      return [];
    }
  }

  static Future<List<PlaylistSearchResult>> getPlaylistSearchResults(
    String word,
  ) async {
    if (word.isEmpty) return [];

    try {
      final String encodedWord = Uri.encodeComponent(word);
      final token = await SpotifyToken.getTokens();

      if (token.isEmpty) {
        print('No Spotify token available for playlist search');
        return [];
      }

      final url = Uri.parse(
        'https://api.spotify.com/v1/search?q=$encodedWord&type=playlist&limit=10',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['playlists'] == null ||
            data['playlists']['items'] == null ||
            data['playlists']['items'] is! List) {
          return [];
        }

        var playlistData = data['playlists']['items'] as List;
        List<PlaylistSearchResult> playlists = [];

        for (var playlist in playlistData) {
          if (playlist == null) continue;

          try {
            // Safely get image URL
            String imageUrl = '';
            if (playlist['images'] != null &&
                playlist['images'] is List &&
                (playlist['images'] as List).isNotEmpty &&
                playlist['images'][0] != null &&
                playlist['images'][0]['url'] != null) {
              imageUrl = playlist['images'][0]['url'].toString();
            }

            // Safely get owner name
            String ownerName = '';
            if (playlist['owner'] != null &&
                playlist['owner']['display_name'] != null) {
              ownerName = playlist['owner']['display_name'].toString();
            }

            playlists.add(
              PlaylistSearchResult(
                id: playlist['id'] ?? '',
                name: playlist['name']?.toString() ?? 'Unknown Playlist',
                image: imageUrl,
                artist: ownerName.isNotEmpty ? ownerName : 'Unknown Owner',
              ),
            );
          } catch (e) {
            print('Error processing playlist: $e');
            continue;
          }
        }
        return playlists;
      } else {
        print('Failed to load playlists: ${response.statusCode}');
        print('Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error in getPlaylistSearchResults: $e');
      return [];
    }
  }
}
