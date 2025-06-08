import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_parser/http_parser.dart';

import 'package:symphonia/models/playlist.dart';
import 'package:http/http.dart' as http;
import 'package:symphonia/models/song.dart';
import 'package:symphonia/services/song.dart';

import 'package:symphonia/services/token_manager.dart';

class PlayListOperations {
  PlayListOperations._();

  static Future<PlayList> getPlaylist(String id) async {
    if (id == "symchart") {
      return getTrendingPlaylist(id);
    }

    // This function now only handles local playlists
    return getLocalPlaylist(id);
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
    String sharePermission = public ? 'public' : 'private';
    return await addPlaylistWithPermission(name, sharePermission);
  }

  // Add playlist with specific permission string
  static Future<bool> addPlaylistWithPermission(
    String name,
    String sharePermission,
  ) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      // Load tokens first to ensure we have valid authentication
      await TokenManager.loadTokens();

      if (TokenManager.accessToken == null) {
        print('No access token available');
        return false;
      }

      final url = Uri.parse(
        '$serverUrl/api/library/playlists/',
      ); // Removed trailing slash
      print("Url: $url");
      print("Using token: ${TokenManager.accessToken?.substring(0, 20)}...");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${TokenManager.accessToken}",
          "Content-Type": "application/json", // Added content type header
        },
        body: jsonEncode({
          'name': name,
          'description': 'Playlist is created by API',
          'share_permission': sharePermission,
        }),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

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

  // Add playlist and return playlist data (improved version)
  static Future<Map<String, dynamic>?> addPlaylistWithData(
    String name,
    bool public,
  ) async {
    String sharePermission = public ? 'public' : 'private';
    return await addPlaylistWithDataAndPermission(name, sharePermission);
  }

  // Add playlist with specific permission and return playlist data
  static Future<Map<String, dynamic>?> addPlaylistWithDataAndPermission(
    String name,
    String sharePermission,
  ) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      // Load tokens first to ensure we have valid authentication
      await TokenManager.loadTokens();

      if (TokenManager.accessToken == null) {
        print('No access token available');
        return null;
      }

      final url = Uri.parse('$serverUrl/api/library/playlists/');
      print("Url: $url");
      print("Using token: ${TokenManager.accessToken?.substring(0, 20)}...");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${TokenManager.accessToken}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          'name': name,
          'description': 'Playlist is created by API',
          'share_permission': sharePermission,
        }),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 201) {
        final playlistData = jsonDecode(response.body);
        return playlistData;
      } else {
        print('Failed to add playlist: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error adding playlist: $e');
      return null;
    }
  }

  // Add playlist with cover image (improved approach)
  static Future<String?> addPlaylistWithCover(
    String name,
    bool public,
    File? coverImage,
  ) async {
    String sharePermission = public ? 'public' : 'private';
    return await addPlaylistWithCoverAndPermission(
      name,
      sharePermission,
      coverImage,
    );
  }

  // Add playlist with cover image and specific permission
  static Future<String?> addPlaylistWithCoverAndPermission(
    String name,
    String sharePermission,
    File? coverImage,
  ) async {
    try {
      // Step 1: Create playlist and get the data immediately
      print("Step 1: Creating playlist...");
      Map<String, dynamic>? playlistData =
          await addPlaylistWithDataAndPermission(name, sharePermission);

      if (playlistData == null) {
        print("Failed to create playlist");
        return null;
      }

      String playlistId = playlistData['id'].toString();
      print("Created playlist with ID: $playlistId");

      // Step 2: Upload cover image if provided
      if (coverImage != null) {
        print("Step 2: Uploading cover image...");
        bool uploadSuccess = await uploadPlaylistCover(playlistId, coverImage);
        if (!uploadSuccess) {
          print("Failed to upload cover image, but playlist was created");
        } else {
          print("Cover image uploaded successfully");
        }
      }

      return playlistId;
    } catch (e) {
      print('Error in addPlaylistWithCover: $e');
      return null;
    }
  }

  // Upload cover image to existing playlist
  static Future<bool> uploadPlaylistCover(
    String playlistId,
    File coverImage,
  ) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      // Load tokens first
      await TokenManager.loadTokens();

      if (TokenManager.accessToken == null) {
        print('No access token available for uploadPlaylistCover');
        return false;
      }

      final url = Uri.parse(
        '$serverUrl/api/library/playlists/$playlistId/upload_cover/',
      );

      var request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        "Authorization": "Bearer ${TokenManager.accessToken}",
      });

      // Add debug info about the multipart file and set proper content type
      String? contentType;
      String extension = coverImage.path.toLowerCase();
      if (extension.endsWith('.jpg') || extension.endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      } else if (extension.endsWith('.png')) {
        contentType = 'image/png';
      } else if (extension.endsWith('.gif')) {
        contentType = 'image/gif';
      }

      var multipartFile = await http.MultipartFile.fromPath(
        'cover_image',
        coverImage.path,
        contentType: contentType != null ? MediaType.parse(contentType) : null,
      );

      request.files.add(multipartFile);

      final response = await request.send();

      if (response.statusCode == 200) {
        print("Cover image uploaded successfully!");
        return true;
      } else {
        print("Failed to upload cover image. Status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print('Error uploading playlist cover: $e');
      print('Stack trace: ${StackTrace.current}');
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
      // Load tokens first
      await TokenManager.loadTokens();

      if (TokenManager.accessToken == null) {
        print('No access token available for getLocalPlaylists');
        return [];
      }

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
          // Handle cover image URL
          String pictureUrl = '';

          if (playlist['cover_image_url'] != null &&
              playlist['cover_image_url'].isNotEmpty) {
            String coverUrl = playlist['cover_image_url'];
            if (!coverUrl.startsWith('http://') &&
                !coverUrl.startsWith('https://')) {
              String baseUrl = serverUrl;
              if (!baseUrl.startsWith('http://') &&
                  !baseUrl.startsWith('https://')) {
                baseUrl = 'http://$baseUrl';
              }
              pictureUrl = '$baseUrl$coverUrl';
            } else {
              pictureUrl = coverUrl;
            }
          } else if (playlist['cover_image'] != null &&
              playlist['cover_image'].isNotEmpty) {
            // If cover_image is a relative path, build full URL
            String coverImage = playlist['cover_image'];
            if (!coverImage.startsWith('http://') &&
                !coverImage.startsWith('https://')) {
              String baseUrl = serverUrl;
              if (!baseUrl.startsWith('http://') &&
                  !baseUrl.startsWith('https://')) {
                baseUrl = 'http://$baseUrl';
              }
              pictureUrl = '$baseUrl$coverImage';
            } else {
              pictureUrl = coverImage;
            }
          } else {
            // Default placeholder image
            pictureUrl =
                'https://wallpapers.com/images/featured/picture-en3dnh2zi84sgt3t.jpg';
          }

          playlists.add(
            PlayList(
              id: playlist['id'].toString(),
              title: playlist['name'],
              description: playlist['description'],
              duration:
                  playlist['total_duration_seconds'] ??
                  0, // Use duration from API
              picture: pictureUrl,
              creator:
                  playlist['owner_name'] ??
                  'Unknown', // Use owner_name from API
              ownerId: playlist['owner']?.toString(),
              ownerAvatarUrl: playlist['owner_avatar_url'],
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
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${TokenManager.accessToken}'},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        // Handle cover image URL
        String pictureUrl = '';

        if (data['cover_image_url'] != null &&
            data['cover_image_url'].isNotEmpty) {
          String coverUrl = data['cover_image_url'];
          if (!coverUrl.startsWith('http://') &&
              !coverUrl.startsWith('https://')) {
            String baseUrl = serverUrl;
            if (!baseUrl.startsWith('http://') &&
                !baseUrl.startsWith('https://')) {
              baseUrl = 'http://$baseUrl';
            }
            pictureUrl = '$baseUrl$coverUrl';
          } else {
            pictureUrl = coverUrl;
          }
        } else if (data['cover_image'] != null &&
            data['cover_image'].isNotEmpty) {
          // If cover_image is a relative path, build full URL
          String coverImage = data['cover_image'];
          if (!coverImage.startsWith('http://') &&
              !coverImage.startsWith('https://')) {
            String baseUrl = serverUrl;
            if (!baseUrl.startsWith('http://') &&
                !baseUrl.startsWith('https://')) {
              baseUrl = 'http://$baseUrl';
            }
            pictureUrl = '$baseUrl$coverImage';
          } else {
            pictureUrl = coverImage;
          }
        } else {
          // Default placeholder image
          pictureUrl =
              'https://wallpapers.com/images/featured/picture-en3dnh2zi84sgt3t.jpg';
        }

        var playlist = PlayList(
          id: data['id'].toString(),
          title: data['name'],
          description: data['description'],
          duration:
              data['total_duration_seconds'] ?? 0, // Use duration from API
          picture: pictureUrl,
          creator: data['owner_name'] ?? 'Unknown', // Use owner_name from API
          ownerId: data['owner']?.toString(),
          ownerAvatarUrl: data['owner_avatar_url'],
          songs: [],
          sharePermission:
              data['share_permission'] ?? 'private', // Added share permission
        );

        // Parse songs if they exist in the response
        if (data['songs'] != null && data['songs'] is List) {
          for (var song in data['songs']) {
            int id = song['id'];

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

            // Process relative URLs to full URLs (similar to SongOperations)
            String serverBase = serverUrl;
            if (!serverBase.startsWith('http://') &&
                !serverBase.startsWith('https://')) {
              serverBase = 'http://$serverBase';
            }

            // Process cover_art URL
            if (song['cover_art'] != null &&
                song['cover_art'].toString().isNotEmpty &&
                !song['cover_art'].toString().startsWith('http://') &&
                !song['cover_art'].toString().startsWith('https://')) {
              song['cover_art'] = '$serverBase${song['cover_art']}';
            }

            // Process audio URLs in audio_urls map
            if (song['audio_urls'] != null) {
              Map<String, dynamic> audioUrls = Map<String, dynamic>.from(
                song['audio_urls'],
              );
              audioUrls.forEach((key, value) {
                if (value != null &&
                    value.toString().isNotEmpty &&
                    !value.toString().startsWith('http://') &&
                    !value.toString().startsWith('https://')) {
                  audioUrls[key] = '$serverBase$value';
                }
              });
              song['audio_urls'] = audioUrls;
            }

            // Process legacy audio URL
            if (song['audio'] != null &&
                song['audio'].toString().isNotEmpty &&
                !song['audio'].toString().startsWith('http://') &&
                !song['audio'].toString().startsWith('https://')) {
              song['audio'] = '$serverBase${song['audio']}';
            }

            // Use Song.fromJson to create Song objects with quality support
            playlist.songs.add(Song.fromJson(song));
          }
        }

        return playlist;
      } else {
        throw Exception(
          'Failed to load playlist: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching playlist: $e');
    }
  }

  static Future<bool> addSongToPlaylist(
    String playlistID,
    String songID,
  ) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      final url = Uri.parse('$serverUrl/api/library/add-song-to-playlist/');

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${TokenManager.accessToken}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({'song_id': songID, 'playlist_id': playlistID}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeSongFromPlaylist(
    String playlistID,
    String songID,
  ) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      final url = Uri.parse(
        '$serverUrl/api/library/remove-song-from-playlist/',
      );

      final response = await http.delete(
        url,
        headers: {
          "Authorization": "Bearer ${TokenManager.accessToken}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({'song_id': songID, 'playlist_id': playlistID}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // New method to get playlists of a specific user (friends/public only)
  static Future<List<PlayList>> getUserPlaylists(String userId) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      final url = Uri.parse('$serverUrl/api/library/user-playlists/$userId/');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${TokenManager.accessToken}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("User playlists data: $data");
        List<PlayList> playlists = [];
        for (var playlist in data) {
          // Only include playlists that are friends or public
          String sharePermission = playlist['share_permission'] ?? 'private';
          if (sharePermission == 'friends' || sharePermission == 'public') {
            // Handle cover image URL (same logic as getLocalPlaylists)
            String pictureUrl = '';

            if (playlist['cover_image_url'] != null &&
                playlist['cover_image_url'].isNotEmpty) {
              String coverUrl = playlist['cover_image_url'];
              if (!coverUrl.startsWith('http://') &&
                  !coverUrl.startsWith('https://')) {
                String baseUrl = serverUrl;
                if (!baseUrl.startsWith('http://') &&
                    !baseUrl.startsWith('https://')) {
                  baseUrl = 'http://$baseUrl';
                }
                pictureUrl = '$baseUrl$coverUrl';
              } else {
                pictureUrl = coverUrl;
              }
            } else if (playlist['cover_image'] != null &&
                playlist['cover_image'].isNotEmpty) {
              // If cover_image is a relative path, build full URL
              String coverImage = playlist['cover_image'];
              if (!coverImage.startsWith('http://') &&
                  !coverImage.startsWith('https://')) {
                String baseUrl = serverUrl;
                if (!baseUrl.startsWith('http://') &&
                    !baseUrl.startsWith('https://')) {
                  baseUrl = 'http://$baseUrl';
                }
                pictureUrl = '$baseUrl$coverImage';
              } else {
                pictureUrl = coverImage;
              }
            } else if (playlist['picture'] != null &&
                playlist['picture'].isNotEmpty) {
              // Fallback: try to use 'picture' field if available
              String picture = playlist['picture'];
              if (!picture.startsWith('http://') &&
                  !picture.startsWith('https://')) {
                String baseUrl = serverUrl;
                if (!baseUrl.startsWith('http://') &&
                    !baseUrl.startsWith('https://')) {
                  baseUrl = 'http://$baseUrl';
                }
                pictureUrl = '$baseUrl$picture';
              } else {
                pictureUrl = picture;
              }
            } else {
              // Default placeholder image (same as getLocalPlaylists)
              pictureUrl =
                  'https://wallpapers.com/images/featured/picture-en3dnh2zi84sgt3t.jpg';
            }

            playlists.add(
              PlayList(
                id: playlist['id'].toString(),
                title: playlist['name'],
                description: playlist['description'] ?? '',
                duration: 0,
                picture:
                    pictureUrl, // Use processed pictureUrl instead of raw 'picture'
                creator: playlist['creator'] ?? 'Unknown',
                ownerId: playlist['owner']?.toString(),
                ownerAvatarUrl: playlist['owner_avatar_url'],
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

  // Update playlist with name, permission, and optionally cover image
  static Future<bool> updatePlaylist(
    String playlistId,
    String name,
    String sharePermission,
    File? newImage,
    bool removeImage,
  ) async {
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    try {
      // Load tokens first to ensure we have valid authentication
      await TokenManager.loadTokens();

      if (TokenManager.accessToken == null) {
        print('No access token available');
        return false;
      }

      final url = Uri.parse('$serverUrl/api/library/playlists/$playlistId/');

      // First, update basic playlist info (name and share permission)
      final response = await http.patch(
        url,
        headers: {
          "Authorization": "Bearer ${TokenManager.accessToken}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({'name': name, 'share_permission': sharePermission}),
      );

      if (response.statusCode != 200) {
        print('Failed to update playlist basic info: ${response.statusCode}');
        return false;
      }

      // Handle cover image update if needed
      if (removeImage) {
        // Remove existing cover image
        final removeCoverUrl = Uri.parse(
          '$serverUrl/api/library/playlists/$playlistId/remove_cover/',
        );
        final removeCoverResponse = await http.delete(
          removeCoverUrl,
          headers: {"Authorization": "Bearer ${TokenManager.accessToken}"},
        );

        print(
          "Remove cover response status: ${removeCoverResponse.statusCode}",
        );
        if (removeCoverResponse.statusCode != 200 &&
            removeCoverResponse.statusCode != 204) {
          print(
            'Failed to remove cover image: ${removeCoverResponse.statusCode}',
          );
          // Don't return false here as basic update was successful
        }
      } else if (newImage != null) {
        // Upload new cover image
        bool uploadSuccess = await uploadPlaylistCover(playlistId, newImage);
        if (!uploadSuccess) {
          print(
            "Failed to upload new cover image, but basic update was successful",
          );
          // Don't return false here as basic update was successful
        } else {
          print("Cover image uploaded successfully");
        }
      }

      return true;
    } catch (e) {
      print('Error updating playlist: $e');
      return false;
    }
  }
}
