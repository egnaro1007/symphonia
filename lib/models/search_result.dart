abstract class SearchResult {
  final int _id;
  final String _name;
  final String _image;

  SearchResult({
    required int id,
    required String name,
    required String image,
  })  : _id = id,
        _name = name,
        _image = image;

  int get id => _id;
  String get name => _name;
  String get image => _image;
}

class SongSearchResult extends SearchResult {
  final String _artist;
  final String _audio_url;

  SongSearchResult({
    required super.id,
    required super.name,
    required super.image,
    required String artist,
    required String audio_url,
  })  : _artist = artist,
        _audio_url = audio_url;

  String get artist => _artist;
  String get audio_url => _audio_url;

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