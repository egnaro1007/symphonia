import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:symphonia/controller/player_controller.dart';

import 'package:symphonia/models/song.dart';
import 'package:symphonia/models/playlist.dart';
import 'package:symphonia/models/album.dart';
import 'package:symphonia/services/song.dart';
import 'package:symphonia/services/playlist.dart';
import 'package:symphonia/services/album.dart';
import 'package:symphonia/widgets/song_item.dart';
import 'package:symphonia/widgets/playlist_item.dart';
import 'package:symphonia/widgets/album_item.dart';
import '../abstract_navigation_screen.dart';
import 'package:symphonia/constants/screen_index.dart';

class HomeScreen extends AbstractScreen {
  @override
  final String title = "Home";

  @override
  final Icon icon = const Icon(Icons.home);

  const HomeScreen({super.key, required super.onTabSelected});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Song> suggestedSongs = [];
  int _currentPageIndex = 0;
  bool _isLoadingSuggestions = false;

  // Playlist data
  List<PlayList> publicPlaylists = [];
  List<PlayList> friendsPlaylists = [];
  bool _isLoadingPublicPlaylists = false;
  bool _isLoadingFriendsPlaylists = false;

  // Album data
  List<Album> albums = [];
  bool _isLoadingAlbums = false;

  Future<void> _loadSuggestedSongs() async {
    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      final songs = await SongOperations.getSuggestedSongs();
      setState(() {
        suggestedSongs = songs;
        _currentPageIndex = 0; // Reset to first page when refreshing
      });
    } catch (e) {
      print('Error loading suggested songs: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải gợi ý bài hát. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingSuggestions = false;
      });
    }
  }

  Future<void> _loadPublicPlaylists() async {
    setState(() {
      _isLoadingPublicPlaylists = true;
    });

    try {
      final playlists = await PlayListOperations.getPublicPlaylists();
      setState(() {
        publicPlaylists = playlists.take(10).toList(); // Limit to 10 playlists
      });
    } catch (e) {
      print('Error loading public playlists: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách công khai'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingPublicPlaylists = false;
      });
    }
  }

  Future<void> _loadFriendsPlaylists() async {
    setState(() {
      _isLoadingFriendsPlaylists = true;
    });

    try {
      final playlists = await PlayListOperations.getFriendsPlaylists();
      setState(() {
        friendsPlaylists = playlists.take(10).toList(); // Limit to 10 playlists
      });
    } catch (e) {
      print('Error loading friends playlists: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách của bạn bè'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingFriendsPlaylists = false;
      });
    }
  }

  Future<void> _loadAlbums() async {
    setState(() {
      _isLoadingAlbums = true;
    });

    try {
      final albumList = await AlbumOperations.getAlbums();
      setState(() {
        albums = albumList.take(20).toList(); // Limit to 20 albums
      });
    } catch (e) {
      print('Error loading albums: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách album'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingAlbums = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSuggestedSongs();
    _loadPublicPlaylists();
    _loadFriendsPlaylists();
    _loadAlbums();
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.discover,
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
                            widget.onTabSelected(ScreenIndex.search.value, "");
                          },
                          child: const Icon(Icons.search, size: 24),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // For You Section Header
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.yourSuggestions,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (!_isLoadingSuggestions && suggestedSongs.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              // Check if any song has a valid audio URL
                              final playableSongs =
                                  suggestedSongs
                                      .where(
                                        (song) => song.getAudioUrl().isNotEmpty,
                                      )
                                      .toList();

                              if (playableSongs.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Không có bài hát nào có thể phát',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              PlayerController.getInstance().loadSongs(
                                suggestedSongs,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đang phát gợi ý của bạn'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
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
                                Text(AppLocalizations.of(context)!.playAll),
                              ],
                            ),
                          ),
                        IconButton(
                          icon:
                              _isLoadingSuggestions
                                  ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  )
                                  : const Icon(Icons.refresh),
                          onPressed:
                              _isLoadingSuggestions
                                  ? null
                                  : () {
                                    _loadSuggestedSongs();

                                    // Show feedback to user
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Đang tải gợi ý mới...'),
                                        duration: Duration(seconds: 1),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                  },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Suggested Songs - Horizontally Scrollable Groups of Vertical Lists
              SizedBox(
                height: 265,
                child:
                    _isLoadingSuggestions
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Đang tải gợi ý...',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                        : suggestedSongs.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.music_note_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Không có gợi ý bài hát',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              TextButton(
                                onPressed: _loadSuggestedSongs,
                                child: Text('Thử lại'),
                              ),
                            ],
                          ),
                        )
                        : PageView.builder(
                          itemCount: suggestedSongGroups.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPageIndex = index;
                            });
                          },
                          itemBuilder: (context, groupIndex) {
                            return _buildSongGroup(
                              suggestedSongGroups[groupIndex],
                            );
                          },
                        ),
              ),

              // Scroll Indicator Dots
              if (!_isLoadingSuggestions &&
                  suggestedSongs.isNotEmpty &&
                  suggestedSongGroups.length > 1)
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
                          color:
                              _currentPageIndex == index
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

              // Public Playlists Section
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 32.0,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.public, color: Colors.green, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.publicPlaylists,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Public Playlists Horizontal List
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SizedBox(
                  height: 220,
                  child:
                      _isLoadingPublicPlaylists
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.loadingPublicPlaylists,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : publicPlaylists.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.playlist_play,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.noPublicPlaylists,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: publicPlaylists.length,
                            itemBuilder: (context, index) {
                              final playlist = publicPlaylists[index];
                              return PlaylistItem(
                                playlist: playlist,
                                isHorizontal: false,
                                showTrailingControls: false,
                                onTap: () {
                                  widget.onTabSelected(
                                    ScreenIndex.playlist.value,
                                    playlist.id,
                                  );
                                },
                              );
                            },
                          ),
                ),
              ),

              // Friends Playlists Section
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 32.0,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.people, color: Colors.blue, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.friendsPlaylists,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Friends Playlists Horizontal List
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SizedBox(
                  height: 220,
                  child:
                      _isLoadingFriendsPlaylists
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.loadingFriendsPlaylists,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : friendsPlaylists.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.noFriendsPlaylists,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: friendsPlaylists.length,
                            itemBuilder: (context, index) {
                              final playlist = friendsPlaylists[index];
                              return PlaylistItem(
                                playlist: playlist,
                                isHorizontal: false,
                                showTrailingControls: false,
                                onTap: () {
                                  widget.onTabSelected(
                                    ScreenIndex.playlist.value,
                                    playlist.id,
                                  );
                                },
                              );
                            },
                          ),
                ),
              ),

              // Albums Section
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 32.0,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.album, color: Colors.orange, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.allAlbums,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Albums Horizontal List
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SizedBox(
                  height: 220,
                  child:
                      _isLoadingAlbums
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)!.loadingAlbums,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : albums.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.album_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)!.noAlbums,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: albums.length,
                            itemBuilder: (context, index) {
                              final album = albums[index];
                              return AlbumItem(
                                album: album,
                                isHorizontal: false,
                                onTap: () {
                                  widget.onTabSelected(
                                    ScreenIndex.album.value,
                                    album.id.toString(),
                                  );
                                },
                              );
                            },
                          ),
                ),
              ),

              // Add some bottom padding
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSongGroup(List<Song> songs) {
    return Column(children: songs.map((song) => _buildSongItem(song)).toList());
  }

  Widget _buildSongItem(Song suggestedSong) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SongItem(song: suggestedSong),
    );
  }
}
