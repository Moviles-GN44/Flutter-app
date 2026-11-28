/// One review written by the signed-in student, as shown in My Reviews.
///
/// Reviews come from both apps (Flutter and Kotlin), so every field is read
/// defensively: a missing value never breaks the list.
class MyReview {
  const MyReview({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.rating,
    required this.comment,
    required this.isPending,
    required this.verified,
    this.createdAt,
  });

  factory MyReview.fromJson(Map<String, Object?> json) {
    final createdAt = json['createdAt'];
    return MyReview(
      id: json['id'] as String? ?? '',
      restaurantId: json['restaurantId'] as String? ?? '',
      restaurantName: json['restaurantName'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      isPending: json['isPending'] == true || json['isPending'] == 1,
      verified: json['verified'] == true || json['verified'] == 1,
      createdAt: createdAt is int
          ? DateTime.fromMillisecondsSinceEpoch(createdAt)
          : null,
    );
  }

  final String id;
  final String restaurantId;

  /// Empty when the restaurant name could not be found.
  final String restaurantName;
  final int rating;
  final String comment;

  /// True while the review is saved on the phone and has not reached the
  /// server yet (it was written offline).
  final bool isPending;

  /// Written after scanning the restaurant's QR code.
  final bool verified;

  /// Null while the review waits for the server to set its date.
  final DateTime? createdAt;

  String get displayName =>
      restaurantName.isNotEmpty ? restaurantName : 'Restaurant';

  Map<String, Object?> toJson() => {
    'id': id,
    'restaurantId': restaurantId,
    'restaurantName': restaurantName,
    'rating': rating,
    'comment': comment,
    'isPending': isPending,
    'verified': verified,
    'createdAt': createdAt?.millisecondsSinceEpoch,
  };
}

/// The list shown in My Reviews plus the three numbers above it.
class MyReviewsSummary {
  const MyReviewsSummary({
    required this.reviews,
    required this.total,
    required this.average,
    required this.pending,
  });

  static const empty = MyReviewsSummary(
    reviews: [],
    total: 0,
    average: null,
    pending: 0,
  );

  /// Pending reviews first (they have no date yet), then newest first.
  final List<MyReview> reviews;
  final int total;

  /// Null when there are no rated reviews.
  final double? average;
  final int pending;

  bool get isEmpty => reviews.isEmpty;

  /// Builds the summary from plain maps.
  ///
  /// Runs in a background isolate (see `MyReviewsRepository`), so it only
  /// takes and returns objects that can be sent between isolates.
  static MyReviewsSummary build(
    ({List<Map<String, Object?>> rows, Map<String, String> names}) input,
  ) {
    final reviews = [
      for (final row in input.rows)
        MyReview.fromJson({
          ...row,
          'restaurantName':
              input.names[row['restaurantId']] ??
              row['restaurantName'] as String? ??
              '',
        }),
    ]..sort(_newestFirst);

    final rated = [
      for (final review in reviews)
        if (review.rating > 0) review.rating,
    ];
    final average = rated.isEmpty
        ? null
        : (rated.reduce((a, b) => a + b) / rated.length * 10).round() / 10;

    return MyReviewsSummary(
      reviews: reviews,
      total: reviews.length,
      average: average,
      pending: reviews.where((review) => review.isPending).length,
    );
  }

  static int _newestFirst(MyReview a, MyReview b) {
    final aDate = a.createdAt;
    final bDate = b.createdAt;
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return -1;
    if (bDate == null) return 1;
    return bDate.compareTo(aDate);
  }
}
