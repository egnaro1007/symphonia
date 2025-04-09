import 'package:flutter/material.dart';

abstract class AbstractScreen extends StatefulWidget {
  final void Function(int, String) onTabSelected;
  const AbstractScreen({super.key, required this.onTabSelected});

  String get title;
  Icon get icon;
}
