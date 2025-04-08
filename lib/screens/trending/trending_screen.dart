import 'package:flutter/material.dart';
import 'package:symphonia/screens/trending/song_list.dart';
import 'package:symphonia/screens/trending/trending_chart.dart';
import 'package:symphonia/screens/trending/trending_header.dart';
import 'package:symphonia/services/song.dart';
import '../../models/song.dart';
import '../abstract_navigation_screen.dart';

class TrendingScreen extends AbstractScreen {
  const TrendingScreen({super.key});

  @override
  final String title = "Trending";

  @override
  final Icon icon = const Icon(Icons.timeline);

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

            // Chart area
            TrendingChart(),

            const Divider(height: 1, color: Colors.white24),

            // Song list using FutureBuilder
            FutureBuilder<List<Song>>(
              future: _futureSongs,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No songs found.'));
                }

                final songs = snapshot.data!;
                return SongList(songs: songs);
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
