class BriefPlayList {
  String id;
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
  String? id;
  String? title;
  String? description;
  String? imageUrl;
}