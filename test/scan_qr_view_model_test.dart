import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uniandes_food/data/sample_restaurants.dart';
import 'package:uniandes_food/models/app_user.dart';
import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/repositories/auth_repository.dart';
import 'package:uniandes_food/repositories/campus_restaurants_repository.dart';
import 'package:uniandes_food/repositories/restaurant_repository.dart';
import 'package:uniandes_food/repositories/review_repository.dart';
import 'package:uniandes_food/services/location/building_location_strategy.dart';
import 'package:uniandes_food/services/location/user_location_tracker.dart';
import 'package:uniandes_food/services/telemetry_service.dart';
import 'package:uniandes_food/viewmodels/home_view_model.dart';
import 'package:uniandes_food/viewmodels/scan_qr_view_model.dart';
import 'package:uniandes_food/viewmodels/write_review_view_model.dart';

class _FakeReviewRepository implements ReviewRepository {
  _FakeReviewRepository({
    this.confirmed = true,
    this.error,
    this.stored = const [],
    this.fromCache = false,
  });

  final bool confirmed;
  final ReviewException? error;
  final List<Review> stored;
  final bool fromCache;
  Review? saved;

  @override
  Future<ReviewList> getReviews(String restaurantId) async =>
      (reviews: stored, isFromCache: fromCache);

  @override
  Future<bool> addReview(Review review) async {
    if (error != null) throw error!;
    saved = review;
    return confirmed;
  }
}

class _FakeRestaurantRepository implements RestaurantRepository {
  bool reachable = true;

  @override
  Future<Restaurant?> fetchRestaurantById(String id) async {
    if (!reachable || id != 'el_toro_rgd') return null;
    return Restaurant.fromFirestore(id, const {
      'name': 'El Toro - RGD',
      'category': 'Executive Lunch',
      'rating': 4.5,
      'reviewCount': 2,
      'waitTimeCategory': 'LONG',
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeConnectivity implements Connectivity {
  _FakeConnectivity({required bool online})
    : _current = online ? ConnectivityResult.wifi : ConnectivityResult.none;

  final _changes = StreamController<List<ConnectivityResult>>.broadcast();
  ConnectivityResult _current;

  void set({required bool online}) {
    _current = online ? ConnectivityResult.wifi : ConnectivityResult.none;
    _changes.add([_current]);
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _changes.stream;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [_current];
}

class _FakeCampusRestaurantsRepository implements CampusRestaurantsRepository {
  _FakeCampusRestaurantsRepository(this.restaurants);

  final List<Restaurant> restaurants;

  @override
  Stream<List<Restaurant>> watchRestaurants() => Stream.value(restaurants);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Restaurant _campusRestaurant(String id, double latitudeOffset) =>
    Restaurant.fromFirestore(id, {
      'name': id,
      'latitude': 4.6029 + latitudeOffset,
      'longitude': -74.0650,
    });

ScanQrViewModel _scanViewModel({
  _FakeRestaurantRepository? repository,
  _FakeConnectivity? connectivity,
  List<Restaurant> campusRestaurants = const [],
}) => ScanQrViewModel(
  repository: repository ?? _FakeRestaurantRepository(),
  campusRepository: _FakeCampusRestaurantsRepository(campusRestaurants),
  locationTracker: UserLocationTracker(
    gpsStrategy: const BuildingLocationStrategy('ML'),
  ),
  connectivity: connectivity ?? _FakeConnectivity(online: true),
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.currentUser);

  @override
  final AppUser? currentUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _student = AppUser(
  uid: 'test-user',
  email: 'test@uniandes.edu.co',
  name: 'Test User',
);

class _FakeTelemetryService implements TelemetryService {
  final List<String> events = [];

  @override
  Future<void> trackReviewEvent({
    required String eventName,
    required String method,
    required String restaurantId,
  }) async => events.add('$eventName:$method');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

WriteReviewViewModel _reviewViewModel(
  ReviewRepository repository, {
  AppUser? user = _student,
  bool verified = true,
  TelemetryService? telemetry,
}) {
  return WriteReviewViewModel(
    restaurant: sampleRestaurants.first,
    verified: verified,
    repository: repository,
    authRepository: _FakeAuthRepository(user),
    telemetryService: telemetry ?? _FakeTelemetryService(),
  );
}

void main() {
  test('A restaurant QR code verifies the visit', () async {
    final viewModel = _scanViewModel();

    final verified = await viewModel.onCodeDetected('el_toro_rgd');

    expect(verified, isTrue);
    expect(viewModel.status, ScanStatus.verified);
    expect(viewModel.restaurant?.name, 'El Toro - RGD');
    expect(viewModel.restaurant?.waitTime, WaitTime.over15);
    expect(viewModel.errorMessage, isNull);
  });

  test('A QR code from outside the app is rejected', () async {
    final viewModel = _scanViewModel();

    final verified = await viewModel.onCodeDetected('https://example.com');

    expect(verified, isFalse);
    expect(viewModel.status, ScanStatus.searching);
    expect(viewModel.restaurant, isNull);
    expect(viewModel.errorMessage, isNotNull);
  });

  test('An unknown restaurant id is rejected', () async {
    final viewModel = _scanViewModel();

    expect(await viewModel.onCodeDetected('does_not_exist'), isFalse);
    expect(viewModel.errorMessage, isNotNull);
  });

  test('An invalid code does not block the scanner', () async {
    final viewModel = _scanViewModel();

    expect(await viewModel.onCodeDetected('..'), isFalse);
    expect(await viewModel.onCodeDetected('el_toro_rgd'), isTrue);
  });

  test('Codes detected after verification are ignored', () async {
    final viewModel = _scanViewModel();
    await viewModel.onCodeDetected('el_toro_rgd');

    expect(await viewModel.onCodeDetected('one_burrito_ml'), isFalse);
    expect(viewModel.restaurant?.id, 'el_toro_rgd');
  });

  test('Offline, an unknown code waits for the connection', () async {
    final repository = _FakeRestaurantRepository()..reachable = false;
    final viewModel = _scanViewModel(
      repository: repository,
      connectivity: _FakeConnectivity(online: false),
    );
    await Future<void>.delayed(Duration.zero);

    expect(await viewModel.onCodeDetected('el_toro_rgd'), isFalse);
    expect(viewModel.errorMessage, startsWith('No connection'));
  });

  test('The pending code is verified when the connection is back', () async {
    final repository = _FakeRestaurantRepository()..reachable = false;
    final connectivity = _FakeConnectivity(online: false);
    final viewModel = _scanViewModel(
      repository: repository,
      connectivity: connectivity,
    );
    await Future<void>.delayed(Duration.zero);
    await viewModel.onCodeDetected('el_toro_rgd');

    repository.reachable = true;
    connectivity.set(online: true);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.isVerified, isTrue);
    expect(viewModel.restaurant?.id, 'el_toro_rgd');
  });

  test('Offline, a code from outside the app is still rejected', () async {
    final viewModel = _scanViewModel(
      connectivity: _FakeConnectivity(online: false),
    );
    await Future<void>.delayed(Duration.zero);

    expect(await viewModel.onCodeDetected('https://example.com'), isFalse);
    expect(
      viewModel.errorMessage,
      'This QR code is not from a campus restaurant.',
    );
  });

  test('Manual search lists the four closest campus restaurants', () async {
    final viewModel = _scanViewModel(
      campusRestaurants: [
        _campusRestaurant('far', 0.005),
        _campusRestaurant('closest', 0.0005),
        _campusRestaurant('third', 0.002),
        _campusRestaurant('second', 0.001),
        _campusRestaurant('fourth', 0.003),
      ],
    );
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.nearbyRestaurants.map((r) => r.id), [
      'closest',
      'second',
      'third',
      'fourth',
    ]);
  });

  test('Low light is detected and cleared by the light sensor', () {
    final viewModel = _scanViewModel()..onLightChanged(5);
    expect(viewModel.isDark, isTrue);

    viewModel.onLightChanged(200);
    expect(viewModel.isDark, isFalse);
  });

  test('Invalid light readings are ignored', () {
    final viewModel = _scanViewModel()..onLightChanged(-1);
    expect(viewModel.isDark, isFalse);
  });

  group('WriteReviewViewModel', () {
    test('A review needs a rating and a wait time to be published', () {
      final viewModel = _reviewViewModel(_FakeReviewRepository());

      expect(viewModel.canPublish, isFalse);
      viewModel.setRating(4);
      expect(viewModel.canPublish, isFalse);
      viewModel.setWaitTime(WaitTime.fiveTo15);
      expect(viewModel.canPublish, isTrue);
    });

    test('Publishing saves the review with the signed in student', () async {
      final repository = _FakeReviewRepository();
      final viewModel = _reviewViewModel(repository)
        ..setRating(5)
        ..setWaitTime(WaitTime.under5)
        ..toggleTag('Good price');

      final outcome = await viewModel.publish('  Great burger  ');

      expect(outcome, PublishOutcome.published);
      expect(repository.saved?.restaurantId, 'el-corral');
      expect(repository.saved?.userId, 'test-user');
      expect(repository.saved?.rating, 5);
      expect(repository.saved?.comment, 'Great burger');
      expect(repository.saved?.tags, ['Good price']);
      expect(repository.saved?.verified, isTrue);
    });

    test('A review sent without connection is saved offline', () async {
      final viewModel =
          _reviewViewModel(_FakeReviewRepository(confirmed: false))
            ..setRating(3)
            ..setWaitTime(WaitTime.over15);

      expect(await viewModel.publish(''), PublishOutcome.savedOffline);
    });

    test('A guest cannot publish a review', () async {
      final repository = _FakeReviewRepository();
      final viewModel = _reviewViewModel(repository, user: null)
        ..setRating(4)
        ..setWaitTime(WaitTime.under5);

      expect(await viewModel.publish(''), PublishOutcome.failed);
      expect(viewModel.errorMessage, isNotNull);
      expect(repository.saved, isNull);
    });

    test('A backend error is shown to the student', () async {
      final viewModel =
          _reviewViewModel(
              _FakeReviewRepository(error: const ReviewException('Denied')),
            )
            ..setRating(2)
            ..setWaitTime(WaitTime.fiveTo15);

      expect(await viewModel.publish(''), PublishOutcome.failed);
      expect(viewModel.errorMessage, 'Denied');
      expect(viewModel.isPublishing, isFalse);
    });

    test('Started and published reviews are tracked by method', () async {
      final telemetry = _FakeTelemetryService();
      final viewModel =
          _reviewViewModel(
              _FakeReviewRepository(),
              verified: false,
              telemetry: telemetry,
            )
            ..setRating(4)
            ..setWaitTime(WaitTime.under5);
      expect(telemetry.events, ['review_started:manual']);

      await viewModel.publish('');

      expect(telemetry.events, [
        'review_started:manual',
        'review_published:manual',
      ]);
    });
  });

  group('Reported wait time', () {
    Review report(WaitTime waitTime, {required bool verified}) => Review(
      restaurantId: 'el-corral',
      userId: 'test-user',
      userName: 'Test User',
      rating: 4,
      comment: '',
      waitTime: waitTime,
      tags: const [],
      verified: verified,
      createdAt: DateTime.now(),
    );

    test('Verified recent reports weigh more', () async {
      final viewModel = HomeViewModel(
        initialRestaurant: sampleRestaurants.first,
        reviewRepository: _FakeReviewRepository(
          stored: [
            report(WaitTime.over15, verified: true),
            report(WaitTime.fiveTo15, verified: false),
          ],
        ),
      );

      await viewModel.loadReportedWait();

      expect(viewModel.reportedWait, WaitTime.over15);
      expect(viewModel.reportCount, 2);
      expect(viewModel.reportsFromCache, isFalse);
    });

    test('Offline, the estimate comes from saved reports', () async {
      final viewModel = HomeViewModel(
        initialRestaurant: sampleRestaurants.first,
        reviewRepository: _FakeReviewRepository(
          stored: [report(WaitTime.under5, verified: true)],
          fromCache: true,
        ),
      );

      await viewModel.loadReportedWait();

      expect(viewModel.reportedWait, WaitTime.under5);
      expect(viewModel.reportsFromCache, isTrue);
    });

    test('Without reports there is no estimate', () async {
      final viewModel = HomeViewModel(
        initialRestaurant: sampleRestaurants.first,
        reviewRepository: _FakeReviewRepository(),
      );

      await viewModel.loadReportedWait();

      expect(viewModel.reportedWait, isNull);
      expect(viewModel.reportCount, 0);
    });
  });

  test('A new review updates the restaurant average rating', () {
    expect(ReviewRepository.newAverage(4.5, 2, 5), 4.7);
    expect(ReviewRepository.newAverage(0, 0, 3), 3.0);
  });
}
