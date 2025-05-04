import 'package:flutter/material.dart';
import 'package:symphonia/models/playlist.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/models/search_result.dart';
import 'package:symphonia/screens/abstract_navigation_screen.dart';
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

class _SearchPageState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController(text: "");
  List<String> _searchSuggestions = [];
  List<SearchResult> _searchResults = [];
  bool _isSearchSubmitted = false;

  @override
  void initState() {
    super.initState();
    _updateSearchSuggestions(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearchSuggestions(String query) {
    var suggestions = Searching.searchSuggestions(query);
    setState(() {
      _searchSuggestions = suggestions;
      _isSearchSubmitted = false;
    });
  }

  void _updateSearchResults(String query) async {
    var results = await Searching.searchResults(query);
    setState(() {
      _searchResults = results;
      _isSearchSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
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
                              _updateSearchSuggestions(value);
                            },
                            onSubmitted: (value) {
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
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    TabBar(
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
                        children: [
                          // Songs tab
                          _buildResultsTab<SongSearchResult>(
                            (result) => _buildSongResult(
                              result
                            ),
                          ),
                          // Artists tab
                          _buildResultsTab<ArtistSearchResult>(
                            (result) => _buildArtistResult(
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
              ),
            )
          // Suggestions
          else
            Expanded(
              flex: 1,
              child: ListView(
                children: _searchSuggestions.map((suggestion) {
                  return ListTile(
                    leading: Icon(Icons.search, color: Colors.grey),
                    title: Text(suggestion),
                    dense: true,
                    onTap: () {
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
    return ListView(
      children: filteredResults.map(builder).toList(),
    );
  }

  Widget _buildSongResult(SongSearchResult result) {
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
          child: Icon(Icons.music_note),
        ),
      ),
      title: Text(
        result.name,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(result.artist),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.play_circle_outline),
            onPressed: () {
              Song song = Song(
                title: result.name,
                artist: result.artist,
                imagePath: result.image,
                audioUrl: result.audio_url,
              );
              PlayerController.getInstance().loadSong(song);
            }
          ),
          SizedBox(width: 16),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              _showSongOptions(context, result.name);
            },
          ),
        ],
      ),
    );
  }

  void _showSongOptions(BuildContext context, String songTitle) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.download),
              title: Text('Tải về'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.favorite_border),
              title: Text('Thêm vào thư viện'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.playlist_add),
              title: Text('Thêm vào playlist'),
              onTap: () async {
                // Get all local playlists
                List<PlayList> localPlaylists = await PlayListOperations.getLocalPlaylists();

                // Show playlist options
                showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return ListView.builder(
                      itemCount: localPlaylists.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(localPlaylists[index].title),
                          onTap: () {
                            // Add song to the selected playlist
                            // PlayListOperations.addSongToPlaylist(songTitle, localPlaylists[index]);
                            // Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.auto_awesome),
              title: Text('Phát bài hát & nội dung tương tự'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.queue_music),
              title: Text('Thêm vào danh sách phát'),
              onTap: () {},
            ),
          ],
        );
      },
    );
  }

  Widget _buildArtistResult(String name, String subtitle, String imagePath) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Icon(Icons.person),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right),
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
      title: Text(
        name,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
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
      title: Text(
        name,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
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