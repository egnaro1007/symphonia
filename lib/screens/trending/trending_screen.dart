import 'package:flutter/material.dart';
import 'package:symphonia/screens/trending/song_list.dart';
import 'package:symphonia/screens/trending/trending_chart.dart';
import 'package:symphonia/screens/trending/trending_header.dart';
import 'package:symphonia/services/song.dart';
import '../../models/song.dart';
import '../abstract_navigation_screen.dart';

class TrendingScreen extends AbstractScreen {
  @override
  final String title = "Trending";

  @override
  final Icon icon = const Icon(Icons.timeline);

  const TrendingScreen({super.key, required super.onTabSelected});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  late Future<List<Song>> _futureSongs;

  @override
  void initState() {
    super.initState();
    _futureSongs = SongOperations.getTrendingSongs(); // initialize once
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.deepPurple,
        child: Column(
          children: [
            // Top header
            TrendingHeader(),

            // Chart area with song list using FutureBuilder
            FutureBuilder<List<Song>>(
              future: _futureSongs,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Expanded(
                    child: Column(
                      children: [
                        // Empty chart area while loading
                        SizedBox(
                          height: 180, // Cập nhật theo chiều cao mới
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        const SizedBox(height: 4),
                        const Divider(height: 1, color: Colors.white24),
                        Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ],
                    ),
                  );
                }

                final songs = snapshot.data!;
                return Expanded(
                  child: Column(
                    children: [
                      // Chart with song data
                      TrendingChart(songs: songs),
                      const Divider(height: 1, color: Colors.white24),
                      // Song list
                      SongList(songs: songs),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
