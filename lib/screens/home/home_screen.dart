import 'package:flutter/material.dart';
import 'package:symphonia/controller/player_controller.dart';
import 'package:symphonia/models/playlist.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/services/song.dart';
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
  List<Song> suggestedSongs = [];
  int _currentPageIndex = 0;

  Future<void> _loadSuggestedSongs() async {
    final songs = await SongOperations.getSuggestedSongs();
    setState(() {
      suggestedSongs = songs;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSuggestedSongs();
  }

  @override
  Widget build(BuildContext context) {
    final List<List<Song>> suggestedSongGroups = [];

    for (int i = 0; i < suggestedSongs.length; i += 3) {
      final group = suggestedSongs.sublist(
        i,
        i + 3 > suggestedSongs.length ? suggestedSongs.length : i + 3,
      );

      suggestedSongGroups.add(group);
    }

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
                            widget.onTabSelected(7, "");
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
                      children: [
                        Text(
                          'Gợi ý cho bạn',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            PlayerController.getInstance().loadSongs(suggestedSongs);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            backgroundColor: Theme.of(context).colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
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
                          onPressed: () {
                            // TODO: Implement refresh functionality
                          },
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
                  itemCount: suggestedSongGroups.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index;
                    });
                  },
                  itemBuilder: (context, groupIndex) {
                    return _buildSongGroup(suggestedSongGroups[groupIndex]);
                  },
                ),
              ),

              // Scroll Indicator Dots
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    suggestedSongGroups.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentPageIndex == index ? 20 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: _currentPageIndex == index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHigh,
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
                        creator: 'Top 100'
                      ),
                      description: "Top những bài hát hot nhất Việt Nam"
                    ),
                    _buildPlaylistItem(
                      playlist: BriefPlayList(
                        id: '7hJfYpKLDQwmeHIPTmNS5y',
                        title: 'Chill Music',
                        picture: 'https://image-cdn-fa.spotifycdn.com/image/ab67706c0000da8473a121591cf84842f9383b93',
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
              )
            ],
          ),
        )
      )
    );
  }

  Widget _buildSongGroup(List<Song> songs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: songs.map((song) => _buildSongItem(song)).toList(),
      ),
    );
  }

  Widget _buildSongItem(Song suggestedSong) {
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
                image: NetworkImage(suggestedSong.imagePath),
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
                  suggestedSong.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  suggestedSong.artist,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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