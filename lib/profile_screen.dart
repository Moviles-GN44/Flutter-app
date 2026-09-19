import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.showBottomNav = true});

  /// The shell provides its own bottom bar, so it hides this one.
  final bool showBottomNav;

  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color primaryOrange = Color(0xFFFFAB00);
  static const Color avatarColor = Color(0xFFFFCD78);
  static const Color primaryText = Color(0xFF292A2E);
  static const Color secondaryText = Color(0xFF8793A4);
  static const Color inactiveNavColor = Color(0xFF8090A5);
  static const Color dividerColor = Color(0xFFE5E8EC);

  @override
  Widget build(BuildContext context) {
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
                        const _ProfileAvatar(),

                        const SizedBox(height: 17),

                        const Text(
                          'Maria Ramirez',
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'Member since 2024',
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 37),

                        const _StatisticsRow(),

                        const SizedBox(height: 34),

                        const _ProfileMenuItem(
                          icon: Icons.star_border_rounded,
                          title: 'Favorites',
                        ),

                        const _ProfileMenuItem(
                          icon: Icons.access_time_rounded,
                          title: 'Visit History',
                        ),

                        const _ProfileMenuItem(
                          icon: Icons.tune_rounded,
                          title: 'Preferences',
                        ),

                        const _ProfileMenuItem(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              // Logout functionality can be connected later.
                            },
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
      bottomNavigationBar: showBottomNav
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
  const _ProfileAvatar();

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
      child: const Text(
        'MR',
        style: TextStyle(
          color: Color(0xFF28221A),
          fontSize: 31,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StatisticsRow extends StatelessWidget {
  const _StatisticsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatisticItem(
            number: '32',
            label: 'Reviews',
          ),
        ),
        Expanded(
          child: _StatisticItem(
            number: '14',
            label: 'Favorites',
          ),
        ),
        Expanded(
          child: _StatisticItem(
            number: '210',
            label: 'Points',
          ),
        ),
      ],
    );
  }
}

class _StatisticItem extends StatelessWidget {
  final String number;
  final String label;

  const _StatisticItem({
    required this.number,
    required this.label,
  });

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

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigation can be connected later.
      },
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Icon(
                icon,
                size: 20,
                color: const Color(0xFF777C82),
              ),
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

  const _AppBottomNavigationBar({
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: ProfileScreen.dividerColor,
            width: 1,
          ),
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
                const Expanded(
                  child: SizedBox(),
                ),
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
            Icon(
              icon,
              size: 20,
              color: itemColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontSize: 9,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}