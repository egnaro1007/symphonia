import 'package:flutter/material.dart';
import '../abstract_navigation_screen.dart';

class TrendingScreen extends AbstractScreen {
  const TrendingScreen({super.key});

  @override
  final String title = "Trending";

  @override
  final Icon icon = const Icon(Icons.timeline);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Trending Screen", style: TextStyle(fontSize: 24)),
    );
  }

}
