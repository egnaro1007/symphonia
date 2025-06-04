class Song {
  int id;
  String title;
  String artist;
  String imagePath;
  String audioUrl;
  List<dynamic>? lyrics;

  Song({
    this.id = 0,
    this.title = "",
    this.artist = "",
    this.imagePath = "",
    this.audioUrl = "",
    this.lyrics,
  });
}
