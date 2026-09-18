import 'package:flutter/material.dart';

import 'package:uniandes_food/theme/app_colors.dart';
import 'package:uniandes_food/theme/app_text.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int? currentIndex;
  final ValueChanged<int> onSelect;

  static const _destinations = [
    _Destination('Map', Icons.map_outlined, Icons.map_rounded),
    _Destination('Explore', Icons.explore_outlined, Icons.explore_rounded),
    _Destination(
      'Favorites',
      Icons.favorite_border_rounded,
      Icons.favorite_rounded,
    ),
    _Destination('Profile', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    Widget tab(int index) => Expanded(
      child: _NavTab(
        destination: _destinations[index],
        selected: currentIndex == index,
        onTap: () => onSelect(index),
      ),
    );

    return BottomAppBar(
      color: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0x331E232A),
      elevation: 12,
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [tab(0), tab(1), const SizedBox(width: 80), tab(2), tab(3)],
      ),
    );
  }
}

class ScanFab extends StatelessWidget {
  const ScanFab({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 68,
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: 'Scan a restaurant QR code',
        backgroundColor: AppColors.amber,
        foregroundColor: AppColors.shadowGrey,
        elevation: 4,
        highlightElevation: 6,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.white, width: 4),
        ),
        child: const Icon(Icons.qr_code_scanner_rounded, size: 32),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.shadowGrey : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 56,
              height: 30,
              decoration: BoxDecoration(
                color: selected ? AppColors.amber : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              destination.label,
              style: AppText.navLabel.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
