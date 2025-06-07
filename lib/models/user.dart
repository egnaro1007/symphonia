class User {
  String id;
  String username;
  String avatarUrl;
  String status;
  String? profilePictureUrl;

  User({
    required this.id,
    required this.username,
    required this.avatarUrl,
    this.status = 'none',
    this.profilePictureUrl,
  });
}

class UserStatus {
  String id;
  String username;
  String avatarUrl;
  String status;
  String? profilePictureUrl;

  UserStatus({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.status,
    this.profilePictureUrl,
  });
}
