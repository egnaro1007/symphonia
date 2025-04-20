abstract class SearchResult {
  final String _id;
  final String _name;
  final String _image;

  SearchResult({
    required String id,
    required String name,
    required String image,
  })  : _id = id,
        _name = name,
        _image = image;

  String get id => _id;
  String get name => _name;
  String get image => _image;
}

class SongSearchResult extends SearchResult {
  final String _artist;

  SongSearchResult({
    required super.id,
    required super.name,
    required super.image,
    required String artist,
  })  : _artist = artist;

  String get artist => _artist;
}

class ArtistSearchResult extends SearchResult {
  ArtistSearchResult({
    required super.id,
    required super.name,
    required super.image,
  });
}

class AlbumSearchResult extends SearchResult {
  final String _artist;

  AlbumSearchResult({
    required super.id,
    required super.name,
    required super.image,
    required String artist,
  })  : _artist = artist;

  String get artist => _artist;
}

class PlaylistSearchResult extends SearchResult {
  final String _artist;

  PlaylistSearchResult({
    required super.id,
    required super.name,
    required super.image,
    required String artist,
  })  : _artist = artist;

  String get artist => _artist;
}