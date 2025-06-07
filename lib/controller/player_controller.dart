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
  final StreamController<PlayList> _playlistChangeController =
      StreamController<PlayList>.broadcast();

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
  Stream<PlayList> get onPlaylistChange => _playlistChangeController.stream;

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
    _hasSong = true;

    // Check if song has valid audio URL
    if (song.audioUrl.isEmpty) {
      // Still notify listeners about song change for UI updates
      _songChangeController.add(_playingSong);
      return;
    }

    // Play through audio handler (this will show notification)
    try {
      await _audioHandler.playSong(song);
    } catch (e) {}

    // Notify listeners about song change after audio handler is set up
    _songChangeController.add(_playingSong);
  }

  // Load song methods
  Future<void> loadSong(Song song, [bool resetQueue = true]) async {
    if (resetQueue) {
      _currentPlaylist.songs.clear();
      _currentSongIndex = 0;
    }
    _currentPlaylist.songs.add(song);
    _playlistChangeController.add(_currentPlaylist); // Notify playlist change
    if (resetQueue || !hasSong) {
      _currentSongIndex = 0;
      await _playSong(_currentPlaylist.songs[_currentSongIndex]);
    }
  }

  Future<void> loadPlaylist(PlayList playlist, [int index = 0]) async {
    _currentPlaylist.songs.clear();
    _currentPlaylist.songs.addAll(playlist.songs);
    _currentSongIndex = index;
    _playlistChangeController.add(_currentPlaylist); // Notify playlist change
    await _playSong(_currentPlaylist.songs[_currentSongIndex]);
  }

  Future<void> loadSongs(List<Song> songs, [int index = 0]) async {
    _currentPlaylist.songs.clear();
    _currentPlaylist.songs.addAll(songs);
    _currentSongIndex = index;
    _playlistChangeController.add(_currentPlaylist); // Notify playlist change
    await _playSong(_currentPlaylist.songs[_currentSongIndex]);
  }

  // Add song to current playlist
  void addSongToPlaylist(Song song) {
    _currentPlaylist.songs.add(song);
    _playlistChangeController.add(_currentPlaylist); // Notify playlist change
  }

  // Add song to play next (right after current song)
  Future<void> addSongToPlayNext(Song song) async {
    if (!_hasSong || _currentPlaylist.songs.isEmpty) {
      // If no song is playing, play this song immediately
      await loadSong(song);
    } else {
      // Check if the song to add is the currently playing song
      if (_currentPlaylist.songs.isNotEmpty &&
          _currentSongIndex < _currentPlaylist.songs.length &&
          _currentPlaylist.songs[_currentSongIndex].id == song.id) {
        // Cancel operation - no need to add currently playing song to next
        return;
      }

      // Check if song already exists in playlist and remove it first
      int existingIndex = _currentPlaylist.songs.indexWhere(
        (s) => s.id == song.id,
      );

      if (existingIndex != -1) {
        // Song already exists, remove it first
        _currentPlaylist.songs.removeAt(existingIndex);

        // Adjust current song index if necessary
        if (existingIndex < _currentSongIndex) {
          _currentSongIndex--;
        }
        // Note: We already checked above that existingIndex != _currentSongIndex
        // so we don't need the else if case here anymore
      }

      // Insert song right after the current song
      int insertIndex = _currentSongIndex + 1;

      // Make sure we don't insert beyond the list bounds
      if (insertIndex > _currentPlaylist.songs.length) {
        insertIndex = _currentPlaylist.songs.length;
      }

      _currentPlaylist.songs.insert(insertIndex, song);
      _playlistChangeController.add(_currentPlaylist); // Notify playlist change
    }
  }

  // Add songs to current playlist
  void addSongsToPlaylist(List<Song> songs) {
    _currentPlaylist.songs.addAll(songs);
    _playlistChangeController.add(_currentPlaylist); // Notify playlist change
  }

  // Remove song from current playlist
  void removeSongFromPlaylist(int index) {
    if (index >= 0 && index < _currentPlaylist.songs.length) {
      _currentPlaylist.songs.removeAt(index);
      // Adjust current index if necessary
      if (index < _currentSongIndex) {
        _currentSongIndex--;
      } else if (index == _currentSongIndex &&
          _currentSongIndex >= _currentPlaylist.songs.length) {
        _currentSongIndex = _currentPlaylist.songs.length - 1;
      }
      _playlistChangeController.add(_currentPlaylist); // Notify playlist change
    }
  }

  // Reorder songs in current playlist
  void reorderSongs(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    if (oldIndex >= 0 &&
        oldIndex < _currentPlaylist.songs.length &&
        newIndex >= 0 &&
        newIndex < _currentPlaylist.songs.length) {
      final Song song = _currentPlaylist.songs.removeAt(oldIndex);
      _currentPlaylist.songs.insert(newIndex, song);

      // Store old current index for comparison
      final oldCurrentIndex = _currentSongIndex;

      // Adjust current song index
      if (oldIndex == _currentSongIndex) {
        // The currently playing song was moved
        _currentSongIndex = newIndex;
      } else if (oldIndex < _currentSongIndex &&
          newIndex >= _currentSongIndex) {
        // Song moved from before current to after current
        _currentSongIndex--;
      } else if (oldIndex > _currentSongIndex &&
          newIndex <= _currentSongIndex) {
        // Song moved from after current to before current
        _currentSongIndex++;
      }

      // Debug print to track changes
      print(
        'Reorder: oldIndex=$oldIndex, newIndex=$newIndex, oldCurrentIndex=$oldCurrentIndex, newCurrentIndex=$_currentSongIndex',
      );

      // Notify playlist change
      _playlistChangeController.add(_currentPlaylist);

      // If the current song index changed, also emit song change to ensure UI updates
      if (oldCurrentIndex != _currentSongIndex) {
        _songChangeController.add(_playingSong);
      }
    }
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
    } catch (e) {}
  }

  void dispose() {
    _songChangeController.close();
    _playlistChangeController.close();
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
