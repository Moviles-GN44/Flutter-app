import 'package:flutter_test/flutter_test.dart';

import 'package:uniandes_food/data/sample_restaurants.dart';
import 'package:uniandes_food/models/app_user.dart';
import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/repositories/auth_repository.dart';
import 'package:uniandes_food/repositories/review_repository.dart';
import 'package:uniandes_food/viewmodels/scan_qr_view_model.dart';
import 'package:uniandes_food/viewmodels/write_review_view_model.dart';

class _FakeReviewRepository implements ReviewRepository {
  _FakeReviewRepository({this.confirmed = true, this.error});

  final bool confirmed;
  final ReviewException? error;
  Review? saved;

  @override
  Future<bool> addReview(Review review) async {
    if (error != null) throw error!;
    saved = review;
    return confirmed;
  }
}

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

WriteReviewViewModel _reviewViewModel(
  ReviewRepository repository, {
  AppUser? user = _student,
}) {
  return WriteReviewViewModel(
    restaurant: sampleRestaurants.first,
    verified: true,
    repository: repository,
    authRepository: _FakeAuthRepository(user),
  );
}

void main() {
  test('A restaurant QR code verifies the visit', () {
    final viewModel = ScanQrViewModel();

    final verified = viewModel.onCodeDetected('uniandesfood:el-corral');

    expect(verified, isTrue);
    expect(viewModel.status, ScanStatus.verified);
    expect(viewModel.restaurant?.name, 'El Corral Uniandes');
    expect(viewModel.errorMessage, isNull);
  });

  test('A QR code from outside the app is rejected', () {
    final viewModel = ScanQrViewModel();

    final verified = viewModel.onCodeDetected('https://example.com');

    expect(verified, isFalse);
    expect(viewModel.status, ScanStatus.searching);
    expect(viewModel.restaurant, isNull);
    expect(viewModel.errorMessage, isNotNull);
  });

  test('An unknown restaurant id is rejected', () {
    final viewModel = ScanQrViewModel();

    expect(viewModel.onCodeDetected('uniandesfood:does-not-exist'), isFalse);
    expect(viewModel.errorMessage, isNotNull);
  });

  test('Codes detected after verification are ignored', () {
    final viewModel = ScanQrViewModel()
      ..onCodeDetected('uniandesfood:el-corral');

    expect(viewModel.onCodeDetected('uniandesfood:wok'), isFalse);
    expect(viewModel.restaurant?.id, 'el-corral');
  });

  test('Low light is detected and cleared by the light sensor', () {
    final viewModel = ScanQrViewModel()..onLightChanged(5);
    expect(viewModel.isDark, isTrue);

    viewModel.onLightChanged(200);
    expect(viewModel.isDark, isFalse);
  });

  test('Invalid light readings are ignored', () {
    final viewModel = ScanQrViewModel()..onLightChanged(-1);
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
  });
}
