import 'dart:async';

enum UserEventType {
  friendRequestSent,
  friendRequestAccepted,
  friendRequestRejected,
  unfriended,
}

class UserEvent {
  final UserEventType type;
  final String userId;
  final String? fromUserId;
  final DateTime timestamp;

  UserEvent({
    required this.type,
    required this.userId,
    this.fromUserId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class UserEventManager {
  static final UserEventManager _instance = UserEventManager._internal();
  factory UserEventManager() => _instance;
  UserEventManager._internal();

  final StreamController<UserEvent> _eventController =
      StreamController<UserEvent>.broadcast();

  Stream<UserEvent> get events => _eventController.stream;

  void notifyFriendRequestSent(String toUserId) {
    _eventController.add(
      UserEvent(type: UserEventType.friendRequestSent, userId: toUserId),
    );
  }

  void notifyFriendRequestAccepted(String fromUserId) {
    _eventController.add(
      UserEvent(type: UserEventType.friendRequestAccepted, userId: fromUserId),
    );
  }

  void notifyFriendRequestRejected(String fromUserId) {
    _eventController.add(
      UserEvent(type: UserEventType.friendRequestRejected, userId: fromUserId),
    );
  }

  void notifyUnfriended(String userId) {
    _eventController.add(
      UserEvent(type: UserEventType.unfriended, userId: userId),
    );
  }

  void dispose() {
    _eventController.close();
  }
}
