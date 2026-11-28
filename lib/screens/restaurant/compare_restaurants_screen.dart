import 'package:flutter/material.dart';
import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/viewmodels/comparison_view_model.dart';
import 'package:uniandes_food/viewmodels/explore_view_model.dart';
import 'package:uniandes_food/utils/currency.dart';

class CompareRestaurantsScreen extends StatefulWidget {
  const CompareRestaurantsScreen({super.key, required this.exploreViewModel});

  final ExploreViewModel exploreViewModel;

  @override
  State<CompareRestaurantsScreen> createState() =>
      _CompareRestaurantsScreenState();
}

class _CompareRestaurantsScreenState extends State<CompareRestaurantsScreen> {
  final _viewModel = ComparisonViewModel();

  static const _orange = Color(0xFFFFAB00);
  static const _background = Color(0xFFF5F5F5);
  static const _textColor = Color(0xFF292A2E);

  @override
  void initState() {
    super.initState();
    _updateRestaurants();
    widget.exploreViewModel.addListener(_updateRestaurants);
    _viewModel.restoreSelection();
  }

  void _updateRestaurants() {
    _viewModel.updateRestaurants(
      widget.exploreViewModel.results,
      isFromCache: widget.exploreViewModel.isFromCache,
    );
  }

  @override
  void dispose() {
    widget.exploreViewModel.removeListener(_updateRestaurants);
    _viewModel.dispose();
    super.dispose();
  }

  String _ranking(Map<String, int>? ranks, String id) {
    final rank = ranks?[id];

    return rank == null ? 'Not available' : '#$rank';
  }

  String _price(Restaurant restaurant) {
    final price = restaurant.averagePriceCop;
    return price == null ? 'Not available' : formatCop(price);
  }

  String _dietaryOptions(Restaurant restaurant) {
    final options = <String>[
      if (restaurant.isVegan) 'Vegan',
      if (restaurant.isGlutenFree) 'Gluten-free',
      if (restaurant.isLactoseFree) 'Lactose-free',
    ];

    return options.isEmpty ? 'Not specified' : options.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _textColor,
        title: const Text('Compare Restaurants'),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final comparison = _viewModel.comparison;
          final insights = _viewModel.insights;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_viewModel.isFromCache) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFFFFF3D6),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 18,
                        color: Color(0xFF8A6200),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Showing saved restaurant data. Updates may be pending.',
                          style: TextStyle(
                            color: Color(0xFF8A6200),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const Text(
                'Compare your options',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Select two restaurants to find the best option for you.',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 24),

              _restaurantSelector(
                label: 'First restaurant',
                selected: _viewModel.firstRestaurant,
                excluded: _viewModel.secondRestaurant,
                onSelected: _viewModel.selectFirstRestaurant,
              ),

              const SizedBox(height: 12),

              _restaurantSelector(
                label: 'Second restaurant',
                selected: _viewModel.secondRestaurant,
                excluded: _viewModel.firstRestaurant,
                onSelected: _viewModel.selectSecondRestaurant,
              ),

              const SizedBox(height: 24),

              if (_viewModel.restaurants.length < 2)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      _viewModel.isFromCache
                          ? 'Not enough saved restaurants to compare. Connect to the internet to update the results.'
                          : 'Not enough restaurants match your filters. Return to Explore to change them.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else if (comparison == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Select two different restaurants to compare.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _restaurantHeader(comparison.firstRestaurant),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _restaurantHeader(comparison.secondRestaurant),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _comparisonRow(
                  icon: Icons.payments_outlined,
                  label: 'Average price',
                  first: _price(comparison.firstRestaurant),
                  second: _price(comparison.secondRestaurant),
                ),

                _comparisonRow(
                  icon: Icons.directions_walk,
                  label: 'Walking time',
                  first: '${comparison.firstRestaurant.walkingMinutes} min',
                  second: '${comparison.secondRestaurant.walkingMinutes} min',
                ),

                _comparisonRow(
                  icon: Icons.schedule,
                  label: 'Waiting time',
                  first: comparison.firstRestaurant.waitTime.shortLabel,
                  second: comparison.secondRestaurant.waitTime.shortLabel,
                ),

                _comparisonRow(
                  icon: Icons.star_outline,
                  label: 'Rating',
                  first: comparison.firstRestaurant.reviewCount == 0
                      ? 'No reviews'
                      : comparison.firstRestaurant.rating.toStringAsFixed(1),
                  second: comparison.secondRestaurant.reviewCount == 0
                      ? 'No reviews'
                      : comparison.secondRestaurant.rating.toStringAsFixed(1),
                ),

                _comparisonRow(
                  icon: Icons.eco_outlined,
                  label: 'Dietary options',
                  first: _dietaryOptions(comparison.firstRestaurant),
                  second: _dietaryOptions(comparison.secondRestaurant),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Comparison Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Rankings among available restaurants in Explore.',
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 12),

                if (_viewModel.isCalculatingInsights)
                  const Center(child: CircularProgressIndicator(color: _orange))
                else if (insights != null) ...[
                  _comparisonRow(
                    icon: Icons.payments_outlined,
                    label: 'Price ranking',
                    first: _ranking(
                      insights.priceRanks,
                      comparison.firstRestaurant.id,
                    ),
                    second: _ranking(
                      insights.priceRanks,
                      comparison.secondRestaurant.id,
                    ),
                  ),

                  _comparisonRow(
                    icon: Icons.directions_walk,
                    label: 'Walking time ranking',
                    first: _ranking(
                      insights.walkingRanks,
                      comparison.firstRestaurant.id,
                    ),
                    second: _ranking(
                      insights.walkingRanks,
                      comparison.secondRestaurant.id,
                    ),
                  ),

                  _comparisonRow(
                    icon: Icons.star_outline,
                    label: 'Rating ranking',
                    first: _ranking(
                      insights.ratingRanks,
                      comparison.firstRestaurant.id,
                    ),
                    second: _ranking(
                      insights.ratingRanks,
                      comparison.secondRestaurant.id,
                    ),
                  ),
                ] else
                  const Text(
                    'Comparison insights are currently unavailable.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),

                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: _viewModel.clearSelection,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Clear comparison'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textColor,
                    side: const BorderSide(color: _orange),
                    padding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _restaurantSelector({
    required String label,
    required Restaurant? selected,
    required Restaurant? excluded,
    required ValueChanged<Restaurant> onSelected,
  }) {
    final available = _viewModel.restaurants
        .where((restaurant) => restaurant.id != excluded?.id)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected?.id,
          isExpanded: true,
          hint: Text(label),
          items: available.map((restaurant) {
            return DropdownMenuItem<String>(
              value: restaurant.id,
              child: Text(restaurant.name, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (id) {
            if (id == null) return;

            final restaurant = available.firstWhere(
              (restaurant) => restaurant.id == id,
            );

            onSelected(restaurant);
          },
        ),
      ),
    );
  }

  Widget _restaurantHeader(Restaurant restaurant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFFFF0D0),
            child: Icon(restaurant.foodIcon, color: _textColor, size: 28),
          ),

          const SizedBox(height: 12),

          Text(
            restaurant.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          const SizedBox(height: 4),

          Text(
            restaurant.category,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _comparisonRow({
    required IconData icon,
    required String label,
    required String first,
    required String second,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _orange, size: 20),

              const SizedBox(width: 8),

              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: Text(first, textAlign: TextAlign.center)),

              Container(width: 1, height: 24, color: const Color(0xFFE5E8EC)),

              Expanded(child: Text(second, textAlign: TextAlign.center)),
            ],
          ),
        ],
      ),
    );
  }
}
