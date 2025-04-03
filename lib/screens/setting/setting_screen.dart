import 'package:flutter/material.dart';
import '../abstract_navigation_screen.dart';

class SettingScreen extends AbstractScreen {
  const SettingScreen({super.key});

  @override
  final String title = "settings";

  @override
  final Icon icon = const Icon(Icons.settings);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Settings Screen", style: TextStyle(fontSize: 24)),
    );
  }
}
