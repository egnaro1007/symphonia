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
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  Map<String, dynamic>? _rawSearchData;
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
        _rawSearchData = null;
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
    print('Starting search for: $query'); // Debug log
    var results = await Searching.searchResults(query);
    var rawData = await Searching.getRawSearchData(query);
    print(
      'Search completed. Results: ${results.length}, Raw data: ${rawData != null}',
    ); // Debug log
    setState(() {
      _searchResults = results;
      _rawSearchData = rawData;
      _isSearchSubmitted = true;
    });

    final songsCount = _searchResults.whereType<SongSearchResult>().length;
    final artistsCount = _searchResults.whereType<ArtistSearchResult>().length;
    final albumsCount = _searchResults.whereType<AlbumSearchResult>().length;

    print(
      'Search results breakdown - Songs: $songsCount, Artists: $artistsCount, Albums: $albumsCount',
    ); // Debug log

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
            padding: EdgeInsets.only(left: 8, right: 12, top: 8, bottom: 8),
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
                      _rawSearchData = null;
                      _isSearchSubmitted = false;
                    });
                    // Navigate back
                    widget.onTabSelected(ScreenIndex.home.value, "");
                  },
                ),

                SizedBox(width: 5),

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
                              _rawSearchData = null;
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
    print(
      'Building song result for: ${result.name} by ${result.artist}',
    ); // Debug log

    // Find the raw song data that matches this result
    if (_rawSearchData != null && _rawSearchData!['songs'] != null) {
      print('Searching for raw data for song ID: ${result.id}'); // Debug log
      for (var songData in _rawSearchData!['songs']) {
        if (songData['id'] == result.id) {
          print('Found raw data for song: ${songData['title']}'); // Debug log

          // Process relative URLs to full URLs (similar to SongOperations)
          String serverUrl = dotenv.env['SERVER_URL'] ?? '';
          String serverBase = serverUrl;
          if (!serverBase.startsWith('http://') &&
              !serverBase.startsWith('https://')) {
            serverBase = 'http://$serverBase';
          }

          // Process cover_art URL
          if (songData['cover_art'] != null &&
              songData['cover_art'].toString().isNotEmpty &&
              !songData['cover_art'].toString().startsWith('http://') &&
              !songData['cover_art'].toString().startsWith('https://')) {
            songData['cover_art'] = '$serverBase${songData['cover_art']}';
          }

          // Process audio URLs in audio_urls map
          if (songData['audio_urls'] != null) {
            Map<String, dynamic> audioUrls = Map<String, dynamic>.from(
              songData['audio_urls'],
            );
            audioUrls.forEach((key, value) {
              if (value != null &&
                  value.toString().isNotEmpty &&
                  !value.toString().startsWith('http://') &&
                  !value.toString().startsWith('https://')) {
                audioUrls[key] = '$serverBase$value';
              }
            });
            songData['audio_urls'] = audioUrls;
          }

          // Process legacy audio URL
          if (songData['audio'] != null &&
              songData['audio'].toString().isNotEmpty &&
              !songData['audio'].toString().startsWith('http://') &&
              !songData['audio'].toString().startsWith('https://')) {
            songData['audio'] = '$serverBase${songData['audio']}';
          }

          // Create Song object using Song.fromJson for proper quality support
          Song song = Song.fromJson(songData);
          print(
            'Created Song object with audio URL: ${song.getAudioUrl()}',
          ); // Debug log
          return SongItem(song: song);
        }
      }
      print('No raw data found for song ID: ${result.id}'); // Debug log
    } else {
      print('No raw search data available'); // Debug log
    }

    // Fallback: create Song from SearchResult if raw data not found
    print('Using fallback Song creation for: ${result.name}'); // Debug log
    Song song = Song(
      id: result.id,
      title: result.name,
      artist: result.artist,
      imagePath: result.image,
      audioUrl: result.audio_url,
    );

    print(
      'Fallback Song created with audio URL: ${song.getAudioUrl()}',
    ); // Debug log
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
