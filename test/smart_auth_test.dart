import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:uniandes_food/models/app_user.dart';
import 'package:uniandes_food/models/restaurant_filters.dart';
import 'package:uniandes_food/repositories/auth_repository.dart';
import 'package:uniandes_food/repositories/user_profile_repository.dart';
import 'package:uniandes_food/services/filter_suggestion_service.dart';
import 'package:uniandes_food/services/location/building_location_strategy.dart';
import 'package:uniandes_food/services/location/preferred_building_sync.dart';
import 'package:uniandes_food/services/location/user_location_tracker.dart';
import 'package:uniandes_food/viewmodels/auth_view_model.dart';
import 'package:uniandes_food/viewmodels/profile_view_model.dart';

const _student = AppUser(
  uid: 'student-1',
  email: 'j.perez@uniandes.edu.co',
  name: 'Juan Perez',
);

class _SignedInAuth implements AuthRepository {
  @override
  AppUser? get currentUser => _student;

  @override
  Stream<AppUser?> authStateChanges() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfiles implements UserProfileRepository {
  _FakeProfiles({this.stored, this.serverAck, Stream<ReviewCount>? reviews})
    : reviews = reviews ?? Stream.value((count: 3, isFromCache: false));

  String? stored;
  final saved = <String>[];

  /// When set, saves stay pending until it completes, like a write made
  /// offline that waits for the server.
  final Completer<void>? serverAck;
  final Stream<ReviewCount> reviews;

  @override
  Future<String?> loadPreferredBuilding(String uid) async => stored;

  @override
  Future<void> savePreferredBuilding(AppUser user, String building) async {
    saved.add('${user.uid}:$building');
    await serverAck?.future;
  }

  @override
  Stream<ReviewCount> watchReviewCount(String uid) => reviews;
}

Map<String, dynamic> _event(
  String applyId,
  int timestamp,
  String type,
  String value,
) => {
  'eventName': 'filter_applied',
  'timestamp': timestamp,
  'params': {'applyId': applyId, 'filterType': type, 'value': value},
};

UserLocationTracker _tracker() => UserLocationTracker(
  // A "GPS" that is never available, so the tracker uses its fallback.
  gpsStrategy: const _FailingStrategy(),
  fallbackStrategy: const BuildingLocationStrategy('ML'),
);

class _FailingStrategy extends BuildingLocationStrategy {
  const _FailingStrategy() : super('GPS');

  @override
  Stream<Never> watchLocation() => Stream.error(Exception('no GPS'));
}

void main() {
  group('Filter suggestion (smart)', () {
    test('Filters used in most recent searches are suggested', () {
      final suggestion = FilterSuggestionService.suggest([
        _event('a', 1, 'dietary', 'vegan'),
        _event('a', 1, 'walking_time', '10'),
        _event('b', 2, 'dietary', 'vegan'),
        _event('b', 2, 'payment', 'Nequi'),
        _event('c', 3, 'dietary', 'vegan'),
        _event('c', 3, 'walking_time', '10'),
      ])!;

      expect(suggestion.basedOn, 3);
      expect(suggestion.filters.dietary, {DietaryOption.vegan});
      expect(suggestion.filters.maxWalkingMinutes, 10);
      // Nequi was used once in three searches: not a habit.
      expect(suggestion.filters.paymentMethods, isEmpty);
    });

    test('One search is not a habit yet', () {
      final suggestion = FilterSuggestionService.suggest([
        _event('a', 1, 'dietary', 'vegan'),
      ]);

      expect(suggestion, isNull);
    });

    test('Searches without filters are ignored', () {
      final suggestion = FilterSuggestionService.suggest([
        _event('a', 1, 'none', 'none'),
        _event('b', 2, 'none', 'none'),
        _event('c', 3, 'price', '0-20000'),
        _event('d', 4, 'price', '0-20000'),
      ])!;

      expect(suggestion.basedOn, 2);
      expect(suggestion.filters.maxPrice, 20000);
    });
  });

  group('Preferred building (auth)', () {
    test('Signing in uses the saved building as the fallback', () async {
      final tracker = _tracker();
      final sync = PreferredBuildingSync(
        auth: AuthViewModel(repository: _SignedInAuth()),
        tracker: tracker,
        repository: _FakeProfiles(stored: 'SD'),
      );
      await pumpEventQueue();

      expect(sync.preferredBuilding, 'SD');
      expect(tracker.label, 'SD');
    });

    test('Choosing a building on the profile saves it', () async {
      final profiles = _FakeProfiles();
      final tracker = _tracker();
      final sync = PreferredBuildingSync(
        auth: AuthViewModel(repository: _SignedInAuth()),
        tracker: tracker,
        repository: profiles,
      );
      await pumpEventQueue();

      sync.setPreferredBuilding('RGD');

      expect(profiles.saved, ['student-1:RGD']);
      expect(sync.preferredBuilding, 'RGD');

      // Picking a building on the map only moves the student.
      tracker.useBuilding('SD');
      expect(profiles.saved, ['student-1:RGD']);
    });

    test('A building chosen offline shows as syncing until the server has '
        'it', () async {
      final serverAck = Completer<void>();
      final sync = PreferredBuildingSync(
        auth: AuthViewModel(repository: _SignedInAuth()),
        tracker: _tracker(),
        repository: _FakeProfiles(serverAck: serverAck),
      );
      await pumpEventQueue();

      sync.setPreferredBuilding('ML');
      await pumpEventQueue();

      // Used right away on the phone, but not confirmed yet.
      expect(sync.preferredBuilding, 'ML');
      expect(sync.isSyncing, isTrue);

      serverAck.complete();
      await pumpEventQueue();

      expect(sync.isSyncing, isFalse);
    });

    test('Unknown building codes are ignored', () async {
      final sync = PreferredBuildingSync(
        auth: AuthViewModel(repository: _SignedInAuth()),
        tracker: _tracker(),
        repository: _FakeProfiles(stored: 'Library'),
      );
      await pumpEventQueue();

      expect(sync.preferredBuilding, isNull);
    });
  });

  group('Profile (auth)', () {
    test('Shows the signed-in student and their review count', () async {
      final viewModel = ProfileViewModel(
        user: _student,
        repository: _FakeProfiles(),
      );
      await pumpEventQueue();

      expect(viewModel.displayName, 'Juan Perez');
      expect(viewModel.initials, 'JP');
      expect(viewModel.reviewCount, 3);
    });

    test('Offline the cached review count is shown and then replaced by '
        'the server count', () async {
      final reviews = StreamController<ReviewCount>();
      final viewModel = ProfileViewModel(
        user: _student,
        repository: _FakeProfiles(reviews: reviews.stream),
      );

      reviews.add((count: 2, isFromCache: true));
      await pumpEventQueue();
      expect(viewModel.reviewCount, 2);
      expect(viewModel.reviewCountIsCached, isTrue);

      // The connection is back.
      reviews.add((count: 4, isFromCache: false));
      await pumpEventQueue();
      expect(viewModel.reviewCount, 4);
      expect(viewModel.reviewCountIsCached, isFalse);

      viewModel.dispose();
      await reviews.close();
    });

    test('Without a name the email is used', () {
      final viewModel = ProfileViewModel(
        user: const AppUser(
          uid: 'x',
          email: 'k.guerrero@uniandes.edu.co',
          name: '',
        ),
        repository: _FakeProfiles(),
      );

      expect(viewModel.displayName, 'k.guerrero');
      expect(viewModel.initials, 'KG');
    });
  });
}
