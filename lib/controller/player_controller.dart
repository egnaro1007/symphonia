import 'package:audioplayers/audioplayers.dart';
import 'package:symphonia/models/song.dart';
import 'dart:async';

class PlayerController {
  static PlayerController? _instance;
  final AudioPlayer _audioPlayer;
  final StreamController<Song> _songChangeController = StreamController<Song>.broadcast();

  Song _playingSong = Song(
    title: "",
    artist: "",
    imagePath: "",
    audioUrl: "",
  );

  PlayerController._internal() : _audioPlayer = AudioPlayer() {
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  factory PlayerController() {
    _instance ??= PlayerController._internal();
    return _instance!;
  }

  static PlayerController getInstance() {
    _instance ??= PlayerController._internal();
    return _instance!;
  }

  Stream<Duration> get onPositionChanged => _audioPlayer.onPositionChanged;
  Stream<PlayerState> get onPlayerStateChanged => _audioPlayer.onPlayerStateChanged;
  Stream<Duration> get onDurationChanged => _audioPlayer.onDurationChanged;
  Stream<Song> get onSongChange => _songChangeController.stream;
  Song get playingSong => _playingSong;

  Future<void> loadSongFromUrl(String url) async {
    print("Loading song from URL: $url");
    _songChangeController.add(_playingSong);
    print ("Playing: ${_playingSong.title}");
    await _audioPlayer.setSourceUrl(url);
    await play();
  }

  Future<void> loadSongFromFile(String filePath) async {
    await _audioPlayer.setSourceDeviceFile(filePath);
  }

  Future<void> loadSong(Song song) async {
    _playingSong = song;
    await loadSongFromUrl(song.audioUrl);
    await play();
  }

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

  Future<void> play() async {
    await _audioPlayer.resume();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void dispose() {
    _audioPlayer.dispose();
    _songChangeController.close();
  }
}