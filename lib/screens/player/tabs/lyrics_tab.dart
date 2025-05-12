import 'package:flutter/material.dart';
import '../../../controller/player_controller.dart';
import 'shared_mini_player.dart';
import 'shared_tab_navigator.dart';

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

class _LyricsTabState extends State<LyricsTab> {
  final PlayerController _playerController = PlayerController.getInstance();
  final int _tabIndex = 1; // This is the "LỜI NHẠC" tab (index 1)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF1E0811), // Dark maroon background
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
              child: Center(
                child: Text(
                  "Lời bài hát",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
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
