import 'package:flutter/material.dart';
import '../../../controller/player_controller.dart';
import 'shared_mini_player.dart';
import 'shared_tab_navigator.dart';

class RelatedTab extends StatefulWidget {
  final VoidCallback onTopBarTap;
  final Function(int) onTabChange;

  const RelatedTab({
    super.key,
    required this.onTopBarTap,
    required this.onTabChange,
  });

  @override
  State<RelatedTab> createState() => _RelatedTabState();
}

class _RelatedTabState extends State<RelatedTab> {
  final PlayerController _playerController = PlayerController.getInstance();
  final int _tabIndex = 2; // This is the "LIÊN QUAN" tab (index 2)

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
                  "Bài hát liên quan",
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
