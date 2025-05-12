import 'package:flutter/material.dart';
import '../../../controller/player_controller.dart';
import 'shared_mini_player.dart';
import 'shared_tab_navigator.dart';

class NextTrackTab extends StatefulWidget {
  final VoidCallback onTopBarTap;
  final Function(int) onTabChange;

  const NextTrackTab({
    super.key,
    required this.onTopBarTap,
    required this.onTabChange,
  });

  @override
  State<NextTrackTab> createState() => _NextTrackTabState();
}

class _NextTrackTabState extends State<NextTrackTab> {
  final PlayerController _playerController = PlayerController.getInstance();
  final int _tabIndex = 0; // This is the "TIẾP THEO" tab (index 0)

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
                  "Danh sách phát tiếp theo",
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
