import 'package:flutter/material.dart';
import '../abstract_navigation_screen.dart';

class HomeScreen extends AbstractScreen {
  const HomeScreen({super.key});

  @override
  final String title = "Home";

  @override
  final Icon icon = const Icon(Icons.home);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Home Screen", style: TextStyle(fontSize: 24)),
    );
  }
}