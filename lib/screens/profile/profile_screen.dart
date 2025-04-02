import 'package:flutter/material.dart';
import '../abstract_navigation_screen.dart';

class ProfileScreen extends AbstractScreen {
  const ProfileScreen({super.key});

  @override
  final String title = "Profile";

  @override
  final Icon icon = const Icon(Icons.person);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Profile Screen", style: TextStyle(fontSize: 24)),
    );
  }
}
