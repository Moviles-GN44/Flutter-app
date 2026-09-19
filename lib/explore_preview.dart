import 'package:flutter/material.dart';
import 'explore_screen.dart';

void main() {
  runApp(const ExplorePreviewApp());
}

class ExplorePreviewApp extends StatelessWidget {
  const ExplorePreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ExploreScreen(),
    );
  }
}
