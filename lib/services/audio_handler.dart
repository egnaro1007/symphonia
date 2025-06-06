import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:symphonia/models/song.dart';

class SymphoniaAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  // Callbacks to connect with PlayerController
  Function()? onSkipToNext;
  Function()? onSkipToPrevious;
  Function()? onSongComplete;

  SymphoniaAudioHandler() {
    // Lắng nghe thay đổi trạng thái player
    _player.playerStateStream.listen((state) {
      final isPlaying = state.playing;
      final processingState = switch (state.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      };

      _updatePlaybackState(
        processingState: processingState,
        playing: isPlaying,
      );

      // Xử lý khi bài hát kết thúc
      if (state.processingState == ProcessingState.completed) {
        onSongComplete?.call();
      }
    });

    // Lắng nghe thay đổi vị trí để cập nhật progress bar
    _player.positionStream.listen((position) {
      _updatePlaybackState();
    });

    // Lắng nghe thay đổi duration để cập nhật progress bar
    _player.durationStream.listen((duration) {
      if (duration != null) {
        // Cập nhật MediaItem với duration chính xác
        final currentMediaItem = mediaItem.value;
        if (currentMediaItem != null) {
          mediaItem.add(currentMediaItem.copyWith(duration: duration));
        }
        _updatePlaybackState();
      }
    });

    // Lắng nghe buffered position để hiển thị phần đã buffer
    _player.bufferedPositionStream.listen((bufferedPosition) {
      _updatePlaybackState();
    });
  }

  // Phương thức helper để cập nhật playback state
  void _updatePlaybackState({
    AudioProcessingState? processingState,
    bool? playing,
  }) {
    final currentPosition = _player.position;
    final bufferedPosition = _player.bufferedPosition;

    // Tạo controls với spacing tối ưu
    final controls = <MediaControl>[
      MediaControl.skipToPrevious,
      if (playing ?? _player.playing) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop,
    ];

    playbackState.add(
      playbackState.value.copyWith(
        controls: controls,
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        // Sử dụng compact mode với spacing tự nhiên
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState ?? playbackState.value.processingState,
        playing: playing ?? _player.playing,
        updatePosition: currentPosition,
        bufferedPosition: bufferedPosition,
        speed: _player.speed,
        queueIndex: 0,
      ),
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    try {
      // Stop audio player
      await _player.stop();

      // Clear media item để xóa notification
      mediaItem.add(null);

      // Update playback state to stopped
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.idle,
          playing: false,
          controls: [], // Clear all controls
          updatePosition: Duration.zero,
          bufferedPosition: Duration.zero,
        ),
      );

      // Call parent stop to properly cleanup the service
      await super.stop();

    } catch (e) {
    }
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    onSkipToNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    onSkipToPrevious?.call();
  }

  // Phương thức để load và play một bài hát
  Future<void> playSong(Song song) async {

    // Check if audioUrl is empty
    if (song.audioUrl.isEmpty) {
      print('ERROR: Audio URL is empty for song: ${song.title}');

      // Update media item để hiển thị thông tin bài hát (không phát được)
      mediaItem.add(
        MediaItem(
          id: song.title, // Use title as ID since audioUrl is empty
          title: song.title,
          artist: song.artist,
          duration: Duration(seconds: song.durationSeconds),
          artUri: song.imagePath.isNotEmpty ? Uri.parse(song.imagePath) : null,
        ),
      );

      // Update playback state to indicate error
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          playing: false,
          controls: [MediaControl.stop],
        ),
      );

      return; // Exit early
    }

    // Cập nhật media item cho notification với duration ban đầu
    mediaItem.add(
      MediaItem(
        id: song.audioUrl,
        title: song.title,
        artist: song.artist,
        duration: Duration(seconds: song.durationSeconds),
        artUri: song.imagePath.isNotEmpty ? Uri.parse(song.imagePath) : null,
      ),
    );

    // Load audio source
    try {
      if (song.audioUrl.startsWith('http')) {
        await _player.setUrl(song.audioUrl);
      } else {
        await _player.setFilePath(song.audioUrl);
      }

      // Sau khi load xong, cập nhật duration chính xác nếu có
      _player.durationStream.first.then((actualDuration) {
        if (actualDuration != null) {
          mediaItem.add(mediaItem.value?.copyWith(duration: actualDuration));
        }
      });

      await play();
    } catch (e) {

      // Update playback state to show error
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          playing: false,
          controls: [MediaControl.stop],
        ),
      );
    }
  }

  // Getters để các widget khác có thể truy cập
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  @override
  Future<void> onTaskRemoved() async {
    try {
      // Stop player trước
      await _player.stop();

      // Clear notification ngay lập tức
      mediaItem.add(null);

      // Clear playback state
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.idle,
          playing: false,
          controls: [],
          updatePosition: Duration.zero,
          bufferedPosition: Duration.zero,
        ),
      );

      // Stop service
      await super.stop();

    } catch (e) {
      // Fallback - force stop
      try {
        await super.stop();
      } catch (e2) {
      }
    }
  }

  // Phương thức để force clear notification
  Future<void> forceStopAndClearNotification() async {
    try {
      // Stop tất cả
      await _player.stop();

      // Clear notification
      mediaItem.add(null);

      // Clear playback state
      playbackState.add(PlaybackState());

      // Stop service
      await super.stop();

    } catch (e) {
    }
  }

  // Thêm phương thức dispose để cleanup khi cần
  Future<void> dispose() async {
    try {
      await forceStopAndClearNotification();
      await _player.dispose();
    } catch (e) {
    }
  }
}
