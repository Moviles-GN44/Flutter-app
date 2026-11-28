import 'package:flutter_test/flutter_test.dart';

import 'package:uniandes_food/models/my_review.dart';

Map<String, Object?> row({
  required String id,
  String restaurantId = 'burger_play_sd',
  int rating = 4,
  int? createdAt,
  Object? isPending = false,
  String restaurantName = '',
}) => {
  'id': id,
  'restaurantId': restaurantId,
  'restaurantName': restaurantName,
  'rating': rating,
  'comment': 'ok',
  'isPending': isPending,
  'verified': true,
  'createdAt': createdAt,
};

void main() {
  test('Counts, average and pending reviews', () {
    final summary = MyReviewsSummary.build((
      rows: [
        row(id: 'a', rating: 3, createdAt: 1000),
        row(id: 'b', rating: 5, createdAt: 3000),
        row(id: 'c', rating: 4, isPending: true),
      ],
      names: const {'burger_play_sd': 'Burger Play - SD'},
    ));

    expect(summary.total, 3);
    expect(summary.average, 4.0);
    expect(summary.pending, 1);
    expect(summary.reviews.first.restaurantName, 'Burger Play - SD');
  });

  test('Pending reviews go first, then the newest', () {
    final summary = MyReviewsSummary.build((
      rows: [
        row(id: 'old', createdAt: 1000),
        row(id: 'pending', isPending: true),
        row(id: 'new', createdAt: 5000),
      ],
      names: const {},
    ));

    expect([for (final r in summary.reviews) r.id], ['pending', 'new', 'old']);
  });

  test('Rows saved in SQLite (booleans as 0/1) keep their saved name', () {
    final summary = MyReviewsSummary.build((
      rows: [row(id: 'a', isPending: 1, restaurantName: 'El Toro (RGD)')],
      names: const {},
    ));

    expect(summary.reviews.single.isPending, isTrue);
    expect(summary.reviews.single.displayName, 'El Toro (RGD)');
  });

  test('No reviews: no average', () {
    final summary = MyReviewsSummary.build((rows: const [], names: const {}));

    expect(summary.isEmpty, isTrue);
    expect(summary.average, isNull);
  });
}
