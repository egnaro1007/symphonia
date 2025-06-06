import 'package:flutter/foundation.dart';

/// Simple global notifier for playlist updates
class PlaylistUpdateNotifier extends ChangeNotifier {
  static final PlaylistUpdateNotifier _instance =
      PlaylistUpdateNotifier._internal();

  factory PlaylistUpdateNotifier() {
    return _instance;
  }

  PlaylistUpdateNotifier._internal();

  /// Notify all listeners that playlist list should be refreshed
  void notifyPlaylistUpdate() {
    print("=== PLAYLIST UPDATE NOTIFICATION ===");
    notifyListeners();
  }
}
