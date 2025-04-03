import 'package:flutter/material.dart';

import '../../models/song.dart';

class SongPlayerScreen extends StatelessWidget {
  final Song song;

  const SongPlayerScreen({Key? key, required this.song}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Now Playing"),
        backgroundColor: const Color(0xFF1F1033),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(
                  Icons.music_note,
                  size: 80,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              song.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.artist,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
                  onPressed: () {},
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: IconButton(
                    icon: const Icon(Icons.pause, color: Colors.white, size: 36),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF1F1033),
    );
  }
}