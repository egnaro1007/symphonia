import 'package:flutter/material.dart';
import '../abstract_navigation_screen.dart';

class FollowScreen extends AbstractScreen {
  @override
  final String title = "Follow";

  @override
  final Icon icon = const Icon(Icons.subscriptions);

  FollowScreen({required super.onTabSelected});

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
