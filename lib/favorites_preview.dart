import 'package:flutter/material.dart';
import 'favorites_screen.dart';

void main() {
  runApp(const FavoritesPreviewApp());
}

class FavoritesPreviewApp extends StatelessWidget {
  const FavoritesPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FavoritesScreen(),
    );
  }
}