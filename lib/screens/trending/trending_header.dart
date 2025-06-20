import 'package:flutter/material.dart';

class TrendingHeader extends StatelessWidget {
  const TrendingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Gradient text using ShaderMask
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.orange, Colors.pink, Colors.blue],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: const Text(
              '#symchart',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white, // This color is used as the base that the shader will apply to
              ),
            ),
          ),
        ],
      ),
    );
  }
}