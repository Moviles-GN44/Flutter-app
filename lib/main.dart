import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:uniandes_food/screens/main_shell.dart';
import 'package:uniandes_food/theme/app_theme.dart';
import 'package:uniandes_food/viewmodels/auth_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //inicializa firebase
  await Firebase.initializeApp();

  runApp(const UniandesFoodApp());
}

class UniandesFoodApp extends StatefulWidget {
  const UniandesFoodApp({super.key});

  @override
  State<UniandesFoodApp> createState() => _UniandesFoodAppState();
}

class _UniandesFoodAppState extends State<UniandesFoodApp> {
  late final AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    _authViewModel = AuthViewModel();
  }

  @override
  void dispose() {
    _authViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uniandes Food',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: MainShell(authViewModel: _authViewModel), // vista principal de la aplicación
    );
  }
}