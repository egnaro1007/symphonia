import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/models/search_result.dart';
import 'package:symphonia/models/album.dart';
import 'package:symphonia/models/artist.dart';
import 'package:symphonia/screens/abstract_navigation_screen.dart';
import 'package:symphonia/services/searching.dart';
import 'package:symphonia/services/album.dart';
import 'package:symphonia/widgets/song_item.dart';
import 'package:symphonia/widgets/album_item.dart';
import 'package:symphonia/widgets/artist_item.dart';
import 'package:symphonia/constants/screen_index.dart';

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
                    widget.onTabSelected(ScreenIndex.home.value, "");
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
                              hintText: AppLocalizations.of(context)!.search,
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
                      Tab(text: AppLocalizations.of(context)!.songs),
                      Tab(text: AppLocalizations.of(context)!.artists),
                      Tab(text: AppLocalizations.of(context)!.albums),
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
                          (result) => _buildArtistResult(result),
                        ),
                        // Albums tab
                        _buildResultsTab<AlbumSearchResult>(
                          (result) => _buildAlbumResult(result),
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
      return Center(child: Text(AppLocalizations.of(context)!.noResultsFound));
    }
    return ListView(children: filteredResults.map(builder).toList());
  }

  Widget _buildSongResult(SongSearchResult result) {
    Song song = Song(
      id: result.id,
      title: result.name,
      artist: result.artist,
      imagePath: result.image,
      audioUrl: result.audio_url,
    );

    return SongItem(song: song);
  }

  Widget _buildArtistResult(ArtistSearchResult result) {
    // Convert ArtistSearchResult to Artist for widget compatibility
    Artist artist = ArtistItem.createArtistFromSearchResult(
      id: result.id,
      name: result.name,
      image: result.image,
    );

    return ArtistItem(
      artist: artist,
      isHorizontal: true,
      showTrailingControls: false,
      onTabSelected: widget.onTabSelected,
      onArtistUpdate: () {
        // Handle artist update if needed
      },
    );
  }

  Widget _buildAlbumResult(AlbumSearchResult result) {
    // Convert AlbumSearchResult to Album for widget compatibility
    Album album = AlbumOperations.createSimpleAlbum(
      id: result.id,
      title: result.name,
      artist: result.artist,
      coverArt: result.image,
      releaseDate: result.releaseDate,
    );

    return AlbumItem(
      album: album,
      isHorizontal: true,
      showTrailingControls: true,
      onTap: () {
        // Navigate to album screen
        widget.onTabSelected(ScreenIndex.album.value, album.id.toString());
      },
      onAlbumUpdate: () {
        // Handle album update if needed
        print('Album updated: ${album.title}');
      },
    );
  }
}
