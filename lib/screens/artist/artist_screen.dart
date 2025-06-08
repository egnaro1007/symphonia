import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:symphonia/models/artist.dart';
import 'package:symphonia/models/album.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/screens/abstract_navigation_screen.dart';
import 'package:symphonia/services/artist.dart';
import 'package:symphonia/widgets/album_item.dart';
import 'package:symphonia/widgets/song_item.dart';
import 'package:symphonia/constants/screen_index.dart';
import 'package:symphonia/controller/player_controller.dart';
import 'dart:async';

class ArtistScreen extends AbstractScreen {
  @override
  final String title = "Artist";

  @override
  final Icon icon = const Icon(Icons.person);

  final String artistID;

  const ArtistScreen({
    super.key,
    required this.artistID,
    required super.onTabSelected,
  });

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  late Artist artist = Artist(
    id: 0,
    name: 'Loading...',
    bio: '',
    artistPicture: '',
  );
  late List<Album> albums = [];
  late List<Song> songs = [];
  bool isLoadingArtist = true;
  bool isLoadingAlbums = true;
  bool isLoadingSongs = true;
  int _currentSongPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadArtistData();
    _loadArtistAlbums();
    _loadArtistSongs();
  }

  @override
  void didUpdateWidget(ArtistScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data when artistID changes
    if (oldWidget.artistID != widget.artistID) {
      setState(() {
        isLoadingArtist = true;
        isLoadingAlbums = true;
        isLoadingSongs = true;
        artist = Artist(id: 0, name: 'Loading...', bio: '', artistPicture: '');
        albums = [];
        songs = [];
      });
      _loadArtistData();
      _loadArtistAlbums();
      _loadArtistSongs();
    }
  }

  Future<void> _loadArtistData() async {
    // Skip loading if artistID is empty or invalid
    if (widget.artistID.isEmpty || widget.artistID == "0") {
      setState(() {
        isLoadingArtist = false;
      });
      return;
    }

    try {
      final result = await ArtistOperations.getArtist(widget.artistID);
      setState(() {
        artist = result;
      });
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading artist data: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoadingArtist = false;
      });
    }
  }

  Future<void> _loadArtistAlbums() async {
    // Skip loading if artistID is empty or invalid
    if (widget.artistID.isEmpty || widget.artistID == "0") {
      setState(() {
        isLoadingAlbums = false;
      });
      return;
    }

    try {
      final result = await ArtistOperations.getArtistAlbums(widget.artistID);
      setState(() {
        albums = result;
      });
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading albums: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoadingAlbums = false;
      });
    }
  }

  Future<void> _loadArtistSongs() async {
    // Skip loading if artistID is empty or invalid
    if (widget.artistID.isEmpty || widget.artistID == "0") {
      setState(() {
        isLoadingSongs = false;
      });
      return;
    }

    try {
      final result = await ArtistOperations.getArtistSongs(widget.artistID);
      setState(() {
        songs = result;
      });
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading songs: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoadingSongs = false;
      });
    }
  }

  String? _processArtistPictureUrl(String? url) {
    if (url == null || url.isEmpty || url == 'null') return null;

    // If URL already starts with http, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Add server URL prefix if it's a relative path
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    if (serverUrl.isNotEmpty && url.startsWith('/')) {
      // Ensure server URL doesn't end with slash
      if (serverUrl.endsWith('/')) {
        serverUrl = serverUrl.substring(0, serverUrl.length - 1);
      }
      return '$serverUrl$url';
    }

    return url;
  }

  @override
  Widget build(BuildContext context) {
    bool isLoading = isLoadingArtist || isLoadingAlbums || isLoadingSongs;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Process the artist picture URL to handle relative paths
    String? backgroundImageUrl = _processArtistPictureUrl(artist.artistPicture);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // App Bar with artist background
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    leading: IconButton(
                      icon: Container(
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        // Go back to previous screen using navigation stack
                        widget.onTabSelected(-1, "");
                      },
                    ),
                    expandedHeight: 280,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(
                              backgroundImageUrl?.isNotEmpty == true
                                  ? backgroundImageUrl!
                                  : "https://via.placeholder.com/400x400/9e9e9e/ffffff?text=Artist",
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Add a semi-transparent overlay to ensure text readability
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.2),
                                      Colors.black.withOpacity(0.6),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      artist.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // All Songs Section
                          if (songs.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'All songs',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.chevron_right,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      PlayerController.getInstance().loadSongs(
                                        songs,
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withAlpha((0.1 * 255).toInt()),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.play_arrow),
                                        SizedBox(width: 4),
                                        Text('Phát tất cả'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSongsPageView(songs),
                            const SizedBox(height: 20),
                          ],

                          const SizedBox(height: 10),

                          // Albums Section
                          if (albums.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Albums',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (albums.length > 3)
                                    TextButton(
                                      onPressed: () {
                                        // TODO: Navigate to all albums
                                      },
                                      child: Text('View All'),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 230,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount:
                                    albums.length > 5 ? 5 : albums.length,
                                itemBuilder: (context, index) {
                                  return AlbumItem(
                                    album: albums[index],
                                    isHorizontal: false,
                                    showTrailingControls: false,
                                    onTap: () {
                                      // Navigate to album screen
                                      widget.onTabSelected(
                                        ScreenIndex.album.value,
                                        albums[index].id.toString(),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),

                          // Bio Section
                          if (artist.bio != null && artist.bio!.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'About',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                artist.bio!,
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  height: 1.5,
                                  fontFamily: 'Roboto',
                                ),
                                textAlign: TextAlign.justify,
                                locale: const Locale('vi', 'VN'),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Empty state if no content
                          if (albums.isEmpty && songs.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.music_note,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No content available',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsPageView(List<Song> songs) {
    final List<List<Song>> songGroups = [];

    for (int i = 0; i < songs.length; i += 3) {
      final group = songs.sublist(
        i,
        i + 3 > songs.length ? songs.length : i + 3,
      );
      songGroups.add(group);
    }

    return Column(
      children: [
        SizedBox(
          height: 265,
          child: PageView.builder(
            itemCount: songGroups.length,
            onPageChanged: (index) {
              setState(() {
                _currentSongPageIndex = index;
              });
            },
            itemBuilder: (context, groupIndex) {
              return _buildSongGroup(songGroups[groupIndex]);
            },
          ),
        ),
        // Scroll Indicator Dots
        if (songGroups.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                songGroups.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentSongPageIndex == index ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color:
                        _currentSongPageIndex == index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSongGroup(List<Song> songs) {
    return Column(children: songs.map((song) => _buildSongItem(song)).toList());
  }

  Widget _buildSongItem(Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SongItem(
        song: song,
        showTrailingControls: true,
        isHorizontal: true,
      ),
    );
  }
}
