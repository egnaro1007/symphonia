import 'package:audioplayers/audioplayers.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/models/playlist.dart';
import 'dart:async';

enum RepeatMode { noRepeat, repeatOne, repeatAll }

class PlayerController {
  static PlayerController? _instance;
  final AudioPlayer _audioPlayer;
  final StreamController<Song> _songChangeController =
      StreamController<Song>.broadcast();
  bool _hasSong = false;

  Song _playingSong = Song(title: "", artist: "", imagePath: "", audioUrl: "");

  PlayList _currentPlaylist = PlayList(
      id: "",
      title: "",
      description: "",
      duration: 0,
      picture: "",
      creator: "",
      songs: []
  );
  int _currentSongIndex = 0;
  RepeatMode _repeatMode = RepeatMode.noRepeat;


  PlayerController._internal() : _audioPlayer = AudioPlayer() {
    _audioPlayer.setReleaseMode(ReleaseMode.stop);

    _audioPlayer.onPlayerComplete.listen((event) {
      if (_currentSongIndex + 1 <= _currentPlaylist.songs.length) {
        next();
      }
    });
  }

  factory PlayerController() {
    _instance ??= PlayerController._internal();
    return _instance!;
  }

  static PlayerController getInstance() {
    _instance ??= PlayerController._internal();
    return _instance!;
  }

  // Stream for listening to audio player events
  Stream<Duration> get onPositionChanged => _audioPlayer.onPositionChanged;
  Stream<PlayerState> get onPlayerStateChanged =>
      _audioPlayer.onPlayerStateChanged;
  Stream<Duration> get onDurationChanged => _audioPlayer.onDurationChanged;
  Stream<Song> get onSongChange => _songChangeController.stream;

  // Getters and Setters
  Song get playingSong => _playingSong;

  bool get hasSong => _hasSong;

  bool isPlaying() {
    return _audioPlayer.state == PlayerState.playing;
  }

  Future<Duration> getCurrentPosition() async {
    final position = await _audioPlayer.getCurrentPosition();
    return position ?? Duration.zero;
  }

  Future<Duration> getDuration() async {
    final duration = await _audioPlayer.getDuration();
    return duration ?? Duration.zero;
  }

  RepeatMode get repeatMode => _repeatMode;
  set repeatMode(RepeatMode mode) {
    _repeatMode = mode;
  }


  Future<void> loadSongFromUrl(String url) async {
    print("Loading song from URL: $url");
    _songChangeController.add(_playingSong);
    print("Playing: ${_playingSong.title}");
    await _audioPlayer.setSourceUrl(url);
    await play();
  }

  Future<void> loadSongFromFile(String filePath) async {
    await _audioPlayer.setSourceDeviceFile(filePath);
  }


  Future<void> _playSong(Song song) async {
    if (_playingSong == song) {
      await _audioPlayer.seek(Duration.zero);
      await play();
    }
    _playingSong = song;
    await loadSongFromUrl(song.audioUrl);
    print(_currentSongIndex);
    _hasSong = true;
    await play();
  }


  // Load song from song object
  // models.song.dart
Future<void> loadSong(Song song, [bool resetQueue = true]) async {
  if (resetQueue) {
    _currentPlaylist.songs.clear();
    _currentSongIndex = 0;
  }
  _currentPlaylist.songs.add(song);
  if (resetQueue || !hasSong) {
    _currentSongIndex = 0;
    await _playSong(_currentPlaylist.songs[_currentSongIndex]);
  }
}

  // models.playlist.dart
  Future<void> loadPlaylist(PlayList playlist, [int index = 0]) async {
    _currentPlaylist.songs.clear();
    _currentPlaylist.songs.addAll(playlist.songs);
    _currentSongIndex = index;
    await _playSong(_currentPlaylist.songs[_currentSongIndex]);
  }

  Future<void> loadSongs(List<Song> songs, [int index = 0]) async {
    _currentPlaylist.songs.clear();
    _currentPlaylist.songs.addAll(songs);
    _currentSongIndex = index;
    await _playSong(_currentPlaylist.songs[_currentSongIndex]);
  }

  // Controls
  Future<void> play() async {
    await _audioPlayer.resume();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> gotoIndex(int index) async {
    if (index < 0 || index >= _currentPlaylist.songs.length) {
      return;
    }
    _currentSongIndex = index;
    _playingSong = _currentPlaylist.songs[index];
    await _playSong(_playingSong);
  }

  Future<void> next() async {
    if (_repeatMode == RepeatMode.repeatOne) {
      await _playSong(_playingSong);
    } else {
      int nextIndex = (_repeatMode == RepeatMode.repeatAll)
          ? (_currentSongIndex + 1) % _currentPlaylist.songs.length
          : _currentSongIndex + 1;
      await gotoIndex(nextIndex);
    }
  }

  Future<void> previous() async {
    gotoIndex(_currentSongIndex-1);
  }

  void changeRepeatMode([RepeatMode? mode]) {
    if (mode != null) {
      _repeatMode = mode;
    } else {
      switch (_repeatMode) {
        case RepeatMode.noRepeat:
          _repeatMode = RepeatMode.repeatAll;
          break;
        case RepeatMode.repeatAll:
          _repeatMode = RepeatMode.repeatOne;
          break;
        case RepeatMode.repeatOne:
          _repeatMode = RepeatMode.noRepeat;
          break;
      }
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _songChangeController.close();
  }
}
