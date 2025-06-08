class Song {
  int id;
  String title;
  String artist;
  String imagePath;
  String audioUrl; // Legacy field for backward compatibility
  List<dynamic>? lyrics;
  int durationSeconds; // Duration in seconds

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

    return Song(
      id: json['id'] ?? 0,
      title: json['title'] ?? "",
      artist: _extractArtistNames(json['artist']),
      imagePath: json['cover_art'] ?? "",
      audioUrl: json['audio'] ?? "", // Legacy field
      lyrics: json['lyric'],
      durationSeconds: json['duration_seconds'] ?? 0,
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
}
