class User {
  String id;
  String username;
  String avatarUrl;
  String status;
  String? profilePictureUrl;
  String? firstName;
  String? lastName;
  String? gender;
  String? birthDate;
  String? email;

  User({
    required this.id,
    required this.username,
    required this.avatarUrl,
    this.status = 'none',
    this.profilePictureUrl,
    this.firstName,
    this.lastName,
    this.gender,
    this.birthDate,
    this.email,
  });

  // Helper method to get full name in format "Last Name First Name"
  String get fullName {
    if ((lastName?.isEmpty ?? true) && (firstName?.isEmpty ?? true)) {
      return username; // Fallback to username if no name provided
    }
    final last = lastName ?? '';
    final first = firstName ?? '';
    return '$last $first'.trim();
  }
}

class UserStatus {
  String id;
  String username;
  String avatarUrl;
  String status;
  String? profilePictureUrl;
  String? firstName;
  String? lastName;
  String? gender;
  String? birthDate;
  String? email;

  UserStatus({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.status,
    this.profilePictureUrl,
    this.firstName,
    this.lastName,
    this.gender,
    this.birthDate,
    this.email,
  });

  // Helper method to get full name in format "Last Name First Name"
  String get fullName {
    if ((lastName?.isEmpty ?? true) && (firstName?.isEmpty ?? true)) {
      return username; // Fallback to username if no name provided
    }
    final last = lastName ?? '';
    final first = firstName ?? '';
    return '$last $first'.trim();
  }
}
