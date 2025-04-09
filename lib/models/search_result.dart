abstract class SearchResult {
  String id;
  String name;
  String image;

  SearchResult({
    required this.id,
    required this.name,
    required this.image,
  });
}

class SongSearchResult extends SearchResult {
  String artist;

  SongSearchResult({
    required String id,
    required String name,
    required this.artist,
    required String image,
  }) : super(id: id, name: name, image: image);
}

class ArtistSearchResult extends SearchResult {
  ArtistSearchResult({
    required String id,
    required String name,
    required String image,
  }) : super(id: id, name: name, image: image);
}

class PlaylistSearchResult extends SearchResult {
  String artist;

  PlaylistSearchResult({
    required String id,
    required String name,
    required String image,
    required this.artist,
  }) : super(id: id, name: name, image: image);
}