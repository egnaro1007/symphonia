import 'package:flutter/material.dart';
import 'package:symphonia/controller/download_controller.dart';
import 'package:symphonia/controller/player_controller.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/screens/playlist/playlist_screen.dart';
import 'package:symphonia/screens/profile/login_screen.dart';
import 'package:symphonia/screens/profile/playlist.dart';
import 'package:symphonia/screens/search/search_screen.dart';
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

        actions: [
          // IconButton(
          //   icon: const Icon(Icons.mic, color: Colors.black),
          //   onPressed: () {},
          // ),

          // ElevatedButton(
          //   onPressed: () {
          //     widget.onTabSelected(6, "");
          //   },
          //   child: const Icon(Icons.search, color: Colors.black),
          // )
        ],
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
                    Icons.favorite_border,
                    'Yêu thích',
                    Colors.blue,
                    () async {
                      //TODO: Implement favorite
                      List<Song> songs = await LikeOperations.getLikeSongs();
                      for(Song song in songs) {
                        print("Song: ${song.title}");
                      }
                    },
                  ),
                  _buildQuickAccessButton(
                    Icons.arrow_downward,
                    'Đã tải',
                    Colors.purple,
                    () async {
                      //TODO: Implement download

                      // Delete when implement
                      List<Song> songs = await DownloadController.getDownloadedSongs();
                      if (songs.isNotEmpty){
                        for (Song song in songs) {
                          print("Song: ${song.title}");
                          print("Image: ${song.imagePath}");
                          print("Audio: ${song.audioUrl}");
                        }
                        PlayerController.getInstance().loadSongs(songs);
                      }

                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recently played section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nghe gần đây',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {},
                  ),
                ],
              ),

              // Recently played items
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildRecentItem('Bài Hát Nghe\nGần Đây', Colors.blue.shade800, Colors.purple),
                    const SizedBox(width: 12),
                    _buildRecentItem('#zingchart', Colors.purple, Colors.purple),
                    const SizedBox(width: 12),
                    _buildRecentItem('My playlist', Colors.grey.shade800, Colors.grey.shade800),
                  ],
                ),
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

  Widget _buildQuickAccessButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentItem(String title, Color startColor, Color endColor) {
    return GestureDetector(
      onTap: () {
        widget.onTabSelected(5, "symchart");
      },
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (title != '#zingchart')
              const Icon(
                Icons.schedule,
                color: Colors.orange,
                size: 32,
              ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
      ),child: Row(
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
              if (UserInfoManager.username == "Guest") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                ).then((value) {
                  setState(() {});
                }
                );
              } else {
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
                            await TokenManager.logout();
                            Navigator.pop(context);
                            setState(() {});
                          },
                          child: const Text("Logout"),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: UserInfoManager.username == "Guest" ? Colors.green : Colors.red,
            ),
            child: Text(
              UserInfoManager.username == "Guest" ? "Login" : "Logout",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),

    );
  }
}