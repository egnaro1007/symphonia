class Song {
  int id;
  String title;
  String artist;
  String imagePath;
  String audioUrl; // Legacy field for backward compatibility
  List<dynamic>? lyrics;
  int durationSeconds; // Duration in seconds

  // New fields for album and release date
  String albumName;
  DateTime? releaseDate;

  // New fields for multiple audio qualities
  List<String> availableQualities;
  Map<String, String> audioUrls; // Maps quality to URL
  Map<String, int> audioFileSizes; // Maps quality to file size

  Song({
    this.id = 0,
    this.title = "",
    this.artist = "",
    this.imagePath = "",
    this.audioUrl = "",
    this.lyrics,
    this.durationSeconds = 0,
    this.albumName = "",
    this.releaseDate,
    this.availableQualities = const [],
    this.audioUrls = const {},
    this.audioFileSizes = const {},
  });

  // Get audio URL for specific quality with fallback logic
  String getAudioUrl([String quality = '320kbps']) {
    // If specific quality URL exists, use it
    if (audioUrls.containsKey(quality) && audioUrls[quality]!.isNotEmpty) {
      return audioUrls[quality]!;
    }

    // Fallback to legacy audioUrl if no quality-specific URL
    if (audioUrl.isNotEmpty) {
      return audioUrl;
    }

    // Fallback to any available quality (prioritize higher quality)
    const fallbackOrder = ['lossless', '320kbps', '128kbps'];
    for (String fallbackQuality in fallbackOrder) {
      if (audioUrls.containsKey(fallbackQuality) &&
          audioUrls[fallbackQuality]!.isNotEmpty) {
        return audioUrls[fallbackQuality]!;
      }
    }

    return "";
  }

  // Get file size for specific quality
  int getFileSize([String quality = '320kbps']) {
    return audioFileSizes[quality] ?? 0;
  }

  // Check if specific quality is available
  bool hasQuality(String quality) {
    return availableQualities.contains(quality) &&
        audioUrls.containsKey(quality) &&
        audioUrls[quality]!.isNotEmpty;
  }

  // Get display name for quality
  static String getQualityDisplayName(String quality) {
    switch (quality) {
      case 'lossless':
        return 'Lossless';
      case '320kbps':
        return '320kbps';
      case '128kbps':
        return '128kbps';
      default:
        return quality;
    }
  }

  // Create Song from JSON with quality support
  factory Song.fromJson(Map<String, dynamic> json) {
    Map<String, String> audioUrls = {};
    Map<String, int> audioFileSizes = {};
    List<String> availableQualities = [];

    // Parse audio_urls from API response
    if (json['audio_urls'] != null) {
      Map<String, dynamic> urlsJson = json['audio_urls'];
      urlsJson.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          audioUrls[key] = value.toString();
          if (key != 'legacy') {
            // Don't include legacy in available qualities
            availableQualities.add(key);
          }
        }
      });
    }

    // Parse audio_file_sizes from API response
    if (json['audio_file_sizes'] != null) {
      Map<String, dynamic> sizesJson = json['audio_file_sizes'];
      sizesJson.forEach((key, value) {
        if (value != null) {
          audioFileSizes[key] =
              value is int ? value : int.tryParse(value.toString()) ?? 0;
        }
      });
    }

    // Use available_qualities from API if provided
    if (json['available_qualities'] != null) {
      availableQualities = List<String>.from(json['available_qualities']);
    }

    // Parse album name from album array
    String albumName = "";
    if (json['album'] != null) {
      if (json['album'] is List) {
        List<dynamic> albums = json['album'];
        if (albums.isNotEmpty) {
          var firstAlbum = albums.first;
          if (firstAlbum is Map) {
            albumName = firstAlbum['title'] ?? "";
          }
        }
      } else if (json['album'] is Map) {
        Map<String, dynamic> albumMap = json['album'];
        albumName = albumMap['title'] ?? "";
      }
    }

    // Parse release date
    DateTime? releaseDate;
    if (json['release_date'] != null &&
        json['release_date'].toString().isNotEmpty) {
      try {
        releaseDate = DateTime.parse(json['release_date']);
      } catch (e) {
        releaseDate = null;
      }
    }

    // Parse duration - check both duration and duration_seconds
    int durationSeconds = 0;
    if (json['duration_seconds'] != null) {
      durationSeconds = json['duration_seconds'] ?? 0;
    } else if (json['duration'] != null) {
      // Backend might send duration as seconds directly or as a time string
      if (json['duration'] is int) {
        durationSeconds = json['duration'];
      } else if (json['duration'] is String) {
        // Try to parse duration string like "00:03:45"
        try {
          List<String> parts = json['duration'].split(':');
          if (parts.length == 3) {
            int hours = int.parse(parts[0]);
            int minutes = int.parse(parts[1]);
            int seconds = int.parse(parts[2]);
            durationSeconds = hours * 3600 + minutes * 60 + seconds;
          } else if (parts.length == 2) {
            int minutes = int.parse(parts[0]);
            int seconds = int.parse(parts[1]);
            durationSeconds = minutes * 60 + seconds;
          }
        } catch (e) {
          // Ignore parsing errors
        }
      }
    }

    return Song(
      id: json['id'] ?? 0,
      title: json['title'] ?? "",
      artist: _extractArtistNames(json['artist']),
      imagePath: json['cover_art'] ?? "",
      audioUrl: json['audio'] ?? "", // Legacy field
      lyrics: json['lyric'],
      durationSeconds: durationSeconds,
      albumName: albumName,
      releaseDate: releaseDate,
      availableQualities: availableQualities,
      audioUrls: audioUrls,
      audioFileSizes: audioFileSizes,
    );
  }

  // Helper method to extract artist names from API response
  static String _extractArtistNames(dynamic artistData) {
    if (artistData == null) return "";

    if (artistData is List) {
      return artistData
          .map(
            (artist) =>
                artist is Map ? (artist['name'] ?? '') : artist.toString(),
          )
          .where((name) => name.isNotEmpty)
          .join(', ');
    } else if (artistData is Map) {
      return artistData['name'] ?? "";
    } else {
      return artistData.toString();
    }
  }

  // Helper method to format duration as "mm:ss"
  String get formattedDuration {
    if (durationSeconds <= 0) return "0:00";

    int minutes = durationSeconds ~/ 60;
    int seconds = durationSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  // Helper method to get duration in "Xh Ym" format
  String get formattedDurationLong {
    if (durationSeconds <= 0) return "0m";

    int hours = durationSeconds ~/ 3600;
    int minutes = (durationSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else {
      return "${minutes}m";
    }
  }

  // Helper method to format release date
  String get formattedReleaseDate {
    if (releaseDate == null) return "";

    return "${releaseDate!.day.toString().padLeft(2, '0')}/${releaseDate!.month.toString().padLeft(2, '0')}/${releaseDate!.year}";
  }
}
