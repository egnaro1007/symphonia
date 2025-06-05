class Song {
  int id;
  String title;
  String artist;
  String imagePath;
  String audioUrl;
  List<dynamic>? lyrics;
  int durationSeconds; // Duration in seconds

  Song({
    this.id = 0,
    this.title = "",
    this.artist = "",
    this.imagePath = "",
    this.audioUrl = "",
    this.lyrics,
    this.durationSeconds = 0,
  });

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
