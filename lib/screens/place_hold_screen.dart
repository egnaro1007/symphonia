import 'package:flutter/material.dart';
import 'abstract_navigation_screen.dart';

class PlaceHoldScreen extends AbstractScreen {
  const PlaceHoldScreen({super.key});

  @override
  final String title = "PlaceHold";

  @override
  final Icon icon = const Icon(Icons.error);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("PlaceHold Screen", style: TextStyle(fontSize: 24)),
    );
  }

}
