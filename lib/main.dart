import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:uniandes_food/screens/main_shell.dart';
import 'package:uniandes_food/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const UniandesFoodApp());
}

class UniandesFoodApp extends StatelessWidget {
  const UniandesFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uniandes Food',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainShell(),
    );
  }
}