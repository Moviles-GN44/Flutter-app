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

  // Not drawn: the pins come from Firestore through CampusMapViewModel. Kept so
  // HomeScreen does not change until HomeViewModel reads Firestore too.
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
        const MarkerLayer(
          markers: [
            Marker(
              point: defaultUserLocation,
              width: _userMarkerSize,
              height: _userMarkerSize,
              child: _UserLocationMarker(),
            ),
          ],
        ),
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
                  size: _pinSize,
                  onTap: () => widget.onSelect(restaurant),
                ),
              ),
          ],
        ),
        //////const _MapAttribution(),
        if (status != null) _MapStatus(message: status),
      ],
    );
  }
}

class _RestaurantPin extends StatelessWidget {
  const _RestaurantPin({
    required this.restaurant,
    required this.selected,
    required this.size,
    required this.onTap,
  });

  final Restaurant restaurant;
  final bool selected;
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (selected) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      color: selected ? AppColors.white : AppColors.shadowGrey,
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
    );
  }
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Your location, next to Mario Laserna',
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

class _MapStatus extends StatelessWidget {
  const _MapStatus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
