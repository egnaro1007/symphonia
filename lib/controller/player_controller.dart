import 'package:audioplayers/audioplayers.dart';
import 'package:symphonia/models/song.dart';

class PlayerController {
  static PlayerController? _instance;
  final AudioPlayer _audioPlayer;

  PlayerController._internal() : _audioPlayer = AudioPlayer();

  factory PlayerController() {
    _instance ??= PlayerController._internal();
    return _instance!;
  }

  static getInstance() {
    _instance ??= PlayerController();
    return _instance;
  }

  Stream<Duration> get onPositionChanged => _audioPlayer.onPositionChanged;
  Stream<PlayerState> get onPlayerStateChanged => _audioPlayer.onPlayerStateChanged;
  Stream<Duration> get onDurationChanged => _audioPlayer.onDurationChanged;

  Future<void> loadSongFromUrl(String url) async {
    print("Loading song from URL: $url");
    await _audioPlayer.setSourceUrl(url);
    await play();
  }

  Future<void> loadSongFromFile(String filePath) async {
    await _audioPlayer.setSourceDeviceFile(filePath);
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
}