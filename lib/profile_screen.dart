import 'package:flutter/material.dart';

import 'package:uniandes_food/data/campus.dart';
import 'package:uniandes_food/models/app_user.dart';
import 'package:uniandes_food/viewmodels/profile_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.showBottomNav = true,
    this.onLogout,
    this.user,
    this.preferredBuilding,
    this.onChangeBuilding,
  });

  /// The shell provides its own bottom bar, so it hides this one.
  final bool showBottomNav;
  final VoidCallback? onLogout;

  /// The signed-in student. Null only in the standalone preview.
  final AppUser? user;

  /// Building code saved in the student's account (`ML`, `SD`…).
  final String? preferredBuilding;

  /// Saves a new preferred building in the student's account.
  final ValueChanged<String>? onChangeBuilding;

  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color primaryOrange = Color(0xFFFFAB00);
  static const Color avatarColor = Color(0xFFFFCD78);
  static const Color primaryText = Color(0xFF292A2E);
  static const Color secondaryText = Color(0xFF8793A4);
  static const Color inactiveNavColor = Color(0xFF8090A5);
  static const Color dividerColor = Color(0xFFE5E8EC);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileViewModel? _viewModel;

  static const backgroundColor = ProfileScreen.backgroundColor;
  static const primaryOrange = ProfileScreen.primaryOrange;
  static const primaryText = ProfileScreen.primaryText;
  static const secondaryText = ProfileScreen.secondaryText;

  @override
  void initState() {
    super.initState();
    _createViewModel();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user?.uid != widget.user?.uid) {
      _viewModel?.dispose();
      _createViewModel();
    }
  }

  void _createViewModel() {
    final user = widget.user;
    _viewModel = user == null ? null : ProfileViewModel(user: user);
  }

  Future<void> _chooseBuilding() async {
    final current = widget.preferredBuilding;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(
                  'Preferred building',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Used for walking times when GPS is not available.',
                  style: TextStyle(color: secondaryText, fontSize: 13),
                ),
              ),
              for (final entry in campusBuildingNames.entries)
                ListTile(
                  leading: const Icon(
                    Icons.apartment_rounded,
                    color: Color(0xFF12897E),
                  ),
                  title: Text(entry.value),
                  trailing: entry.key == current
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF12897E),
                        )
                      : null,
                  selected: entry.key == current,
                  selectedColor: const Color(0xFF0B5F57),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () => Navigator.of(context).pop(entry.key),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null || choice == current) return;
    widget.onChangeBuilding?.call(choice);
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel;
    if (viewModel == null) return _buildScreen(null);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => _buildScreen(viewModel),
    );
  }

  Widget _buildScreen(ProfileViewModel? viewModel) {
    final building = widget.preferredBuilding;
    final reviewCount = viewModel?.reviewCount;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _ProfileHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 38, 28, 28),
                    child: Column(
                      children: [
                        _ProfileAvatar(initials: viewModel?.initials ?? '?'),

                        const SizedBox(height: 17),

                        Text(
                          viewModel?.displayName ?? 'Guest',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: primaryText,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          widget.user?.email ?? 'Not signed in',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: secondaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 37),

                        _StatisticsRow(
                          reviews: reviewCount == null ? '–' : '$reviewCount',
                          building: building ?? '–',
                          buildingName: campusBuildingNames[building],
                        ),

                        const SizedBox(height: 34),

                        _ProfileMenuItem(
                          icon: Icons.apartment_rounded,
                          title: 'Preferred building',
                          value: campusBuildingNames[building] ?? 'Not set',
                          onTap: widget.onChangeBuilding == null
                              ? null
                              : _chooseBuilding,
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: widget.onLogout,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: primaryOrange,
                              foregroundColor: primaryText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Log out',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const _AppBottomNavigationBar(selectedIndex: 4)
          : null,
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 60,
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Profile',
            style: TextStyle(
              color: ProfileScreen.primaryText,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 106,
      height: 106,
      decoration: const BoxDecoration(
        color: ProfileScreen.avatarColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF28221A),
          fontSize: 31,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StatisticsRow extends StatelessWidget {
  const _StatisticsRow({
    required this.reviews,
    required this.building,
    this.buildingName,
  });

  final String reviews;
  final String building;
  final String? buildingName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatisticItem(number: reviews, label: 'Reviews'),
        ),
        Expanded(
          child: Semantics(
            label: 'Preferred building: ${buildingName ?? 'none'}',
            excludeSemantics: true,
            child: _StatisticItem(
              number: building,
              label: 'Preferred building',
            ),
          ),
        ),
      ],
    );
  }
}

class _StatisticItem extends StatelessWidget {
  final String number;
  final String label;

  const _StatisticItem({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            color: ProfileScreen.primaryText,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: ProfileScreen.secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Icon(icon, size: 20, color: const Color(0xFF777C82)),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF777C82),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (value case final value?)
              Text(
                value,
                style: const TextStyle(
                  color: ProfileScreen.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF868B90),
              size: 23,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;

  const _AppBottomNavigationBar({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: ProfileScreen.dividerColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Row(
              children: [
                Expanded(
                  child: _NavigationItem(
                    icon: Icons.location_on_outlined,
                    label: 'Map',
                    isSelected: selectedIndex == 0,
                  ),
                ),
                Expanded(
                  child: _NavigationItem(
                    icon: Icons.explore_outlined,
                    label: 'Explore',
                    isSelected: selectedIndex == 1,
                  ),
                ),
                const Expanded(child: SizedBox()),
                Expanded(
                  child: _NavigationItem(
                    icon: Icons.favorite_border_rounded,
                    label: 'Favorites',
                    isSelected: selectedIndex == 3,
                  ),
                ),
                Expanded(
                  child: _NavigationItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    isSelected: selectedIndex == 4,
                  ),
                ),
              ],
            ),

            Positioned(
              top: 5,
              child: GestureDetector(
                onTap: () {
                  // QR screen navigation can be connected later.
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: ProfileScreen.primaryOrange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: ProfileScreen.primaryText,
                    size: 25,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final Color itemColor = isSelected
        ? ProfileScreen.primaryOrange
        : ProfileScreen.inactiveNavColor;

    return InkWell(
      onTap: () {
        // Navigation can be connected later.
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 11),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: itemColor),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
