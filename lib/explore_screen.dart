import 'package:flutter/material.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.showBottomNav = true});

  /// The screen brings its own navigation bar when it runs on its own
  /// (preview mode). Inside [MainShell] the shell already provides one.
  final bool showBottomNav;

  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color primaryOrange = Color(0xFFFFAB00);
  static const Color primaryText = Color(0xFF292A2E);
  static const Color secondaryText = Color(0xFF8793A4);
  static const Color inactiveNavColor = Color(0xFF8090A5);
  static const Color dividerColor = Color(0xFFE5E8EC);
  static const Color teal = Color(0xFF2EC4B6);
  static const Color chipBackground = Color(0xFFEFF1F4);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const List<String> _categories = [
    'Executive Lunch',
    'Fast Food',
    'Healthy',
    'Post',
    'Coffee',
  ];

  static const List<String> _walkingTimes = ['< 5 min', '< 10 min', '< 15 min'];

  static const List<String> _dietaryOptions = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Nut-Free',
  ];

  static const List<String> _paymentMethods = [
    'Cash',
    'Card',
    'Nequi',
    'Daviplata',
  ];

  String _selectedCategory = 'Executive Lunch';
  String _selectedWalkingTime = '< 5 min';
  RangeValues _budget = const RangeValues(5000, 25000);
  final Set<String> _selectedDietary = {'Vegetarian', 'Vegan'};
  final Set<String> _selectedPayments = {};
  bool _openNow = true;

  String _formatPrice(double value) {
    final int rounded = (value / 1000).round() * 1000;
    final String digits = rounded.toString();
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }

    return '\$${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExploreScreen.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ExploreHeader(
              categories: _categories,
              selectedCategory: _selectedCategory,
              onCategorySelected: (String category) {
                setState(() => _selectedCategory = category);
              },
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Advanced Filters',
                        style: TextStyle(
                          color: ExploreScreen.primaryText,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _SectionTitle('Walking Time'),

                          Row(
                            children: const [
                              Text(
                                'From ML',
                                style: TextStyle(
                                  color: ExploreScreen.primaryOrange,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              SizedBox(width: 2),

                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: ExploreScreen.primaryOrange,
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          for (int i = 0; i < _walkingTimes.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(
                              child: _WalkingTimeOption(
                                label: _walkingTimes[i],
                                isSelected:
                                    _selectedWalkingTime == _walkingTimes[i],
                                onTap: () {
                                  setState(
                                    () => _selectedWalkingTime =
                                        _walkingTimes[i],
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 22),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _SectionTitle('Budget'),

                          Text(
                            '${_formatPrice(_budget.start)} – '
                            '${_formatPrice(_budget.end)} COP',
                            style: const TextStyle(
                              color: ExploreScreen.secondaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          activeTrackColor: ExploreScreen.primaryOrange,
                          inactiveTrackColor: ExploreScreen.dividerColor,
                          thumbColor: Colors.white,
                          overlayColor: const Color(0x1FFFAB00),
                          rangeThumbShape: const RoundRangeSliderThumbShape(
                            enabledThumbRadius: 9,
                          ),
                          rangeTrackShape:
                              const RectangularRangeSliderTrackShape(),
                          showValueIndicator: ShowValueIndicator.never,
                        ),
                        child: RangeSlider(
                          values: _budget,
                          min: 0,
                          max: 50000,
                          onChanged: (RangeValues values) {
                            setState(() => _budget = values);
                          },
                        ),
                      ),

                      const SizedBox(height: 14),

                      const _SectionTitle('Dietary Restrictions'),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final String option in _dietaryOptions)
                            _DietaryChip(
                              label: option,
                              isSelected: _selectedDietary.contains(option),
                              onTap: () {
                                setState(() {
                                  if (_selectedDietary.contains(option)) {
                                    _selectedDietary.remove(option);
                                  } else {
                                    _selectedDietary.add(option);
                                  }
                                });
                              },
                            ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      const _SectionTitle('Payment Method'),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final String method in _paymentMethods)
                            _PaymentChip(
                              label: method,
                              isSelected: _selectedPayments.contains(method),
                              onTap: () {
                                setState(() {
                                  if (_selectedPayments.contains(method)) {
                                    _selectedPayments.remove(method);
                                  } else {
                                    _selectedPayments.add(method);
                                  }
                                });
                              },
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: ExploreScreen.teal,
                            size: 22,
                          ),

                          const SizedBox(width: 10),

                          const Expanded(
                            child: Text(
                              'Open Now',
                              style: TextStyle(
                                color: ExploreScreen.primaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          Switch(
                            value: _openNow,
                            activeThumbColor: Colors.white,
                            activeTrackColor: ExploreScreen.teal,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: ExploreScreen.dividerColor,
                            onChanged: (bool value) {
                              setState(() => _openNow = value);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            // Applying the filters can be connected later.
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ExploreScreen.primaryOrange,
                            foregroundColor: ExploreScreen.primaryText,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              fontSize: 17,
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
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const _AppBottomNavigationBar(selectedIndex: 1)
          : null,
    );
  }
}

class _ExploreHeader extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const _ExploreHeader({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: ExploreScreen.backgroundColor,
      padding: const EdgeInsets.only(top: 18, bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Explore',
              style: TextStyle(
                color: ExploreScreen.primaryText,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (BuildContext context, int index) {
                final String category = categories[index];

                return _CategoryChip(
                  label: category,
                  isSelected: selectedCategory == category,
                  onTap: () => onCategorySelected(category),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isSelected ? ExploreScreen.primaryOrange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? ExploreScreen.primaryOrange
                : ExploreScreen.dividerColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: ExploreScreen.primaryText,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: ExploreScreen.primaryText,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _WalkingTimeOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _WalkingTimeOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : ExploreScreen.chipBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? ExploreScreen.primaryOrange
                : ExploreScreen.chipBackground,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? ExploreScreen.primaryText
                : ExploreScreen.secondaryText,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DietaryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DietaryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? ExploreScreen.teal : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? ExploreScreen.teal : ExploreScreen.dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
            ],

            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : ExploreScreen.primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? ExploreScreen.primaryOrange
              : ExploreScreen.chipBackground,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? ExploreScreen.primaryText
                : ExploreScreen.secondaryText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
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
            color: ExploreScreen.dividerColor,
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
                    color: ExploreScreen.primaryOrange,
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
                    color: ExploreScreen.primaryText,
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
        ? ExploreScreen.primaryOrange
        : ExploreScreen.inactiveNavColor;

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
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
