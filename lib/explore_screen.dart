import 'package:flutter/material.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/models/restaurant_filters.dart';
import 'package:uniandes_food/screens/restaurant/restaurant_detail_screen.dart';
import 'package:uniandes_food/utils/currency.dart';
import 'package:uniandes_food/services/filter_suggestion_service.dart';
import 'package:uniandes_food/viewmodels/auth_view_model.dart';
import 'package:uniandes_food/viewmodels/explore_view_model.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    this.showBottomNav = true,
    this.authViewModel,
  });

  /// The screen brings its own navigation bar when it runs on its own
  /// (preview mode). Inside [MainShell] the shell already provides one.
  final bool showBottomNav;

  /// The session, used to suggest the student's usual filters.
  final AuthViewModel? authViewModel;

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
  static const _allCategories = 'All';

  late final ExploreViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ExploreViewModel(auth: widget.authViewModel);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _openRestaurant(Restaurant restaurant) {
    _viewModel.openRestaurant(restaurant);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => _buildScreen(context),
    );
  }

  Widget _buildScreen(BuildContext context) {
    final filters = _viewModel.filters;

    return Scaffold(
      backgroundColor: ExploreScreen.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ExploreHeader(
              categories: [_allCategories, ..._viewModel.categories],
              selectedCategory: filters.category ?? _allCategories,
              onCategorySelected: (String category) {
                _viewModel.selectCategory(
                  category == _allCategories ? null : category,
                );
              },
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: _viewModel.showingResults
                    ? _ResultsView(
                        results: _viewModel.results,
                        isLoading: _viewModel.isLoading,
                        errorMessage: _viewModel.errorMessage,
                        measuredFrom: _viewModel.measuredFrom,
                        onEditFilters: _viewModel.editFilters,
                        onClearFilters: _viewModel.clearFilters,
                        onOpen: _openRestaurant,
                      )
                    : _buildFilters(context),
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

  Widget _buildFilters(BuildContext context) {
    final filters = _viewModel.filters;
    final budget = RangeValues(
      filters.minPrice.toDouble(),
      filters.maxPrice.toDouble(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_viewModel.suggestion case final suggestion?) ...[
            _SuggestionCard(
              suggestion: suggestion,
              onApply: _viewModel.useSuggestion,
            ),
            const SizedBox(height: 22),
          ],

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
              Text(
                'From ${_viewModel.measuredFrom}',
                style: const TextStyle(
                  color: ExploreScreen.primaryOrange,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              for (final (i, minutes)
                  in ExploreViewModel.walkingTimeOptions.indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _WalkingTimeOption(
                    label: '< $minutes min',
                    isSelected: filters.maxWalkingMinutes == minutes,
                    onTap: () => _viewModel.selectWalkingTime(minutes),
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
                '${formatCop(filters.minPrice)} – '
                '${formatCop(filters.maxPrice)} COP',
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
              rangeTrackShape: const RectangularRangeSliderTrackShape(),
              showValueIndicator: ShowValueIndicator.never,
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
            ),
            child: RangeSlider(
              values: budget,
              min: RestaurantFilters.minBudget.toDouble(),
              max: RestaurantFilters.maxBudget.toDouble(),
              // Steps of $1.000, the way prices are written on campus.
              divisions: RestaurantFilters.maxBudget ~/ 1000,
              onChanged: (RangeValues values) {
                _viewModel.setBudget(values.start.round(), values.end.round());
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
              for (final option in DietaryOption.values)
                _DietaryChip(
                  label: option.label,
                  isSelected: filters.dietary.contains(option),
                  onTap: () => _viewModel.toggleDietary(option),
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
              for (final method in ExploreViewModel.paymentOptions)
                _PaymentChip(
                  label: method,
                  isSelected: filters.paymentMethods.contains(method),
                  onTap: () => _viewModel.togglePayment(method),
                ),
            ],
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _viewModel.applyFilters,
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
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
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
              const Icon(Icons.check_rounded, color: Colors.white, size: 16),
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
        decoration: BoxDecoration(
          color: isSelected
              ? ExploreScreen.primaryOrange
              : ExploreScreen.chipBackground,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          widthFactor: 1,
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
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({
    required this.results,
    required this.isLoading,
    required this.errorMessage,
    required this.measuredFrom,
    required this.onEditFilters,
    required this.onClearFilters,
    required this.onOpen,
  });

  final List<Restaurant> results;
  final bool isLoading;
  final String? errorMessage;
  final String measuredFrom;
  final VoidCallback onEditFilters;
  final VoidCallback onClearFilters;
  final ValueChanged<Restaurant> onOpen;

  @override
  Widget build(BuildContext context) {
    final count = results.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: onEditFilters,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Edit filters'),
                style: TextButton.styleFrom(
                  foregroundColor: ExploreScreen.primaryText,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const Spacer(),
              Text(
                isLoading
                    ? 'Loading…'
                    : '$count ${count == 1 ? 'result' : 'results'}',
                style: const TextStyle(
                  color: ExploreScreen.secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: switch ((isLoading, errorMessage, count)) {
            (true, _, _) => const Center(child: CircularProgressIndicator()),
            (_, final String message?, 0) => _EmptyResults(
              title: message,
              detail: 'Check your connection and try again.',
            ),
            (_, _, 0) => _EmptyResults(
              title: 'No restaurants match your filters',
              detail: 'Try a longer walk or a wider budget.',
              actionLabel: 'Clear filters',
              onAction: onClearFilters,
            ),
            _ => ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: count,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _ResultCard(
                restaurant: results[index],
                measuredFrom: measuredFrom,
                onTap: () => onOpen(results[index]),
              ),
            ),
          },
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.restaurant,
    required this.measuredFrom,
    required this.onTap,
  });

  final Restaurant restaurant;
  final String measuredFrom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final dietary = [
      for (final option in DietaryOption.values)
        if (option.isOfferedBy(r)) option.label,
    ];

    return Semantics(
      button: true,
      label:
          '${r.name}, ${r.walkingMinutes} minutes from $measuredFrom, '
          '${r.waitTime.spokenLabel}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ExploreScreen.dividerColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: ExploreScreen.chipBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(r.foodIcon, color: ExploreScreen.primaryText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ExploreScreen.primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: ExploreScreen.primaryOrange,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          r.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: ExploreScreen.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        r.category,
                        if (r.priceRange.isNotEmpty) r.priceRange,
                      ].join(' · '),
                      style: const TextStyle(
                        color: ExploreScreen.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${r.walkingMinutes} min from $measuredFrom · '
                      '${r.waitTime.shortLabel} wait',
                      style: const TextStyle(
                        color: ExploreScreen.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (dietary.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final label in dietary) _DietaryTag(label),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DietaryTag extends StatelessWidget {
  const _DietaryTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F5F2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF0B5F57),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({
    required this.title,
    required this.detail,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: ExploreScreen.secondaryText,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ExploreScreen.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ExploreScreen.secondaryText,
                fontSize: 14,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Smart feature: the filters this student keeps using, one tap away.
class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion, required this.onApply});

  final FilterSuggestion suggestion;
  final VoidCallback onApply;

  static String _describe(RestaurantFilters filters) => [
    ?filters.category,
    if (filters.maxWalkingMinutes case final minutes?) '< $minutes min',
    if (filters.hasBudget)
      '${formatCop(filters.minPrice)} – ${formatCop(filters.maxPrice)}',
    for (final option in filters.dietary) option.label,
    ...filters.paymentMethods,
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final searches = suggestion.basedOn;
    final description = _describe(suggestion.filters);

    return Semantics(
      container: true,
      label:
          'Suggested for you: $description, based on your last '
          '$searches searches',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F5F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ExploreScreen.teal),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF12897E),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Suggested for you',
                    style: TextStyle(
                      color: Color(0xFF0B5F57),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: ExploreScreen.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Based on your last $searches searches',
                    style: const TextStyle(
                      color: ExploreScreen.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onApply,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0B5F57),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Apply'),
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
          top: BorderSide(color: ExploreScreen.dividerColor, width: 1),
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
