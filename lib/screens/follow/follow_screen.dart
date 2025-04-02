import 'package:flutter/material.dart';
import '../abstract_navigation_screen.dart';

class FollowScreen extends AbstractScreen {
  const FollowScreen({super.key});

  @override
  final String title = "Follow";

  @override
  final Icon icon = const Icon(Icons.subscriptions);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Follow Screen", style: TextStyle(fontSize: 24)),
    );
  }
}
