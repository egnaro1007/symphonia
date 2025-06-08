import 'package:audio_service/audio_service.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/models/playlist.dart';
import 'package:symphonia/services/audio_handler.dart';
import 'package:symphonia/main.dart';
import 'dart:async';
import 'dart:math';

enum RepeatMode { noRepeat, repeatOne, repeatAll }

enum ShuffleMode { off, on }

class PlayerController {
  static PlayerController? _instance;
  final StreamController<Song> _songChangeController =
      StreamController<Song>.broadcast();
  final StreamController<PlayList> _playlistChangeController =
      StreamController<PlayList>.broadcast();
  final StreamController<ShuffleMode> _shuffleModeChangeController =
      StreamController<ShuffleMode>.broadcast();

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
  ShuffleMode _shuffleMode = ShuffleMode.off;
  List<int> _shuffledIndices = [];
  int _shufflePosition = 0;

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
  Stream<ShuffleMode> get onShuffleModeChange =>
      _shuffleModeChangeController.stream;

  // Getters
  Song get playingSong => _playingSong;
  bool get hasSong => _hasSong;
  PlayList get currentPlaylist => _currentPlaylist;
  int get currentSongIndex => _currentSongIndex;
  List<Song> get queueSongs =>
      _currentSongIndex < _currentPlaylist.songs.length - 1
          ? _currentPlaylist.songs.sublist(_currentSongIndex + 1)
          : [];

  // Get songs in display order (shuffled or normal)
  List<Song> get songsInDisplayOrder {
    if (_shuffleMode == ShuffleMode.on && _shuffledIndices.isNotEmpty) {
      return _shuffledIndices
          .map((index) => _currentPlaylist.songs[index])
          .toList();
    }
    return _currentPlaylist.songs;
  }

  // Get current song index in display order
  int get currentSongIndexInDisplayOrder {
    if (_shuffleMode == ShuffleMode.on && _shuffledIndices.isNotEmpty) {
      return _shufflePosition;
    }
    return _currentSongIndex;
  }

  // Convert display index to actual playlist index
  int displayIndexToPlaylistIndex(int displayIndex) {
    if (_shuffleMode == ShuffleMode.on && _shuffledIndices.isNotEmpty) {
      return displayIndex < _shuffledIndices.length
          ? _shuffledIndices[displayIndex]
          : -1;
    }
    return displayIndex;
  }

  // Convert playlist index to display index
  int playlistIndexToDisplayIndex(int playlistIndex) {
    if (_shuffleMode == ShuffleMode.on && _shuffledIndices.isNotEmpty) {
      return _shuffledIndices.indexOf(playlistIndex);
    }
    return playlistIndex;
  }

  // Convert current shuffle order to be the main playlist order and turn off shuffle
  // This is called when adding songs in shuffle mode to "freeze" the current shuffle order
  // as the new official playlist order before adding new songs
  void _consolidateShuffleToPlaylist() {
    if (_shuffleMode != ShuffleMode.on || _shuffledIndices.isEmpty) return;

    // Create new playlist in current shuffle order
    List<Song> newOrderedSongs = [];
    for (int shuffleIndex in _shuffledIndices) {
      if (shuffleIndex < _currentPlaylist.songs.length) {
        newOrderedSongs.add(_currentPlaylist.songs[shuffleIndex]);
      }
    }

    // Update playlist with new order (shuffle order becomes the new normal order)
    _currentPlaylist.songs.clear();
    _currentPlaylist.songs.addAll(newOrderedSongs);

    // Update current song index to match new position in consolidated playlist
    _currentSongIndex = _shufflePosition;

    // Turn off shuffle mode
    _shuffleMode = ShuffleMode.off;
    _shuffledIndices.clear();
    _shufflePosition = 0;

    // Notify UI about changes
    _shuffleModeChangeController.add(_shuffleMode);
    _playlistChangeController.add(_currentPlaylist);
  }

  // Reorder songs in shuffle mode (only affects shuffle order, not original playlist)
  void reorderSongsInShuffle(int oldDisplayIndex, int newDisplayIndex) {
    if (_shuffleMode != ShuffleMode.on || _shuffledIndices.isEmpty) return;

    if (oldDisplayIndex < newDisplayIndex) {
      newDisplayIndex -= 1;
    }

    if (oldDisplayIndex >= 0 &&
        oldDisplayIndex < _shuffledIndices.length &&
        newDisplayIndex >= 0 &&
        newDisplayIndex < _shuffledIndices.length) {
      final int playlistIndex = _shuffledIndices.removeAt(oldDisplayIndex);
      _shuffledIndices.insert(newDisplayIndex, playlistIndex);

      // Update shuffle position if current song was moved
      if (oldDisplayIndex == _shufflePosition) {
        _shufflePosition = newDisplayIndex;
      } else if (oldDisplayIndex < _shufflePosition &&
          newDisplayIndex >= _shufflePosition) {
        _shufflePosition--;
      } else if (oldDisplayIndex > _shufflePosition &&
          newDisplayIndex <= _shufflePosition) {
        _shufflePosition++;
      }

      // Notify playlist change to update UI
      _playlistChangeController.add(_currentPlaylist);

      // Also notify shuffle mode change to force UI rebuild
      _shuffleModeChangeController.add(_shuffleMode);
    }
  }

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

  ShuffleMode get shuffleMode => _shuffleMode;
  set shuffleMode(ShuffleMode mode) {
    _shuffleMode = mode;
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
    // If in shuffle mode, consolidate shuffle order first
    if (_shuffleMode == ShuffleMode.on) {
      _consolidateShuffleToPlaylist();
    }

    _currentPlaylist.songs.add(song);
    _playlistChangeController.add(_currentPlaylist); // Notify playlist change
  }

  // Add song to play next (right after current song)
  Future<void> addSongToPlayNext(Song song) async {
    if (!_hasSong || _currentPlaylist.songs.isEmpty) {
      // If no song is playing, play this song immediately
      await loadSong(song);
    } else {
      // If in shuffle mode, consolidate shuffle order first
      if (_shuffleMode == ShuffleMode.on) {
        _consolidateShuffleToPlaylist();
      }

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
    // If in shuffle mode, consolidate shuffle order first
    if (_shuffleMode == ShuffleMode.on) {
      _consolidateShuffleToPlaylist();
    }

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

      // Update shuffle indices if in shuffle mode
      if (_shuffleMode == ShuffleMode.on && _shuffledIndices.isNotEmpty) {
        _updateShuffleIndicesAfterRemoval(index);
      }

      _playlistChangeController.add(_currentPlaylist); // Notify playlist change
    }
  }

  // Update shuffle indices after removing a song from playlist
  void _updateShuffleIndicesAfterRemoval(int removedIndex) {
    // Remove the index from shuffle list
    int shuffleIndexToRemove = _shuffledIndices.indexOf(removedIndex);
    if (shuffleIndexToRemove != -1) {
      _shuffledIndices.removeAt(shuffleIndexToRemove);

      // Adjust shuffle position if necessary
      if (shuffleIndexToRemove < _shufflePosition) {
        _shufflePosition--;
      } else if (shuffleIndexToRemove == _shufflePosition) {
        // Current song was removed, adjust position
        if (_shufflePosition >= _shuffledIndices.length) {
          _shufflePosition = _shuffledIndices.length - 1;
        }
      }
    }

    // Adjust all indices that are greater than the removed index
    for (int i = 0; i < _shuffledIndices.length; i++) {
      if (_shuffledIndices[i] > removedIndex) {
        _shuffledIndices[i]--;
      }
    }

    // If shuffle list is empty, turn off shuffle
    if (_shuffledIndices.isEmpty) {
      _shuffleMode = ShuffleMode.off;
      _shufflePosition = 0;
      _shuffleModeChangeController.add(_shuffleMode);
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
    } else if (_shuffleMode == ShuffleMode.on) {
      await _nextShuffled();
    } else {
      int nextIndex =
          (_repeatMode == RepeatMode.repeatAll)
              ? (_currentSongIndex + 1) % _currentPlaylist.songs.length
              : _currentSongIndex + 1;
      await gotoIndex(nextIndex);
    }
  }

  Future<void> previous() async {
    if (_shuffleMode == ShuffleMode.on) {
      await _previousShuffled();
    } else {
      gotoIndex(_currentSongIndex - 1);
    }
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

  void changeShuffleMode([ShuffleMode? mode]) {
    if (mode != null) {
      _shuffleMode = mode;
    } else {
      switch (_shuffleMode) {
        case ShuffleMode.off:
          _shuffleMode = ShuffleMode.on;
          _generateShuffledIndices();
          break;
        case ShuffleMode.on:
          _shuffleMode = ShuffleMode.off;
          _shuffledIndices.clear();
          _shufflePosition = 0;
          break;
      }
    }
    // Notify listeners about shuffle mode change
    _shuffleModeChangeController.add(_shuffleMode);
  }

  void _generateShuffledIndices() {
    if (_currentPlaylist.songs.isEmpty) return;

    _shuffledIndices = List.generate(
      _currentPlaylist.songs.length,
      (index) => index,
    );
    _shuffledIndices.shuffle(Random());

    // Make sure current song is at the beginning of shuffle
    int currentIndexInShuffle = _shuffledIndices.indexOf(_currentSongIndex);
    if (currentIndexInShuffle != -1) {
      _shuffledIndices.removeAt(currentIndexInShuffle);
      _shuffledIndices.insert(0, _currentSongIndex);
    }
    _shufflePosition = 0;
  }

  Future<void> _nextShuffled() async {
    if (_shuffledIndices.isEmpty) {
      _generateShuffledIndices();
    }

    if (_shufflePosition < _shuffledIndices.length - 1) {
      _shufflePosition++;
      await gotoIndex(_shuffledIndices[_shufflePosition]);
    } else if (_repeatMode == RepeatMode.repeatAll) {
      // Regenerate shuffle and start from beginning
      _generateShuffledIndices();
      _shufflePosition = 0;
      await gotoIndex(_shuffledIndices[_shufflePosition]);
    }
  }

  Future<void> _previousShuffled() async {
    if (_shuffledIndices.isEmpty) {
      _generateShuffledIndices();
    }

    if (_shufflePosition > 0) {
      _shufflePosition--;
      await gotoIndex(_shuffledIndices[_shufflePosition]);
    }
  }

  Future<void> reset() async {
    try {
      await _audioHandler.stop();
      _hasSong = false;
      _currentSongIndex = 0;
      _repeatMode = RepeatMode.noRepeat;
      _shuffleMode = ShuffleMode.off;
      _shuffledIndices.clear();
      _shufflePosition = 0;
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
    _shuffleModeChangeController.close();
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
