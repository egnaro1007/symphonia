import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../controller/player_controller.dart';
import '../../../services/token_manager.dart'; // Import token manager for API calls
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import for server URL
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'shared_mini_player.dart';
import 'shared_tab_navigator.dart';

// Model class for timed lyrics
class LyricsLine {
  final double startTime;
  final String text;
  final double duration;
  final GlobalKey key = GlobalKey(); // Each line gets its own key

  LyricsLine({
    required this.startTime,
    required this.text,
    required this.duration,
  });

  factory LyricsLine.fromJson(Map<String, dynamic> json) {
    return LyricsLine(
      startTime: json['startTime']?.toDouble() ?? 0.0,
      text: json['text'] ?? "",
      duration: json['duration']?.toDouble() ?? 0.0,
    );
  }
}

class LyricsTab extends StatefulWidget {
  final VoidCallback onTopBarTap;
  final Function(int) onTabChange;

  const LyricsTab({
    super.key,
    required this.onTopBarTap,
    required this.onTabChange,
  });

  @override
  State<LyricsTab> createState() => _LyricsTabState();
}

class _LyricsTabState extends State<LyricsTab>
    with AutomaticKeepAliveClientMixin {
  final PlayerController _playerController = PlayerController.getInstance();
  final int _tabIndex = 1; // This is the "LỜI NHẠC" tab (index 1)

  // Add state variables for lyrics
  late Future<List<LyricsLine>> _lyricsFuture;

  // Current highlighted line index
  int _currentLineIndex = -1;
  List<LyricsLine> _lyricsLines = [];

  // For lyrics timing
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;
  bool _userTapped = false; // Track if user manually tapped a line

  // Subscriptions
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _songChangeSubscription;

  // For scrolling
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false; // Track if auto-scrolling is in progress
  bool _isUserScrolling = false; // Track if the user is actively scrolling

  // Keep scroll position when switching tabs
  bool _isInitialized = false;

  // Track current song to detect changes
  String _currentSongId = '';

  // Add state variable to track if lyrics exist
  bool _hasLyrics = true;

  @override
  bool get wantKeepAlive => true; // This is key to keep the state when switching tabs

  @override
  void initState() {
    super.initState();
    _initializeTab();
  }

  void _initializeTab() {
    if (_isInitialized) return;

    // Initialize lyrics future
    _fetchLyrics();

    // Set up listeners for player state and position
    _setupPlayerListeners();

    // Add listener for user scroll activity
    _scrollController.addListener(_handleUserScroll);

    // Listen for song changes to refresh lyrics
    _songChangeSubscription = _playerController.onSongChange.listen((song) {
      final newSongId = song.id.toString();
      if (_currentSongId != newSongId) {
        _currentSongId = newSongId;
        // Reset states
        _currentLineIndex = -1;
        _lyricsLines = [];
        _fetchLyrics();

        // Reset scroll position
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      }
    });

    _isInitialized = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Make sure initialization happens even if the widget is rebuilt
    _initializeTab();

    // Force update current line and scroll position when tab becomes visible
    if (_isInitialized && _lyricsLines.isNotEmpty) {
      _playerController.getCurrentPosition().then((position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _updateCurrentLine();
          });
          // Ensure scrolling to current line happens after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToCurrentLine();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    // Clean up subscriptions
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _songChangeSubscription?.cancel();
    _scrollController.removeListener(_handleUserScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Handle user scroll activity
  void _handleUserScroll() {
    if (_scrollController.position.userScrollDirection !=
        ScrollDirection.idle) {
      _isUserScrolling = true;
    } else {
      // Add a short delay before re-enabling auto-scroll
      // This prevents auto-scroll from triggering immediately after user finishes scrolling
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _isUserScrolling = false;
        }
      });
    }
  }

  // Set up listeners for player state and position
  void _setupPlayerListeners() {
    // Listen to position changes
    _positionSubscription = _playerController.onPositionChanged.listen((
      position,
    ) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          // Only update line if not recently tapped by user and user is not scrolling
          if (!_userTapped && !_isUserScrolling) {
            _updateCurrentLine();
          } else if (_userTapped) {
            // Reset the user tapped flag after a short delay
            Future.delayed(const Duration(milliseconds: 500), () {
              _userTapped = false;
            });
          }
        });
      }
    });

    // Listen for player state changes
    _playerController.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    // Get initial state
    _isPlaying = _playerController.isPlaying();

    // Get current position and force sync of the lyrics
    _playerController.getCurrentPosition().then((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _updateCurrentLine();
        });

        // Ensure we scroll to the current line after the build is complete
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCurrentLine();
        });
      }
    });

    // Get initial song ID
    _currentSongId = _playerController.playingSong.id.toString();
  }

  // Handle tap on a lyrics line
  void _handleLineTap(int index) {
    if (index < 0 || index >= _lyricsLines.length) return;

    final tapTime = Duration(
      milliseconds: (_lyricsLines[index].startTime * 1000).round(),
    );

    // Set user tapped flag
    _userTapped = true;
    _isUserScrolling = false; // Allow auto-scroll after tap

    // Update the current line index
    setState(() {
      _currentLineIndex = index;
    });

    // Seek to the start time of the tapped line
    _playerController.seek(tapTime);

    // Scroll to make the tapped line visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLine();
    });
  }

  // Update current line based on the current playback position
  void _updateCurrentLine() {
    if (_lyricsLines.isEmpty) return;

    final currentTimeInSeconds = _currentPosition.inMilliseconds / 1000;
    int newLineIndex = -1;

    // Find the current line based on the playback position
    for (int i = 0; i < _lyricsLines.length; i++) {
      final line = _lyricsLines[i];
      // A line is current if current time is between its start time and (start time + duration)
      if (currentTimeInSeconds >= line.startTime &&
          currentTimeInSeconds <= (line.startTime + line.duration)) {
        newLineIndex = i;
        break;
      }
    }

    // If we couldn't find a current line by exact time match, use the line that's coming up next
    if (newLineIndex == -1 && currentTimeInSeconds > 0) {
      for (int i = 0; i < _lyricsLines.length; i++) {
        if (_lyricsLines[i].startTime > currentTimeInSeconds) {
          newLineIndex = i - 1;
          break;
        }
      }

      // If still not found, it might be past the last line
      if (newLineIndex == -1 && _lyricsLines.isNotEmpty) {
        // Check if we're past the last line
        final lastLine = _lyricsLines.last;
        if (currentTimeInSeconds > lastLine.startTime + lastLine.duration) {
          newLineIndex = _lyricsLines.length - 1;
        }
      }
    }

    // Only update if line has changed and user is not scrolling
    if (newLineIndex != _currentLineIndex &&
        newLineIndex >= 0 &&
        !_isUserScrolling) {
      setState(() {
        _currentLineIndex = newLineIndex;
      });

      // Schedule the scroll after the build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentLine();
      });
    }
  }

  // Scroll to make the current line visible in the middle of the viewport
  void _scrollToCurrentLine() {
    if (_currentLineIndex < 0 || _currentLineIndex >= _lyricsLines.length) {
      return;
    }

    if (_isScrolling || _isUserScrolling) {
      return;
    }

    // Ensure the widget is still mounted before trying to access context or scroll.
    if (!mounted) {
      return;
    }

    final currentLine = _lyricsLines[_currentLineIndex];
    final GlobalKey key = currentLine.key;


    if (key.currentContext != null) {
      setState(() {
        // Set _isScrolling to true to prevent concurrent scrolls
        _isScrolling = true;
      });

      Scrollable.ensureVisible(
        key.currentContext!,
        alignment: 0.5, // Center the item in the viewport
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).whenComplete(() {
        if (mounted) {
          setState(() {
            _isScrolling = false; // Reset flag when scroll completes
          });
        }
      });
    } else {
      // Calculate more accurate item height by measuring text
      // Get the text style and constraints to calculate actual height
      final textStyle = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);

      // Calculate cumulative height up to current line
      double targetOffset = 0.0;
      final screenWidth =
          MediaQuery.of(context).size.width -
          48.0; // Account for horizontal padding

      for (int i = 0; i < _currentLineIndex; i++) {
        final line = _lyricsLines[i];
        if (line.text.trim().isEmpty) {
          targetOffset += 16.0; // Empty line height
        } else {
          // Calculate text height for this line
          final textPainter = TextPainter(
            text: TextSpan(text: line.text, style: textStyle),
            maxLines: null,
            textDirection: TextDirection.ltr,
          );
          textPainter.layout(maxWidth: screenWidth);

          // Add text height + margins + padding
          targetOffset +=
              textPainter.height + 16.0 + 8.0; // margin (8*2) + padding (4*2)
        }
      }

      // Ensure the offset is within the scrollable range if controller is ready.
      if (_scrollController.hasClients &&
          _scrollController.position.hasContentDimensions) {
        targetOffset = targetOffset.clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
      } else {
        return;
      }

      _scrollController.jumpTo(targetOffset);

      // After jumping, the item should hopefully be built in the next frame.
      // Schedule another attempt to scroll, ensuring it's properly visible and centered.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (key.currentContext != null) {
          setState(() {
            // Set _isScrolling to true
            _isScrolling = true;
          });
          Scrollable.ensureVisible(
            key.currentContext!,
            alignment: 0.5,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ).whenComplete(() {
            if (mounted) {
              setState(() {
                _isScrolling = false; // Reset flag
              });
            }
          });
        } else {
          // If still null, the item wasn't built, or GlobalKey isn't attached correctly.
          // This might happen if calculated height is still off or other complex layout issues.
          // print('Warning: Lyrics line context STILL null after jump and retry for index $_currentLineIndex.');
        }
      });
    }
  }

  // Method to fetch lyrics from backend API
  void _fetchLyrics() {
    setState(() {
      _lyricsFuture = _loadLyricsFromBackend().then((lyrics) {
        // After lyrics are loaded, immediately update the current line based on playback position
        _lyricsLines = lyrics;
        _playerController.getCurrentPosition().then((position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
              _updateCurrentLine();
            });

            // Ensure we scroll to the current line after the build is complete
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToCurrentLine();
            });
          }
        });
        return lyrics;
      });
    });
  }

  // Load lyrics from backend API
  Future<List<LyricsLine>> _loadLyricsFromBackend() async {
    try {
      // Get current playing song
      final currentSong = _playerController.playingSong;

      // For all songs, try to fetch from backend
      final lyricsData = await _fetchLyricsFromAPI(currentSong.id);

      if (lyricsData != null && lyricsData.isNotEmpty) {
        // Convert API data to LyricsLine objects using local method
        _hasLyrics = true;
        return _parseLyricsData(lyricsData);
      } else {
        // No lyrics available
        _hasLyrics = false;
        return []; // Return empty list for no lyrics case
      }
    } catch (e) {
      // On error, no lyrics available
      _hasLyrics = false;
      return []; // Return empty list for error case
    }
  }

  // Fetch lyrics from API
  Future<List<dynamic>?> _fetchLyricsFromAPI(int songId) async {
    String? serverUrl = dotenv.env['SERVER_URL'];
    if (serverUrl == null) {
      return null;
    }

    try {
      final url = Uri.parse('$serverUrl/api/library/songs/$songId/');

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${TokenManager.accessToken}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['lyric'] as List<dynamic>?;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Parse lyrics data to LyricsLine objects
  List<LyricsLine> _parseLyricsData(List<dynamic> lyricsData) {
    return lyricsData.map((entry) {
      return LyricsLine.fromJson(entry as Map<String, dynamic>);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Required for AutomaticKeepAliveClientMixin to work
    super.build(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E0811), Color(0xFF0A0205)],
          ),
        ),
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
              child: FutureBuilder<List<LyricsLine>>(
                future: _lyricsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error loading lyrics: ${snapshot.error}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    );
                  } else {
                    // Get lyrics lines
                    _lyricsLines = snapshot.data ?? [];

                    // Check if we have lyrics or not
                    if (!_hasLyrics || _lyricsLines.isEmpty) {
                      // No lyrics case - show centered message
                      return const Center(
                        child: Text(
                          "Hiện chưa có lời bài hát.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else {
                      // Has lyrics case - show scrollable lyrics
                      return Column(
                        children: [
                          // Lyrics content
                          Expanded(
                            child: Center(
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (scrollNotification) {
                                  if (scrollNotification
                                      is UserScrollNotification) {
                                    if (scrollNotification.direction !=
                                        ScrollDirection.idle) {
                                      _isUserScrolling = true;
                                    } else {
                                      // Add a short delay before re-enabling auto-scroll
                                      Future.delayed(
                                        const Duration(milliseconds: 1000),
                                        () {
                                          if (mounted) {
                                            _isUserScrolling = false;
                                          }
                                        },
                                      );
                                    }
                                  }
                                  return false;
                                },
                                child: Scrollbar(
                                  thumbVisibility: true,
                                  controller: _scrollController,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0,
                                      vertical: 16.0,
                                    ),
                                    itemCount: _lyricsLines.length,
                                    itemBuilder: (context, index) {
                                      final line = _lyricsLines[index];

                                      // Skip empty lines
                                      if (line.text.trim().isEmpty) {
                                        return const SizedBox(height: 16);
                                      }

                                      final isCurrentLine =
                                          index == _currentLineIndex;

                                      return GestureDetector(
                                        onTap: () => _handleLineTap(index),
                                        child: Container(
                                          key:
                                              line.key, // Apply the GlobalKey to this widget
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4.0,
                                          ),
                                          child: Text(
                                            line.text,
                                            style: TextStyle(
                                              color:
                                                  isCurrentLine
                                                      ? Colors.white
                                                      : Colors.white
                                                          .withOpacity(0.4),
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Handle tab selection - switch tabs directly without navigation
  void _handleTabTap(int index) {
    if (index == _tabIndex) return; // Already on this tab
    widget.onTabChange(index);
  }
}
