import 'package:flutter/material.dart';

abstract class AbstractScreen extends StatefulWidget {
  const AbstractScreen({super.key});

  String get title;
  Icon get icon;
}
