import 'package:flutter/material.dart';
import 'package:symphonia/screens/profile/playlist.dart';
import 'package:symphonia/screens/search/search_screen.dart';
import '../abstract_navigation_screen.dart';

class ProfileScreen extends AbstractScreen {
  const ProfileScreen({super.key});

  @override
  final String title = "Profile";

  @override
  final Icon icon = const Icon(Icons.person);

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
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.black),
            onPressed: () {},
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            child: const Icon(Icons.search, color: Colors.black),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick access buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAccessButton(Icons.favorite_border, 'Yêu thích', Colors.blue),
                  _buildQuickAccessButton(Icons.arrow_downward, 'Đã tải', Colors.purple),
                  _buildQuickAccessButton(Icons.cloud_upload_outlined, 'Upload', Colors.amber),
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
              PlayListComponent()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessButton(IconData icon, String label, Color color) {
    return Container(
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
    );
  }

  Widget _buildRecentItem(String title, Color startColor, Color endColor) {
    return Container(
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
          if (title == '#zingchart')
            const Text(
              '#zingchart',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
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
    );
  }
}