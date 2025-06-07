import 'package:symphonia/models/song.dart';
import 'package:symphonia/models/artist.dart';

class Album {
  final int id;
  final String title;
  final List<Artist> artist;
  final String? coverArt;
  final DateTime? releaseDate;
  final List<Song> songs;

  Album({
    required this.id,
    required this.title,
    required this.artist,
    this.coverArt,
    this.releaseDate,
    required this.songs,
  });

  // Helper method to get artist names as string
  String get artistNames {
    return artist.map((a) => a.name).join(', ');
  }

  // Helper method to get first artist name
  String get primaryArtist {
    return artist.isNotEmpty ? artist.first.name : 'Unknown Artist';
  }

  // Helper method to get track count
  int get trackCount {
    return songs.length;
  }

  factory Album.fromJson(Map<String, dynamic> json) {
    // Parse cover art URL
    String? coverArtUrl;
    if (json['cover_art'] != null && json['cover_art'].isNotEmpty) {
      String coverArt = json['cover_art'];
      if (!coverArt.startsWith('http://') && !coverArt.startsWith('https://')) {
        // This is a relative path, we'll handle full URL construction in services
        coverArtUrl = coverArt;
      } else {
        coverArtUrl = coverArt;
      }
    }

    return Album(
      id: json['id'] as int,
      title: json['title'] as String,
      artist:
          (json['artist'] as List<dynamic>?)
              ?.map((artistData) => Artist.fromJson(artistData))
              .toList() ??
          [],
      coverArt: coverArtUrl,
      releaseDate:
          json['release_date'] != null
              ? DateTime.parse(json['release_date'] as String)
              : null,
      songs:
          (json['songs'] as List<dynamic>?)?.map((songData) {
            // Parse song cover art
            String? songCoverArt;
            if (songData['cover_art'] != null &&
                songData['cover_art'].isNotEmpty) {
              String cover = songData['cover_art'];
              if (!cover.startsWith('http://') &&
                  !cover.startsWith('https://')) {
                songCoverArt = cover;
              } else {
                songCoverArt = cover;
              }
            }

            return Song(
              id: songData['id'] ?? 0,
              title: songData['title'] ?? '',
              imagePath: songCoverArt ?? '',
              artist:
                  '', // Artist info not included in song data from album API
              audioUrl:
                  '', // Audio URL not included in song data from album API
              durationSeconds:
                  0, // Duration not included in song data from album API
            );
          }).toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist.map((a) => a.toJson()).toList(),
      'cover_art': coverArt,
      'release_date': releaseDate?.toIso8601String(),
      'songs':
          songs
              .map(
                (s) => {'id': s.id, 'title': s.title, 'cover_art': s.imagePath},
              )
              .toList(),
    };
  }

  Album copyWith({
    int? id,
    String? title,
    List<Artist>? artist,
    String? coverArt,
    DateTime? releaseDate,
    List<Song>? songs,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      coverArt: coverArt ?? this.coverArt,
      releaseDate: releaseDate ?? this.releaseDate,
      songs: songs ?? this.songs,
    );
  }
}
