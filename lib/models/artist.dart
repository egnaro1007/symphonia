class Artist {
  final int id;
  final String name;
  final String? bio;
  final String? artistPicture;

  Artist({required this.id, required this.name, this.bio, this.artistPicture});

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as int,
      name: json['name'] as String,
      bio: json['bio'] as String?,
      artistPicture: json['artist_picture'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'artist_picture': artistPicture,
    };
  }

  Artist copyWith({int? id, String? name, String? bio, String? artistPicture}) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      artistPicture: artistPicture ?? this.artistPicture,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Artist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Artist{id: $id, name: $name, bio: $bio, artistPicture: $artistPicture}';
  }
}
