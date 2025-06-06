import 'package:flutter/material.dart';

class SharedTabNavigator extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTabTap;

  const SharedTabNavigator({
    super.key,
    required this.selectedIndex,
    required this.onTabTap,
  });

  @override
  State<SharedTabNavigator> createState() => _SharedTabNavigatorState();
}

class _SharedTabNavigatorState extends State<SharedTabNavigator> {
  int? pressedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E0811),
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTabItem("TIẾP THEO", 0),
          _buildTabItem("LỜI NHẠC", 1),
          _buildTabItem("THÔNG TIN", 2),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isSelected =
        widget.selectedIndex >= 0 && widget.selectedIndex == index;
    final isPressed = pressedIndex == index;

    return InkWell(
      onTap: () => widget.onTabTap(index),
      onTapDown: (_) => setState(() => pressedIndex = index),
      onTapUp: (_) => setState(() => pressedIndex = null),
      onTapCancel: () => setState(() => pressedIndex = null),
      borderRadius: BorderRadius.circular(8),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPressed ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: isSelected ? 60 : 40,
              height: 3,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
