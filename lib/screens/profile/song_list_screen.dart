import 'dart:async';
import 'package:flutter/material.dart';
import 'package:symphonia/controller/player_controller.dart';
import 'package:symphonia/models/song.dart';
import 'package:symphonia/screens/abstract_navigation_screen.dart';
import 'package:symphonia/services/data_event_manager.dart';
import 'package:symphonia/widgets/song_item.dart';

class SongListScreen extends AbstractScreen {
  final String screenTitle;
  final Future<List<Song>> Function() songsLoader;
  final IconData titleIcon;
  final Color titleColor;

  const SongListScreen({
    super.key,
    required this.screenTitle,
    required this.songsLoader,
    required this.titleIcon,
    required this.titleColor,
    required super.onTabSelected,
  });

  @override
  String get title => screenTitle;

  @override
  Icon get icon => Icon(titleIcon);

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  late Future<List<Song>> _songsFuture;
  StreamSubscription<DataEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _songsFuture = widget.songsLoader();
    _setupEventListener();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  void _setupEventListener() {
    _eventSubscription = DataEventManager.instance.events.listen((event) {
      // Check if this event is relevant to this screen
      bool shouldRefresh = false;

      switch (widget.screenTitle) {
        case 'Yêu thích':
          shouldRefresh = event.type == DataEventType.likeChanged;
          break;
        case 'Đã tải':
          shouldRefresh = event.type == DataEventType.downloadChanged;
          break;
        case 'Nghe gần đây':
          shouldRefresh = event.type == DataEventType.historyChanged;
          break;
        default:
          shouldRefresh = false;
      }

      if (shouldRefresh) {
        _refreshData();
      }
    });
  }

  void _refreshData() {
    setState(() {
      _songsFuture = widget.songsLoader();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            widget.onTabSelected(-1, "");
          },
        ),
        title: Row(
          children: [
            Icon(widget.titleIcon, color: widget.titleColor, size: 24),
            const SizedBox(width: 8),
            Text(
              widget.screenTitle,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: FutureBuilder<List<Song>>(
        future: _songsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${snapshot.error}'),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.titleIcon, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có bài hát nào trong ${widget.screenTitle}',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          } else {
            final songs = snapshot.data!;
            return Column(
              children: [
                // Header section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.titleColor.withOpacity(0.1),
                        Colors.white,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.titleColor.withOpacity(0.2),
                        ),
                        child: Icon(
                          widget.titleIcon,
                          size: 60,
                          color: widget.titleColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        widget.screenTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Stats
                      Text(
                        '${songs.length} bài hát',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Play all button
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (songs.isNotEmpty) {
                            try {
                              // Reload songs to ensure fresh data before playing
                              final freshSongs = await widget.songsLoader();
                              if (freshSongs.isNotEmpty) {
                                PlayerController.getInstance().loadSongs(
                                  freshSongs,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Không có bài hát nào để phát',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } catch (e) {
                              PlayerController.getInstance().loadSongs(
                                songs,
                              ); // Fallback
                            }
                          }
                        },
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        label: const Text(
                          'PHÁT TẤT CẢ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.titleColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Song list
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        return SongItem(
                          song: songs[index],
                          showTrailingControls: true,
                          isHorizontal: true,
                          index: index,
                          showIndex: false,
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
