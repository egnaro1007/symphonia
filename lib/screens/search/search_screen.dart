import 'package:flutter/material.dart';
import 'package:symphonia/models/playlist.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/models/search_result.dart';
import 'package:symphonia/screens/abstract_navigation_screen.dart';
import 'package:symphonia/services/like.dart';
import 'package:symphonia/services/playlist.dart';
import 'package:symphonia/services/searching.dart';
import '../../controller/player_controller.dart';

class SearchScreen extends AbstractScreen {
  const SearchScreen({super.key, required super.onTabSelected});

  @override
  _SearchPageState createState() => _SearchPageState();

  @override
  Icon get icon => Icon(Icons.search);

  @override
  String get title => "Search";
}

class _SearchPageState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController(
    text: "",
  );
  List<String> _searchSuggestions = [];
  List<SearchResult> _searchResults = [];
  bool _isSearchSubmitted = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (_searchController.text.isNotEmpty) {
      _updateSearchSuggestions(_searchController.text);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _updateSearchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions = [];
        _isSearchSubmitted = false;
      });
      return;
    }
    var suggestions = await Searching.searchSuggestions(query);
    if (mounted && !_isSearchSubmitted) {
      setState(() {
        _searchSuggestions = suggestions;
      });
    }
  }

  void _updateSearchResults(String query) async {
    var results = await Searching.searchResults(query);
    setState(() {
      _searchResults = results;
      _isSearchSubmitted = true;
    });

    final songsCount = _searchResults.whereType<SongSearchResult>().length;
    final artistsCount = _searchResults.whereType<ArtistSearchResult>().length;
    final albumsCount = _searchResults.whereType<AlbumSearchResult>().length;

    int targetTabIndex = 0;
    if (songsCount > 0) {
      targetTabIndex = 0;
    } else if (artistsCount > 0) {
      targetTabIndex = 1;
    } else if (albumsCount > 0) {
      targetTabIndex = 2;
    }

    _tabController.animateTo(targetTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(backgroundColor: Colors.white, elevation: 0),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    // Reset search state
                    _searchController.clear();
                    setState(() {
                      _searchSuggestions = [];
                      _searchResults = [];
                      _isSearchSubmitted = false;
                    });
                    // Navigate back
                    widget.onTabSelected(0, "");
                  },
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF1F1F1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Search",
                            ),
                            onChanged: (value) {
                              setState(() {
                                _isSearchSubmitted = false;
                              });
                              _updateSearchSuggestions(value);
                            },
                            onSubmitted: (value) {
                              FocusScope.of(context).unfocus();
                              _updateSearchResults(value);
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _isSearchSubmitted = false;
                              _searchResults = [];
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1),

          // Search results
          if (_isSearchSubmitted)
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.deepPurple,
                    tabs: [
                      Tab(text: "Songs"),
                      Tab(text: "Artists"),
                      Tab(text: "Albums"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Songs tab
                        _buildResultsTab<SongSearchResult>(
                          (result) => _buildSongResult(result),
                        ),
                        // Artists tab
                        _buildResultsTab<ArtistSearchResult>(
                          (result) => _buildArtistResult(
                            result.id.toString(),
                            result.name,
                            "Artist",
                            result.image,
                          ),
                        ),
                        // Albums tab
                        _buildResultsTab<AlbumSearchResult>(
                          (result) => _buildAlbumResult(
                            result.name,
                            result.artist,
                            result.image,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          // Suggestions
          else
            Expanded(
              flex: 1,
              child: ListView(
                children:
                    _searchSuggestions.map((suggestion) {
                      return ListTile(
                        leading: Icon(Icons.search, color: Colors.grey),
                        title: Text(suggestion),
                        dense: true,
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          _searchController.text = suggestion;
                          _updateSearchResults(suggestion);
                        },
                      );
                    }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsTab<T>(Widget Function(T result) builder) {
    final filteredResults = _searchResults.whereType<T>().cast<T>().toList();
    if (filteredResults.isEmpty) {
      return Center(child: Text("No results found"));
    }
    return ListView(children: filteredResults.map(builder).toList());
  }

  Widget _buildSongResult(SongSearchResult result) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child:
              (result.image.isNotEmpty)
                  ? Image.network(
                    result.image,
                    fit: BoxFit.cover,
                    width: 50,
                    height: 50,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback in case of error loading image
                      return Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.music_note,
                          color: Colors.grey.shade700,
                        ),
                      );
                    },
                    loadingBuilder: (
                      BuildContext context,
                      Widget child,
                      ImageChunkEvent? loadingProgress,
                    ) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade300,
                        child: Center(
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                          ),
                        ),
                      );
                    },
                  )
                  : Container(
                    // Fallback if no image URL
                    width: 50,
                    height: 50,
                    color: Colors.grey.shade300,
                    child: Icon(Icons.music_note, color: Colors.grey.shade700),
                  ),
        ),
      ),
      title: Text(result.name, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(result.artist),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.play_circle_outline),
            onPressed: () {
              Song song = Song(
                id: result.id,
                title: result.name,
                artist: result.artist,
                imagePath: result.image,
                audioUrl: result.audio_url,
              );
              PlayerController.getInstance().loadSong(song);
            },
          ),
          SizedBox(width: 16),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              Song song = Song(
                id: result.id,
                title: result.name,
                artist: result.artist,
                imagePath: result.image,
                audioUrl: result.audio_url,
              );
              _showSongOptions(context, song);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showSongOptions(BuildContext context, Song song) async {
    bool _isLike = await LikeOperations.getLikeStatus(song);

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.queue_play_next),
              title: Text('Thêm vào danh dách phát tiếp'),
              onTap: () {
                PlayerController.getInstance().loadSong(song, false);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.download),
              title: Text('Tải về'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(_isLike ? Icons.favorite : Icons.favorite_border),
              title: Text(_isLike ? 'Bỏ khỏi yêu thích' : 'Thêm vào yêu thích'),
              onTap: () async {
                if (_isLike) {
                  if (await LikeOperations.unlike(song)) {
                    _isLike = false;
                  }
                } else {
                  if (await LikeOperations.like(song)) {
                    _isLike = true;
                  }
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.playlist_add),
              title: Text('Thêm vào playlist'),
              onTap: () async {
                List<PlayList> localPlaylists =
                    await PlayListOperations.getLocalPlaylists();

                showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return ListView.builder(
                      itemCount: localPlaylists.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(localPlaylists[index].title),
                          onTap: () {
                            PlayListOperations.addSongToPlaylist(
                              localPlaylists[index].id,
                              song.id.toString(),
                            );
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildArtistResult(
    String id,
    String name,
    String subtitle,
    String imagePath,
  ) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: ClipOval(child: Icon(Icons.person)),
      ),
      title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right),
      onTap: () {},
    );
  }

  Widget _buildAlbumResult(String name, String artist, String imagePath) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Icon(Icons.playlist_play),
        ),
      ),
      title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(artist),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_outline),
          SizedBox(width: 16),
          Icon(Icons.more_vert),
        ],
      ),
    );
  }

  Widget _buildPlaylistResult(String name, String artist, String imagePath) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Icon(Icons.playlist_play),
        ),
      ),
      title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(artist),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_outline),
          SizedBox(width: 16),
          Icon(Icons.more_vert),
        ],
      ),
    );
  }
}
