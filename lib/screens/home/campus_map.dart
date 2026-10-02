import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:uniandes_food/data/campus.dart';
import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/theme/app_colors.dart';
import 'package:uniandes_food/theme/app_text.dart';
import 'package:uniandes_food/viewmodels/campus_map_view_model.dart';

class CampusMap extends StatefulWidget {
  const CampusMap({
    super.key,
    required this.restaurants,
    required this.selected,
    required this.onSelect,
  });

  final List<Restaurant> restaurants;
  final Restaurant selected;
  final ValueChanged<Restaurant> onSelect;

  @override
  State<CampusMap> createState() => _CampusMapState();
}

class _CampusMapState extends State<CampusMap> {
  static const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _userAgent = 'com.uniandesfood';
  static const _pinBoxWidth = 160.0;
  static const _pinBoxHeight = 94.0;
  static const _pinSize = 44.0;
  static const _userMarkerSize = 28.0;
  static const _buildingMarkerSize = 34.0;

  // Anchors the centre of the pin's circle (not the whole box) on the point.
  static final _pinAlignment = Marker.computePixelAlignment(
    width: _pinBoxWidth,
    height: _pinBoxHeight,
    left: _pinBoxWidth / 2,
    top: _pinBoxHeight - _pinSize / 2,
  );

  final _controller = MapController(); //libreria para controlar el mapa
  late final CampusMapViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CampusMapViewModel();
  }

  @override
  void didUpdateWidget(CampusMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected.id != widget.selected.id) {
      _controller.move(widget.selected.location, _controller.camera.zoom);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _chooseLocationSource() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (_) => _LocationSourceSheet(
        current: _viewModel.isUsingGps
            ? _LocationSourceSheet.gps
            : _viewModel.locationLabel,
      ),
    );
    if (!mounted || choice == null) return;

    if (choice == _LocationSourceSheet.gps) {
      _viewModel.useGps();
      return;
    }
    _viewModel.useBuilding(choice);
    final building = campusBuildings[choice];
    if (building != null) _controller.move(building, _controller.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => _buildMap(),
    );
  }

  Widget _buildMap() {
    final restaurants = _viewModel.restaurants;
    final selected = widget.selected;
    // The selected pin goes last so it is drawn on top. It is only drawn when
    // it is one of the Firestore restaurants.
    final ordered = [
      ...restaurants.where((r) => r.id != selected.id),
      ...restaurants.where((r) => r.id == selected.id),
    ];
    final status = _viewModel.isLoading
        ? 'Loading restaurants…'
        : _viewModel.errorMessage;
    final nearby = _viewModel.nearbyRestaurants;
    final hasNearby = nearby.isNotEmpty;

    //flutter map es un widget que muestra mapas interactivos, viene de flutter_map
    //. Se configura un controller para controlar el mapa, y
    //se definen opciones como el centro inicial, zoom, límites y opciones de interacción.
    // Se agregan capas de marcadores para restaurantes y la ubicación del usuario
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: campusCenter,
        initialZoom: 17,
        minZoom: 15.5,
        maxZoom: 19,
        backgroundColor: AppColors.mapLand,
        cameraConstraint: CameraConstraint.contain(bounds: campusBounds),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        //tilelayer es la capa que muestra los tiles del mapa, en este caso de openstreetmap
        //permite agregar marcadores de restaurantes y la ubicación del usuario segun la cuadricula
        TileLayer(urlTemplate: _tileUrl, userAgentPackageName: _userAgent),
        MarkerLayer(
          markers: [
            for (final restaurant in ordered)
              Marker(
                point: restaurant.location,
                width: _pinBoxWidth,
                height: _pinBoxHeight,
                alignment: _pinAlignment,
                child: _RestaurantPin(
                  restaurant: restaurant,
                  selected: restaurant.id == selected.id,
                  // Fade what is far away only when something is close, so
                  // the map never looks empty.
                  dimmed: hasNearby && !_viewModel.isNearby(restaurant),
                  size: _pinSize,
                  onTap: () => widget.onSelect(restaurant),
                ),
              ),
          ],
        ),
        // Drawn above the pins so a restaurant at the same spot cannot hide
        // it; IgnorePointer lets taps reach the pin underneath.
        MarkerLayer(
          markers: [
            // A person's dot when the GPS places the student; a building
            // badge when the position is a building they picked (or the
            // fallback), so it is clear the spot is not measured.
            if (_viewModel.isUsingGps)
              Marker(
                point: _viewModel.userLocation,
                width: _userMarkerSize,
                height: _userMarkerSize,
                child: const IgnorePointer(
                  child: _UserLocationMarker(label: 'Your location'),
                ),
              )
            else
              Marker(
                point: _viewModel.userLocation,
                width: _buildingMarkerSize,
                height: _buildingMarkerSize,
                child: IgnorePointer(
                  child: _BuildingLocationMarker(
                    label: 'Your location, at ${_viewModel.locationLabel}',
                  ),
                ),
              ),
          ],
        ),
        //////const _MapAttribution(),
        if (status != null)
          _MapStatus(message: status)
        else if (_viewModel.closestRestaurant case final closest?)
          _NearbyBanner(
            building: _viewModel.currentBuilding,
            nearby: nearby,
            closest: closest,
            onTap: () => widget.onSelect(hasNearby ? nearby.first : closest),
          ),
        _LocationControls(
          label: _viewModel.isUsingGps
              ? 'GPS'
              : _viewModel.gpsUnavailable
              ? 'At ${_viewModel.locationLabel} · GPS off'
              : 'At ${_viewModel.locationLabel}',
          icon: _viewModel.isUsingGps
              ? Icons.gps_fixed_rounded
              : _viewModel.gpsUnavailable
              ? Icons.gps_off_rounded
              : Icons.apartment_rounded,
          onTapLabel: _chooseLocationSource,
          onCenter: () => _controller.move(
            _viewModel.userLocation,
            _controller.camera.zoom,
          ),
        ),
      ],
    );
  }
}

class _RestaurantPin extends StatelessWidget {
  const _RestaurantPin({
    required this.restaurant,
    required this.selected,
    required this.dimmed,
    required this.size,
    required this.onTap,
  });

  final Restaurant restaurant;
  final bool selected;
  final bool dimmed;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final markerSize = selected ? size : 36.0;
    return Semantics(
      button: true,
      selected: selected,
      label: '${restaurant.name}, ${restaurant.waitTime.spokenLabel}',
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: dimmed && !selected ? 0.4 : 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (selected) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x291E232A),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  restaurant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tag.copyWith(
                    fontSize: 12,
                    color: AppColors.shadowGrey,
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: SizedBox.square(
                dimension: size,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: markerSize,
                    height: markerSize,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.amber : AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.white
                            : AppColors.shadowGrey,
                        width: selected ? 3 : 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x331E232A),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      restaurant.foodIcon,
                      size: selected ? 22 : 18,
                      color: AppColors.shadowGrey,
                    ),
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

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.tealDark,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 3),
          ),
        ),
      ),
    );
  }
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '© OpenStreetMap contributors',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.tag.copyWith(
            fontSize: 10,
            color: AppColors.shadowGrey,
          ),
        ),
      ),
    );
  }
}

class _BuildingLocationMarker extends StatelessWidget {
  const _BuildingLocationMarker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.tealDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x331E232A),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.apartment_rounded,
          size: 16,
          color: AppColors.white,
        ),
      ),
    );
  }
}

/// Context-aware hint: says where the student is and what they can reach in a
/// few minutes. It updates by itself as the GPS position changes.
class _NearbyBanner extends StatelessWidget {
  const _NearbyBanner({
    required this.building,
    required this.nearby,
    required this.closest,
    required this.onTap,
  });

  final String? building;
  final List<Restaurant> nearby;
  final Restaurant closest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final where = building == null
        ? 'Near you'
        : 'Near ${campusBuildingNames[building] ?? building}';
    final minutes = CampusMapViewModel.nearbyMinutes;
    final detail = switch (nearby.length) {
      0 =>
        'Nothing under $minutes min · closest: ${closest.name}, '
            '${closest.walkingMinutes} min',
      1 => '1 restaurant under $minutes min: ${nearby.first.name}',
      _ =>
        '${nearby.length} restaurants under $minutes min · '
            'closest: ${nearby.first.name}',
    };

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.paddingOf(context).top + 84,
          16,
          0,
        ),
        child: Semantics(
          button: true,
          label: '$where. $detail. Tap to see it',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.tealTint,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.teal),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F1E232A),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.near_me_rounded,
                    size: 18,
                    color: AppColors.tealDark,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          where,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.tag.copyWith(
                            fontSize: 13,
                            color: AppColors.tealText,
                          ),
                        ),
                        Text(
                          detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption.copyWith(
                            color: AppColors.shadowGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapStatus extends StatelessWidget {
  const _MapStatus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 84),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F1E232A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message,
          style: AppText.tag.copyWith(
            fontSize: 12,
            color: AppColors.shadowGrey,
          ),
        ),
      ),
    );
  }
}

class _LocationControls extends StatelessWidget {
  const _LocationControls({
    required this.label,
    required this.icon,
    required this.onTapLabel,
    required this.onCenter,
  });

  final String label;
  final IconData icon;

  /// Opens the choice between the GPS and a campus building.
  final VoidCallback onTapLabel;
  final VoidCallback onCenter;

  static final _decoration = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(999),
    boxShadow: const [
      BoxShadow(color: Color(0x1F1E232A), blurRadius: 12, offset: Offset(0, 4)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                heightFactor: 1,
                child: Semantics(
                  button: true,
                  label: '$label. Tap to change where you are',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: onTapLabel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: _decoration,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16, color: AppColors.tealDark),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.tag.copyWith(
                                fontSize: 12,
                                color: AppColors.shadowGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              button: true,
              label: 'Center the map on your location',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onCenter,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: _decoration,
                  child: const Icon(
                    Icons.my_location_rounded,
                    size: 20,
                    color: AppColors.shadowGrey,
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

class _LocationSourceSheet extends StatelessWidget {
  const _LocationSourceSheet({required this.current});

  static const gps = 'GPS';

  /// [gps] or the tag of the building in use.
  final String current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Where are you?', style: AppText.h2),
            ),
            _option(
              context,
              value: gps,
              icon: Icons.gps_fixed_rounded,
              title: 'My location (GPS)',
              subtitle: 'Follows you as you walk',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Or pick the building you are in',
                style: AppText.caption,
              ),
            ),
            for (final entry in campusBuildingNames.entries)
              _option(
                context,
                value: entry.key,
                icon: Icons.apartment_rounded,
                title: entry.value,
              ),
          ],
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required String value,
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    final selected = value == current;
    return ListTile(
      leading: Icon(icon, color: AppColors.tealDark),
      title: Text(title, style: AppText.body),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: AppColors.tealDark)
          : null,
      selected: selected,
      selectedColor: AppColors.tealText,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () => Navigator.of(context).pop(value),
    );
  }
}
