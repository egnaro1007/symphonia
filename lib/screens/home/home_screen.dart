import 'package:flutter/material.dart';
import 'package:symphonia/models/playlist.dart';
import 'package:symphonia/screens/playlist/playlist_screen.dart';
import 'package:symphonia/screens/search/search_screen.dart';
import '../abstract_navigation_screen.dart';

class HomeScreen extends AbstractScreen {
  @override
  final String title = "Home";

  @override
  final Icon icon = const Icon(Icons.home);

  HomeScreen({required super.onTabSelected});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  @override
  Widget build(BuildContext context) {
    // Define song data
    final List<List<Map<String, String>>> songGroups = [
      [
        {
          'thumbnail': 'assets/song1.jpg',
          'title': 'Gói Xôi Vội',
          'artists': 'Đạt G, DuUyen',
        },
        {
          'thumbnail': 'assets/song2.jpg',
          'title': 'Trúc Xinh',
          'artists': 'Minh Vương M4U, VIET., ACV',
        },
        {
          'thumbnail': 'assets/song3.jpg',
          'title': 'Chạm Khẽ Tim Anh Một Chút Thôi',
          'artists': 'Noo Phước Thịnh',
        },
      ],
      [
        {
          'thumbnail': 'assets/song1.jpg',
          'title': 'Gói Xôi Vội',
          'artists': 'Đạt G, DuUyen',
        },
        {
          'thumbnail': 'assets/song2.jpg',
          'title': 'Trúc Xinh',
          'artists': 'Minh Vương M4U, VIET., ACV',
        },
        {
          'thumbnail': 'assets/song3.jpg',
          'title': 'Chạm Khẽ Tim Anh Một Chút Thôi',
          'artists': 'Noo Phước Thịnh',
        },
      ],
      [
        {
          'thumbnail': 'assets/song4.jpg',
          'title': 'Ai Chờ Ai',
          'artists': 'Hương Ly, Jombie',
        },
        {
          'thumbnail': 'assets/song5.jpg',
          'title': 'Ngày Đầu Tiên',
          'artists': 'Đức Phúc',
        },
        {
          'thumbnail': 'assets/song6.jpg',
          'title': 'Chìm Sâu',
          'artists': 'MCK, Trung Trần',
        },
      ],
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Bar with search and theme
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Khám phá',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SearchScreen()),
                            );
                          },
                          child: const Icon(Icons.search, size: 24),
                        )
                      ],
                    ),
                  ],
                ),
              ),

              // For You Section Header
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Text(
                          'Gợi ý cho bạn',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.play_arrow),
                              SizedBox(width: 4),
                              Text('Phát tất cả'),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Suggested Songs - Horizontally Scrollable Groups of Vertical Lists
              SizedBox(
                height: 250,
                child: PageView.builder(
                  itemCount: songGroups.length,
                  itemBuilder: (context, groupIndex) {
                    return _buildSongGroup(songGroups[groupIndex]);
                  },
                ),
              ),

              // Scroll Indicator Dots
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    songGroups.length,
                        (index) => Container(
                      width: index == 0 ? 20 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index == 0 ? Colors.purple.shade400 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),

              // Recommended Playlists Title
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Playlist gợi ý',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),

              // Recommended Playlists Horizontal Scrollable
              SizedBox(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    _buildPlaylistItem(
                      playlist: BriefPlayList(
                        id: '616iSon5fJRnCwYbAJZ9kE',
                        title: 'Vietnam Top 100',
                        picture: 'https://image-cdn-fa.spotifycdn.com/image/ab67706c0000d72c465991ae29721b9576b2cffc',
                        creator: 'Top 100 Tops'
                      ),
                      description: "Top những bài hát hot nhất Việt Nam"
                    ),
                    _buildPlaylistItem(
                      playlist: BriefPlayList(
                        id: '7hJfYpKLDQwmeHIPTmNS5y',
                        title: 'Chill Music',
                        picture: 'https://image-cdn-ak.spotifycdn.com/image/ab67706c0000da84c409e9623b8aad2f27a80040',
                        creator: 'chill songs'
                      ),
                      description: 'Thư giãn với những bản nhạc nhẹ nhàng'
                    ),
                    _buildPlaylistItem(
                      playlist: BriefPlayList(
                        id: '1dvoCOb3vso33rTd4FWqRW',
                        title: 'EDM Mix',
                        picture: 'https://mosaic.scdn.co/640/ab67616d00001e021a5eb771120e2ee3f6a44ed7ab67616d00001e02941dd3b3343d9cb9329d37bfab67616d00001e029cfe80c0c05ce104f7bab18eab67616d00001e02ffb343926530168be4724dd4',
                        creator: 'Akhil Sagar'
                      ),
                      description: 'Năng lượng với những bản EDM hot'
                    ),
                    _buildPlaylistItem(
                      playlist: BriefPlayList(
                        id: '4ckPlRonCUjkAhVnOXV6Ne',
                        title: 'Love Songs',
                        picture: 'https://mosaic.scdn.co/640/ab67616d00001e022ceedc8c879a1f6784fbeef5ab67616d00001e026f6fd002ef1fc6b1f3f90c87ab67616d00001e02a36f994bf8ef9912143d9a23ab67616d00001e02ad2852df5956130426085520',
                        creator: 'Ramsey Kouri'
                      ),
                      description: 'Những bản tình ca ngọt ngào'
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        )
      )
    );
  }

  Widget _buildSongGroup(List<Map<String, String>> songs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: songs.map((song) => _buildSongItem(
          thumbnail: song['thumbnail']!,
          title: song['title']!,
          artists: song['artists']!,
        )).toList(),
      ),
    );
  }

  Widget _buildSongItem({
    required String thumbnail,
    required String title,
    required String artists
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: AssetImage(thumbnail),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  artists,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem({
    required BriefPlayList playlist,
    required String description
  }) {
    return GestureDetector(
      onTap: () {
        widget.onTabSelected(5, playlist.id);
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Playlist cover image
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: Image.network(playlist.picture).image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                playlist.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Flexible(
              child: Text(
                description,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildRecentItem({
    IconData? icon,
    String? label,
    List<Color>? gradient,
    Color? backgroundColor,
    Color? iconColor,
    required String title,
    bool hasPlayButton = false,
  }) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: gradient != null
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        )
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null)
                  Icon(
                    icon,
                    size: 30,
                    color: iconColor ?? Colors.orange.shade300,
                  ),
                if (label != null)
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: gradient != null ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (hasPlayButton)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 20,
                  color: Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }
}