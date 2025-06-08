import 'dart:async';
import 'package:flutter/material.dart';
import '../../../controller/player_controller.dart';
import '../../../services/artist.dart';
import '../../../services/album.dart';
import '../../../models/artist.dart';
import '../../../models/album.dart';
import '../../../models/song.dart';
import '../../../widgets/artist_item.dart';
import '../../../widgets/album_item.dart';
import 'shared_mini_player.dart';
import 'shared_tab_navigator.dart';

class RelatedTab extends StatefulWidget {
  final VoidCallback onTopBarTap;
  final VoidCallback closePlayer;
  final Function(int) onTabChange;
  final Function(int, String)? onTabSelected;

  const RelatedTab({
    super.key,
    required this.onTopBarTap,
    required this.closePlayer,
    required this.onTabChange,
    this.onTabSelected,
  });

  @override
  State<RelatedTab> createState() => _RelatedTabState();
}

class _RelatedTabState extends State<RelatedTab>
    with AutomaticKeepAliveClientMixin {
  final PlayerController _playerController = PlayerController.getInstance();
  final int _tabIndex = 2; // This is the "THÔNG TIN" tab (index 2)

  // Track current song to detect changes
  String _currentSongId = '';

  // Subscription for song changes
  StreamSubscription? _songChangeSubscription;

  // Flag to track initialization
  bool _isInitialized = false;

  // Lists for related content
  List<Artist> _relatedArtists = [];
  List<Album> _relatedAlbums = [];
  bool _isLoadingArtists = false;
  bool _isLoadingAlbums = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeTab();
  }

  void _initializeTab() {
    if (_isInitialized) return;

    // Get initial song ID
    _currentSongId = _playerController.playingSong.id.toString();

    // Listen for song changes
    _songChangeSubscription = _playerController.onSongChange.listen((song) {
      final newSongId = song.id.toString();
      if (_currentSongId != newSongId && mounted) {
        setState(() {
          _currentSongId = newSongId;
        });
        // Refresh information content when song changes
        _loadRelatedContent();
      }
    });

    // Load initial related content
    _loadRelatedContent();

    _isInitialized = true;
  }

  Future<void> _loadRelatedContent() async {
    final currentSong = _playerController.playingSong;
    _loadRelatedArtists(currentSong);
    _loadRelatedAlbums(currentSong);
  }

  Future<void> _loadRelatedArtists(Song currentSong) async {
    if (_isLoadingArtists || !mounted) return;

    if (mounted) {
      setState(() {
        _isLoadingArtists = true;
      });
    }

    try {
      List<Artist> songArtists = [];

      // Parse artist data from current song
      if (currentSong.artist.isNotEmpty) {
        // Get all artists to find matching ones
        final allArtists = await ArtistOperations.getArtists();

        // Split artist names from song and find matching artists
        List<String> artistNames = currentSong.artist.split(', ');
        for (String artistName in artistNames) {
          final matchingArtist = allArtists.firstWhere(
            (artist) => artist.name.toLowerCase() == artistName.toLowerCase(),
            orElse: () => Artist(id: 0, name: artistName),
          );
          if (matchingArtist.id != 0) {
            songArtists.add(matchingArtist);
          }
        }
      }

      if (mounted) {
        setState(() {
          _relatedArtists = songArtists;
        });
      }
    } catch (e) {
      print('Error loading song artists: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingArtists = false;
        });
      }
    }
  }

  Future<void> _loadRelatedAlbums(Song currentSong) async {
    if (_isLoadingAlbums || !mounted) return;

    if (mounted) {
      setState(() {
        _isLoadingAlbums = true;
      });
    }

    try {
      List<Album> songAlbums = [];

      // Get album from current song
      if (currentSong.albumName.isNotEmpty) {
        // Get all albums to find matching one
        final allAlbums = await AlbumOperations.getAlbums();

        final matchingAlbum = allAlbums.firstWhere(
          (album) =>
              album.title.toLowerCase() == currentSong.albumName.toLowerCase(),
          orElse:
              () => Album(
                id: 0,
                title: currentSong.albumName,
                artist: [],
                songs: [],
                releaseDate: currentSong.releaseDate,
              ),
        );

        if (matchingAlbum.id != 0) {
          songAlbums.add(matchingAlbum);
        }
      }

      if (mounted) {
        setState(() {
          _relatedAlbums = songAlbums;
        });
      }
    } catch (e) {
      print('Error loading song albums: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAlbums = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeTab();
  }

  @override
  void dispose() {
    _songChangeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            // Mini player top bar
            SharedMiniPlayer(onTap: widget.onTopBarTap),

            // Tab indicator
            SharedTabNavigator(
              selectedIndex: _tabIndex,
              onTabTap: _handleTabTap,
            ),

            // Content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Song information box
                    _buildSongInformation(),

                    SizedBox(height: 20),

                    // Related Artists section
                    _buildRelatedArtistsSection(),

                    SizedBox(height: 15),

                    // Related Albums section
                    _buildRelatedAlbumsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongInformation() {
    final song = _playerController.playingSong;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Song cover and basic info
            Row(
              children: [
                // Album art
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        song.imagePath.isNotEmpty
                            ? Image.network(
                              song.imagePath,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Container(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.surfaceVariant,
                                    child: Icon(
                                      Icons.music_note,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                      size: 40,
                                    ),
                                  ),
                            )
                            : Container(
                              color:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              child: Icon(
                                Icons.music_note,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                size: 40,
                              ),
                            ),
                  ),
                ),
                SizedBox(width: 16),

                // Song title and artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title.isNotEmpty ? song.title : "Không có tiêu đề",
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        song.artist.isNotEmpty
                            ? song.artist
                            : "Không rõ nghệ sĩ",
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Information details
            _buildInfoRow(
              "Album",
              song.albumName.isNotEmpty
                  ? song.albumName
                  : (song.title.isNotEmpty
                      ? "${song.title} (Single)"
                      : "Không rõ"),
            ),
            _buildInfoRow(
              "Nhạc sĩ",
              song.artist.isNotEmpty ? song.artist : "Không rõ",
            ),
            _buildInfoRow(
              "Phát hành",
              song.formattedReleaseDate.isNotEmpty
                  ? song.formattedReleaseDate
                  : "Không rõ",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Handle tab selection - switch tabs directly without navigation
  void _handleTabTap(int index) {
    if (index == _tabIndex) return; // Already on this tab
    widget.onTabChange(index);
  }

  Widget _buildRelatedArtistsSection() {
    if (_relatedArtists.isEmpty && !_isLoadingArtists) {
      return SizedBox.shrink(); // Hide section if no artists
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Nghệ sĩ",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        if (_isLoadingArtists)
          SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: 8),
              itemCount: _relatedArtists.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: 16),
                  child: ArtistItem(
                    artist: _relatedArtists[index],
                    isHorizontal:
                        false, // This gives us the vertical layout with large avatar
                    onTabSelected: _handleNavigation,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRelatedAlbumsSection() {
    if (_relatedAlbums.isEmpty && !_isLoadingAlbums) {
      return SizedBox.shrink(); // Hide section if no albums
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Album",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        if (_isLoadingAlbums)
          SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        else
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: 8),
              itemCount: _relatedAlbums.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: 16),
                  child: AlbumItem(
                    album: _relatedAlbums[index],
                    isHorizontal:
                        false, // This gives us the vertical layout with large cover
                    onTabSelected: _handleNavigation,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _handleNavigation(int screenIndex, String param) {
    // First, close the player to return to mini player mode
    widget.closePlayer();

    // Use the callback to navigate if provided
    if (widget.onTabSelected != null) {
      // Add a small delay to ensure player transition completes
      Future.delayed(Duration(milliseconds: 300), () {
        widget.onTabSelected!(screenIndex, param);
      });
    }
  }
}
