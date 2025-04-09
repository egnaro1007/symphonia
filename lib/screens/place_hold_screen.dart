import 'package:flutter/material.dart';
import 'abstract_navigation_screen.dart';

class PlaceHoldScreen extends AbstractScreen {
  const PlaceHoldScreen({super.key, required super.onTabSelected});

  @override
  final String title = "PlaceHold";

  @override
  final Icon icon = const Icon(Icons.error);

  @override
  State<PlaceHoldScreen> createState() => _PlaceHoldScreenState();
}

class _PlaceHoldScreenState extends State<PlaceHoldScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("PlaceHold Screen", style: TextStyle(fontSize: 24)),
    );
  }
}
