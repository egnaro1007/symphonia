import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:symphonia/controller/player_controller.dart';

import 'package:symphonia/models/song.dart';
import 'package:symphonia/services/song.dart';
import 'package:symphonia/widgets/song_item.dart';
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
                        TextButton(
                          onPressed: () {
                            PlayerController.getInstance().loadSongs(
                              suggestedSongs,
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
                height: 265,
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
