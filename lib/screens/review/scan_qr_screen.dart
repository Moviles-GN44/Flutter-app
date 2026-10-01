import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:light/light.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/navigation/app_navigation.dart';
import 'package:uniandes_food/screens/review/write_review_screen.dart';
import 'package:uniandes_food/theme/app_colors.dart';
import 'package:uniandes_food/theme/app_text.dart';
import 'package:uniandes_food/viewmodels/scan_qr_view_model.dart';
import 'package:uniandes_food/widgets/app_bottom_nav.dart';
import 'package:uniandes_food/widgets/food_image_placeholder.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _openDelay = Duration(milliseconds: 1400);

  late final AnimationController _scanLine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  final _viewModel = ScanQrViewModel();
  final _scanner = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  Timer? _openTimer;
  StreamSubscription<int>? _lightSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lightSubscription = Light().lightSensorStream.listen(
      _viewModel.onLightChanged,
      onError: (Object _) {},
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lightSubscription?.cancel();
    _openTimer?.cancel();
    _scanLine.dispose();
    _scanner.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_viewModel.isVerified || !_scanner.value.hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_scanner.start());
      case AppLifecycleState.inactive:
        unawaited(_scanner.stop());
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (!_viewModel.onCodeDetected(code)) return;

    HapticFeedback.mediumImpact();
    _scanLine.stop();
    unawaited(_scanner.stop());
    _openTimer = Timer(
      _openDelay,
      () => _openReview(_viewModel.restaurant!, true),
    );
  }

  void _openReview(Restaurant restaurant, bool verified) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            WriteReviewScreen(restaurant: restaurant, verified: verified),
      ),
    );
  }

  Future<void> _searchManually() async {
    await _scanner.stop();
    if (!mounted) return;

    final picked = await showModalBottomSheet<Restaurant>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (_) =>
          _NearbyRestaurantsSheet(restaurants: _viewModel.nearbyRestaurants),
    );
    if (!mounted) return;

    if (picked != null) {
      _openReview(picked, false);
    } else {
      unawaited(_scanner.start());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => _buildScreen(context),
    );
  }

  Widget _buildScreen(BuildContext context) {
    final verified = _viewModel.isVerified;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.shadowGrey,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.white,
                        backgroundColor: AppColors.white.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Scan QR code',
                      style: AppText.h2.copyWith(color: AppColors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _Viewfinder(
                    scanLine: _scanLine,
                    verified: verified,
                    camera: MobileScanner(
                      controller: _scanner,
                      onDetect: _onDetect,
                      placeholderBuilder: (_) => const SizedBox.shrink(),
                      errorBuilder: (_, error) =>
                          _CameraUnavailable(error: error),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _scanner,
                      builder: (context, state, _) {
                        final torchOn = state.torchState == TorchState.on;
                        return _CameraControl(
                          icon: torchOn
                              ? Icons.flashlight_on_rounded
                              : Icons.flashlight_off_rounded,
                          label: torchOn ? 'Light on' : 'Light off',
                          tooltip: torchOn
                              ? 'Turn flashlight off'
                              : 'Turn flashlight on',
                          onPressed: state.torchState == TorchState.unavailable
                              ? null
                              : _scanner.toggleTorch,
                          highlighted: _viewModel.isDark && !torchOn,
                        );
                      },
                    ),
                    _CameraControl(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      tooltip: 'Scan a QR code from a photo',
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: verified
                      ? _VerifiedCard(
                          key: const ValueKey('verified'),
                          restaurantName: _viewModel.restaurant!.name,
                        )
                      : _SearchingCard(
                          key: const ValueKey('searching'),
                          errorMessage:
                              _viewModel.errorMessage ??
                              (_viewModel.isDark
                                  ? 'Low light detected. Turn on the flashlight.'
                                  : null),
                        ),
                ),
              ),
              SizedBox(
                height: 48,
                child: verified
                    ? null
                    : TextButton(
                        onPressed: _searchManually,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.white,
                        ),
                        child: const Text(
                          'Can’t scan the code? Search nearby restaurants',
                        ),
                      ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
        floatingActionButton: const ScanFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: AppBottomNav(
          currentIndex: null,
          onSelect: (index) => AppNavigation.goToTab(context, index),
        ),
      ),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder({
    required this.scanLine,
    required this.verified,
    required this.camera,
  });

  final Animation<double> scanLine;
  final bool verified;
  final Widget camera;

  static const _frameSize = 230.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: verified
          ? 'QR code recognised'
          : 'Camera viewfinder. Point at the restaurant QR code',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.cameraTop, AppColors.cameraBottom],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: _ViewfinderBackdropPainter()),
              ),
              Positioned.fill(child: camera),
              Center(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: _frameSize,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _FrameCornersPainter(
                                  color: verified
                                      ? AppColors.teal
                                      : AppColors.amber,
                                ),
                              ),
                            ),
                            if (verified)
                              const Center(
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  size: 72,
                                  color: AppColors.teal,
                                ),
                              )
                            else
                              AnimatedBuilder(
                                animation: scanLine,
                                builder: (context, child) => Positioned(
                                  left: 20,
                                  right: 20,
                                  top: 20 + scanLine.value * (_frameSize - 40),
                                  child: child!,
                                ),
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: AppColors.teal,
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.teal.withValues(
                                          alpha: 0.6,
                                        ),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        verified
                            ? 'Code recognised'
                            : 'Point at the restaurant’s QR code',
                        style: AppText.bodyStrong.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraControl extends StatelessWidget {
  const _CameraControl({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          iconSize: 22,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            minimumSize: const Size.square(48),
            foregroundColor: highlighted
                ? AppColors.shadowGrey
                : AppColors.white,
            backgroundColor: highlighted
                ? AppColors.amber
                : AppColors.white.withValues(alpha: 0.12),
            disabledForegroundColor: AppColors.white.withValues(alpha: 0.38),
            disabledBackgroundColor: AppColors.white.withValues(alpha: 0.06),
          ),
        ),
        const SizedBox(width: 8),
        ExcludeSemantics(
          child: Text(
            label,
            style: AppText.caption.copyWith(color: AppColors.white),
          ),
        ),
      ],
    );
  }
}

class _SearchingCard extends StatelessWidget {
  const _SearchingCard({super.key, this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Looking for a QR code…',
                    style: AppText.bodyStrong.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    errorMessage ?? 'Hold your phone about 20 cm from the code',
                    style: AppText.caption.copyWith(
                      color: errorMessage == null
                          ? AppColors.white.withValues(alpha: 0.75)
                          : AppColors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifiedCard extends StatelessWidget {
  const _VerifiedCard({super.key, required this.restaurantName});

  final String restaurantName;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.tealDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.verified_rounded,
              size: 28,
              color: AppColors.white,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visit verified!',
                    style: AppText.h3.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'At $restaurantName. Opening review…',
                    style: AppText.caption.copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final message = error.errorCode == MobileScannerErrorCode.permissionDenied
        ? 'Allow camera access in Settings to scan the code.'
        : 'The camera is not available on this device.';

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              size: 20,
              color: AppColors.amber,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: AppText.caption.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyRestaurantsSheet extends StatelessWidget {
  const _NearbyRestaurantsSheet({required this.restaurants});

  final List<Restaurant> restaurants;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Restaurants near you', style: AppText.h2),
            const SizedBox(height: 4),
            const Text(
              'Reviews added without scanning are not marked as verified.',
              style: AppText.caption,
            ),
            const SizedBox(height: 8),
            for (final restaurant in restaurants)
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => Navigator.of(context).pop(restaurant),
                leading: SizedBox.square(
                  dimension: 52,
                  child: RestaurantThumbnail(
                    restaurant: restaurant,
                    aspectRatio: 1,
                    iconSize: 24,
                  ),
                ),
                title: Text(restaurant.name, style: AppText.h3),
                subtitle: Text(
                  '${restaurant.distanceMeters} m · '
                  '${restaurant.walkingMinutes} min walk',
                  style: AppText.caption,
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FrameCornersPainter extends CustomPainter {
  const _FrameCornersPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const length = 44.0;
    const radius = 22.0;
    const corner = Radius.circular(radius);
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, length)
      ..lineTo(0, radius)
      ..arcToPoint(const Offset(radius, 0), radius: corner)
      ..lineTo(length, 0)
      ..moveTo(w - length, 0)
      ..lineTo(w - radius, 0)
      ..arcToPoint(Offset(w, radius), radius: corner)
      ..lineTo(w, length)
      ..moveTo(w, h - length)
      ..lineTo(w, h - radius)
      ..arcToPoint(Offset(w - radius, h), radius: corner)
      ..lineTo(w - length, h)
      ..moveTo(length, h)
      ..lineTo(radius, h)
      ..arcToPoint(Offset(0, h - radius), radius: corner)
      ..lineTo(0, h - length);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FrameCornersPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ViewfinderBackdropPainter extends CustomPainter {
  const _ViewfinderBackdropPainter();

  static const _spots = [
    (0.15, 0.20, 60.0, 0.06),
    (0.85, 0.15, 40.0, 0.05),
    (0.78, 0.80, 80.0, 0.05),
    (0.20, 0.85, 50.0, 0.04),
    (0.50, 0.05, 30.0, 0.05),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (x, y, radius, alpha) in _spots) {
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        radius,
        Paint()
          ..color = AppColors.white.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ViewfinderBackdropPainter oldDelegate) =>
      false;
}
