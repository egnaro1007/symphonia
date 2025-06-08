import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    final localizations = AppLocalizations.of(context)!;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTabItem(localizations.upNext, 0),
          _buildTabItem(localizations.lyrics, 1),
          _buildTabItem(localizations.info, 2),
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
          color:
              isPressed
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: isSelected ? 60 : 40,
              height: 3,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
