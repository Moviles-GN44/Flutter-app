import 'package:flutter/material.dart';
import 'profile_screen.dart';

void main() {
  runApp(const ProfilePreviewApp());
}

class ProfilePreviewApp extends StatelessWidget {
  const ProfilePreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProfileScreen(),
    );
  }
}