import 'package:flutter/material.dart';
import 'package:symphonia/controller/download_controller.dart';
import 'package:symphonia/controller/player_controller.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/screens/profile/login_screen.dart';
import 'package:symphonia/screens/profile/playlist.dart';
import 'package:symphonia/screens/profile/song_list_screen.dart';
import 'package:symphonia/services/like.dart';
import 'package:symphonia/services/token_manager.dart';
import '../../services/user_info_manager.dart';
import '../abstract_navigation_screen.dart';

class ProfileScreen extends AbstractScreen {
  @override
  final String title = "Profile";

  @override
  final Icon icon = const Icon(Icons.person);

  ProfileScreen({required super.onTabSelected});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header
              _buildProfileHeader(),
              // Quick access buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAccessButton(
                    Icons.schedule,
                    'Nghe gần đây',
                    Colors.orange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => SongListScreen(
                                title: 'Nghe gần đây',
                                songsFuture: _getRecentlyPlayedSongs(),
                                titleIcon: Icons.schedule,
                                titleColor: Colors.orange,
                              ),
                        ),
                      );
                    },
                  ),
                  _buildQuickAccessButton(
                    Icons.favorite_border,
                    'Yêu thích',
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => SongListScreen(
                                title: 'Yêu thích',
                                songsFuture: LikeOperations.getLikeSongs(),
                                titleIcon: Icons.favorite,
                                titleColor: Colors.blue,
                              ),
                        ),
                      );
                    },
                  ),
                  _buildQuickAccessButton(
                    Icons.arrow_downward,
                    'Đã tải',
                    Colors.purple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => SongListScreen(
                                title: 'Đã tải',
                                songsFuture:
                                    DownloadController.getDownloadedSongs(),
                                titleIcon: Icons.download_done,
                                titleColor: Colors.purple,
                              ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Playlists Section
              PlayListComponent(onTabSelected: widget.onTabSelected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 85,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Welcome, ',
                style: const TextStyle(fontSize: 18),
                children: [
                  TextSpan(
                    text: UserInfoManager.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: '!',
                    style: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Logout functionality
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Are you sure you want to logout?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () async {
                          // Reset player state before logout
                          final playerController =
                              PlayerController.getInstance();
                          await playerController.reset();

                          await TokenManager.logout();
                          Navigator.pop(context); // Close the dialog first
                          // Navigate to login screen and clear all previous routes
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                              (Route<dynamic> route) =>
                                  false, // This removes all previous routes
                            );
                          }
                        },
                        child: const Text("Logout"),
                      ),
                    ],
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Method to get recently played songs (placeholder for now)
  Future<List<Song>> _getRecentlyPlayedSongs() async {
    // TODO: Implement actual recently played functionality
    // For now, return an empty list
    return [];
  }
}
