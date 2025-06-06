class User {
  String id;
  String username;
  String avatarUrl;
  String status;

  User({
    required this.id,
    required this.username,
    required this.avatarUrl,
    this.status = 'none',
  });
}

class UserStatus {
  String id;
  String username;
  String avatarUrl;
  String status;

  UserStatus({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.status,
  });
}
