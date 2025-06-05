import 'package:audio_service/audio_service.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/models/playlist.dart';
import 'package:symphonia/services/audio_handler.dart';
import 'package:symphonia/main.dart';
import 'dart:async';

enum RepeatMode { noRepeat, repeatOne, repeatAll }

class PlayerController {
  static PlayerController? _instance;
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
    songs: [],
  );

  int _currentSongIndex = 0;
  RepeatMode _repeatMode = RepeatMode.noRepeat;

  // Lấy audio handler từ main
  SymphoniaAudioHandler get _audioHandler =>
      audioHandler as SymphoniaAudioHandler;

  PlayerController._internal();

  factory PlayerController() {
    _instance ??= PlayerController._internal();
    _instance!._setupAudioHandlerCallbacks();
    return _instance!;
  }

  static PlayerController getInstance() {
    _instance ??= PlayerController._internal();
    _instance!._setupAudioHandlerCallbacks();
    return _instance!;
  }

  // Stream getters từ audio handler
  Stream<Duration> get onPositionChanged => _audioHandler.positionStream;
  Stream<PlaybackState> get onPlayerStateChanged => _audioHandler.playbackState;
  Stream<Duration?> get onDurationChanged => _audioHandler.durationStream;
  Stream<Song> get onSongChange => _songChangeController.stream;

  // Getters
  Song get playingSong => _playingSong;
  bool get hasSong => _hasSong;
  PlayList get currentPlaylist => _currentPlaylist;
  int get currentSongIndex => _currentSongIndex;
  List<Song> get queueSongs =>
      _currentSongIndex < _currentPlaylist.songs.length - 1
          ? _currentPlaylist.songs.sublist(_currentSongIndex + 1)
          : [];

  bool isPlaying() {
    return _audioHandler.isPlaying;
  }

  Future<Duration> getCurrentPosition() async {
    return _audioHandler.position;
  }

  Future<Duration> getDuration() async {
    return _audioHandler.duration ?? Duration.zero;
  }

  RepeatMode get repeatMode => _repeatMode;
  set repeatMode(RepeatMode mode) {
    _repeatMode = mode;
  }

  Future<void> _playSong(Song song) async {
    _playingSong = song;
    _songChangeController.add(_playingSong);

    // Play through audio handler (this will show notification)
    await _audioHandler.playSong(song);

    _hasSong = true;
  }

  // Load song methods
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

  // Controls - delegate to audio handler
  Future<void> play() async {
    await _audioHandler.play();
  }

  Future<void> pause() async {
    await _audioHandler.pause();
  }

  Future<void> seek(Duration position) async {
    await _audioHandler.seek(position);
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
      int nextIndex =
          (_repeatMode == RepeatMode.repeatAll)
              ? (_currentSongIndex + 1) % _currentPlaylist.songs.length
              : _currentSongIndex + 1;
      await gotoIndex(nextIndex);
    }
  }

  Future<void> previous() async {
    gotoIndex(_currentSongIndex - 1);
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

  Future<void> reset() async {
    try {
      await _audioHandler.stop();
      _hasSong = false;
      _currentSongIndex = 0;
      _repeatMode = RepeatMode.noRepeat;
      _playingSong = Song(title: "", artist: "", imagePath: "", audioUrl: "");
      _currentPlaylist = PlayList(
        id: "",
        title: "",
        description: "",
        duration: 0,
        picture: "",
        creator: "",
        songs: [],
      );
      _songChangeController.add(_playingSong);
      print("Player state reset successfully");
    } catch (e) {
      print("Error resetting player: $e");
    }
  }

  void dispose() {
    _songChangeController.close();
  }

  // Thiết lập callbacks cho audio handler
  void _setupAudioHandlerCallbacks() {
    _audioHandler.onSkipToNext = () async {
      await next();
    };

    _audioHandler.onSkipToPrevious = () async {
      await previous();
    };

    _audioHandler.onSongComplete = () async {
      await next();
    };
  }
}
