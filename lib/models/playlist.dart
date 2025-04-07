import 'package:symphonia/models/song.dart';

class BriefPlayList {
  int id;
  String title;
  String picture;
  String creator;

  BriefPlayList({
    required this.id,
    required this.title,
    required this.picture,
    required this.creator,
  });
}

class PlayList {
  int id;
  String title;
  String description;
  int duration;
  String picture;
  String creator;

  List<Song> songs;

  PlayList({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.picture,
    required this.creator,
    required this.songs,
  });
}