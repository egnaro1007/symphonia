class FriendRequest {
  final String id;
  final String sender_id;
  final String name;
  final String avatarUrl;
  final String? profilePictureUrl;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? birthDate;
  final String? email;

  FriendRequest({
    required this.id,
    required this.sender_id,
    required this.name,
    required this.avatarUrl,
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
      return name; // Fallback to name/username if no name provided
    }
    final last = lastName ?? '';
    final first = firstName ?? '';
    return '$last $first'.trim();
  }
}
