import 'package:symphonia/models/song.dart';

class BriefPlayList {
  String id;
  String title;
  String picture;
  String creator;
  String? sharePermission;

  BriefPlayList({
    required this.id,
    required this.title,
    required this.picture,
    required this.creator,
    this.sharePermission,
  });
}

class PlayList {
  String id;
  String title;
  String description;
  int duration; // Duration in seconds
  String picture;
  String creator;
  String? ownerId;
  String? ownerAvatarUrl;
  String? sharePermission;

  List<Song> songs;

  PlayList({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.picture,
    required this.creator,
    required this.songs,
    this.ownerId,
    this.ownerAvatarUrl,
    this.sharePermission,
  });

  // Calculate total duration from songs if not provided
  int get totalDurationSeconds {
    if (duration > 0) {
      return duration;
    }
    // Fallback: calculate from songs
    return songs.fold(0, (total, song) => total + song.durationSeconds);
  }

  // Format duration as "Xm Ys"
  String get formattedDuration {
    int totalSeconds = totalDurationSeconds;
    if (totalSeconds <= 0) return "0m 0s";

    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;

    return "${minutes}m ${seconds}s";
  }

  // Get songs count
  int get songsCount {
    return songs.length;
  }
}
