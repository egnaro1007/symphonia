import 'package:flutter/material.dart';
import 'package:symphonia/mock_data/playlist/playlist.dart';
import 'package:symphonia/services/playlist.dart';

import '../navigation_bar_screen.dart';

class PlaylistCreationScreen extends StatefulWidget {
  const PlaylistCreationScreen({Key? key}) : super(key: key);

  @override
  State<PlaylistCreationScreen> createState() => _PlaylistCreationScreenState();
}

class _PlaylistCreationScreenState extends State<PlaylistCreationScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _autoDownload = true;
  bool _isPrivate = false;
  bool _autoUpdate = false;
  bool _isButtonActive = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_checkButtonState);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _checkButtonState() {
    setState(() {
      _isButtonActive = _nameController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App bar with close button
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Playlist name label
                    const Text(
                      'Tên playlist',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),

                    // Playlist name input field
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tên của Playlist',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: UnderlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Auto download toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tự động tải',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Switch(
                          value: _autoDownload,
                          onChanged: (value) {
                            setState(() {
                              _autoDownload = value;
                            });
                          },
                          activeColor: Colors.deepPurple,
                          activeTrackColor: Colors.deepPurple.withValues(),
                        ),
                      ],
                    ),

                    // Private toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Riêng tư',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Switch(
                          value: _isPrivate,
                          onChanged: (value) {
                            setState(() {
                              _isPrivate = value;
                            });
                          },
                          activeColor: Colors.deepPurple,
                          activeTrackColor: Colors.deepPurple.withOpacity(0.5),
                        ),
                      ],
                    ),

                    // Auto update toggle (Premium feature)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Phát tuần tự',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PLUS',
                                style: TextStyle(
                                  color: Colors.deepPurple,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _autoUpdate,
                          onChanged: (value) {
                            setState(() {
                              _autoUpdate = value;
                            });
                          },
                          activeColor: Colors.deepPurple,
                          activeTrackColor: Colors.deepPurple.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom create button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isButtonActive ? () async {
                    // Get the playlist name
                    String playlistName = _nameController.text;

                    // Call the addPlaylist function from the Playlist class
                    bool success = await PlayListOperations.addPlaylist(playlistName, _isPrivate);
                    if (success) {
                      print('Playlist created successfully');
                    } else {
                      print('Failed to create playlist');
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NavigationBarScreen(selectedBottom: 3),
                      ),
                    );

                    // Navigator.pop(context);
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isButtonActive ? Colors.deepPurple : Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'TẠO PLAYLIST',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}