// Enum to define screen indices for navigation
enum ScreenIndex {
  // Main tab screens (0-4)
  home(0),
  trending(1),
  follow(2),
  profile(3),
  setting(4),

  // Extra screens (5+)
  playlist(5),
  search(6),
  userProfile(7),
  friendRequests(8),
  searchUser(9),
  recentlyPlayed(10),
  favorites(11),
  downloaded(12),
  playlistCreation(13),
  album(14),
  artist(15);

  const ScreenIndex(this.value);
  final int value;

  static ScreenIndex? fromValue(int value) {
    for (ScreenIndex screen in ScreenIndex.values) {
      if (screen.value == value) return screen;
    }
    return null;
  }
}
