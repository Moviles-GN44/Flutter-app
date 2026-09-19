import 'package:flutter/material.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color primaryOrange = Color(0xFFFFAB00);
  static const Color primaryText = Color(0xFF292A2E);
  static const Color secondaryText = Color(0xFF8793A4);
  static const Color inactiveNavColor = Color(0xFF8090A5);
  static const Color dividerColor = Color(0xFFE5E8EC);
  static const Color coral = Color(0xFFFF6F61);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _FavoritesHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Restaurants',
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    SizedBox(height: 16),

                    _RestaurantCard(
                      name: 'El Corral Uniandes',
                      imagePath: 'assets/restaurants/el_corral.webp',
                    ),

                    SizedBox(height: 14),

                    _RestaurantCard(
                      name: 'Verde Bowl',
                      imagePath: 'assets/restaurants/verde_bowl.jpg',
                    ),

                    SizedBox(height: 14),

                    _RestaurantCard(
                      name: 'Sushi Nikkei',
                      imagePath: 'assets/restaurants/sushi_nikkei.webp',
                    ),

                    SizedBox(height: 14),

                    _RestaurantCard(
                      name: 'Wok',
                      imagePath: 'assets/restaurants/wok.webp',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _AppBottomNavigationBar(
        selectedIndex: 3,
      ),
    );
  }
}

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Favorites',
            style: TextStyle(
              color: FavoritesScreen.primaryText,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),

          SizedBox(height: 4),

          Text(
            'Maria Ramirez',
            style: TextStyle(
              color: FavoritesScreen.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),

          SizedBox(height: 8),

          Row(
            children: [
              Icon(
                Icons.star_rounded,
                color: FavoritesScreen.primaryOrange,
                size: 18,
              ),

              SizedBox(width: 3),

              Text(
                '4.5',
                style: TextStyle(
                  color: FavoritesScreen.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(width: 14),

              Text(
                '187 restaurants',
                style: TextStyle(
                  color: FavoritesScreen.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final String name;
  final String imagePath;

  const _RestaurantCard({
    required this.name,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 102,
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: FavoritesScreen.dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 70,
              height: 80,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stackTrace,
                ) {
                  return Container(
                    color: const Color(0xFFF1F1F1),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: FavoritesScreen.secondaryText,
                      size: 30,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FavoritesScreen.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                const Row(
                  children: [
                    _WaitingTimeTag(),
                    SizedBox(width: 6),
                    _DietaryTag(),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 5),

          IconButton(
            onPressed: () {
              // Remove from favorites functionality can be added later.
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            icon: const Icon(
              Icons.favorite_border_rounded,
              color: FavoritesScreen.coral,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingTimeTag extends StatelessWidget {
  const _WaitingTimeTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 23,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: FavoritesScreen.primaryOrange,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hourglass_bottom_rounded,
            color: FavoritesScreen.primaryText,
            size: 12,
          ),

          SizedBox(width: 3),

          Text(
            '5-15 MIN',
            style: TextStyle(
              color: FavoritesScreen.primaryText,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DietaryTag extends StatelessWidget {
  const _DietaryTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 23,
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: FavoritesScreen.coral,
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: FavoritesScreen.coral,
            size: 11,
          ),

          SizedBox(width: 3),

          Text(
            'NUT-FREE',
            style: TextStyle(
              color: FavoritesScreen.coral,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
            color: FavoritesScreen.dividerColor,
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
                  decoration: const BoxDecoration(
                    color: FavoritesScreen.primaryOrange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: FavoritesScreen.primaryText,
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
        ? FavoritesScreen.primaryOrange
        : FavoritesScreen.inactiveNavColor;

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