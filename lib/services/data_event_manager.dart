import 'dart:async';

enum DataEventType { likeChanged, downloadChanged, playlistChanged }

class DataEvent {
  final DataEventType type;
  final Map<String, dynamic> data;

  DataEvent({required this.type, this.data = const {}});
}

class DataEventManager {
  static DataEventManager? _instance;
  static DataEventManager get instance => _instance ??= DataEventManager._();

  DataEventManager._();

  final StreamController<DataEvent> _eventController =
      StreamController<DataEvent>.broadcast();

  Stream<DataEvent> get events => _eventController.stream;

  void notifyLikeChanged({int? songId}) {
    _eventController.add(
      DataEvent(type: DataEventType.likeChanged, data: {'songId': songId}),
    );
  }

  void notifyDownloadChanged({int? songId}) {
    _eventController.add(
      DataEvent(type: DataEventType.downloadChanged, data: {'songId': songId}),
    );
  }

  void notifyPlaylistChanged({String? playlistId}) {
    _eventController.add(
      DataEvent(
        type: DataEventType.playlistChanged,
        data: {'playlistId': playlistId},
      ),
    );
  }

  void dispose() {
    _eventController.close();
  }
}
