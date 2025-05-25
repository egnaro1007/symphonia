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
  int duration;
  String picture;
  String creator;
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
    this.sharePermission,
  });
}
