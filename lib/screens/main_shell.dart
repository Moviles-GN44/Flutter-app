import 'package:flutter/material.dart';

import 'package:uniandes_food/explore_screen.dart';
import 'package:uniandes_food/favorites_screen.dart';
import 'package:uniandes_food/navigation/app_navigation.dart';
import 'package:uniandes_food/profile_screen.dart';
import 'package:uniandes_food/screens/home/home_screen.dart';
import 'package:uniandes_food/screens/review/scan_qr_screen.dart';
import 'package:uniandes_food/viewmodels/home_view_model.dart';
import 'package:uniandes_food/widgets/app_bottom_nav.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final HomeViewModel _homeViewModel;

  @override
  void initState() {
    super.initState();
    _homeViewModel = HomeViewModel();
  }

  @override
  void dispose() {
    _homeViewModel.dispose();
    super.dispose();
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScanQrScreen(
          restaurant: _homeViewModel.selectedRestaurant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _homeViewModel,
      builder: (context, _) {
        return ValueListenableBuilder<int>(
          valueListenable: AppNavigation.tab,
          builder: (context, tab, _) => Scaffold(
            body: IndexedStack(
              index: tab,
              children: [
                HomeScreen(viewModel: _homeViewModel),
                const ExploreScreen(showBottomNav: false),
                const FavoritesScreen(showBottomNav: false),
                const ProfileScreen(showBottomNav: false),
              ],
            ),
            floatingActionButton: ScanFab(onPressed: _openScanner),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: AppBottomNav(
              currentIndex: tab,
              onSelect: (index) => AppNavigation.tab.value = index,
            ),
          ),
        );
      },
    );
  }
}