import 'dart:developer';

import 'package:flutter/material.dart';

class PlayerScreen extends StatefulWidget {
  final VoidCallback closePlayer;

  const PlayerScreen({super.key, required this.closePlayer});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: Icon(Icons.expand_more, color: Colors.white),
              onPressed: widget.closePlayer,
            ),
            title: Text("Player", style: TextStyle(color: Colors.white)),
          ),
          Expanded(
            child: IconButton(onPressed: () => {
              log("Play button pressed"),
            }, icon: Icon(Icons.play_circle_outline, size: 100, color: Colors.white)),

            // child: Center(
            //   child: Icon(Icons.play_circle_outline, size: 100, color: Colors.white),
            // ),
          ),
        ],
      ),
    );
  }
}