import 'package:flutter/material.dart';
import '../abstract_navigation_screen.dart';

class FollowScreen extends AbstractScreen {
  const FollowScreen({super.key});

  @override
  final String title = "Follow";

  @override
  final Icon icon = const Icon(Icons.subscriptions);

  @override
  State<FollowScreen> createState() => _FollowScreenState();
}

class _FollowScreenState extends State<FollowScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Follow Screen", style: TextStyle(fontSize: 24)),
    );
  }
}
