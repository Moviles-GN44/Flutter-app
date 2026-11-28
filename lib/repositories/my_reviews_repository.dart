import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:uniandes_food/models/my_review.dart';
import 'package:uniandes_food/repositories/my_reviews_store.dart';

typedef MyReviewsSnapshot = ({
  List<Map<String, Object?>> rows,
  bool isFromCache,
});

/// Reads the signed-in student's reviews for the My Reviews view.
///
/// - Eventual connectivity: listens to Firestore with metadata changes, so a
///   review written offline shows as pending and turns into sent by itself
///   when it reaches the server.
/// - Caching: restaurant names live in memory for [nameTtl].
/// - Concurrency: missing names are requested in parallel with `Future.wait`,
///   and the summary is built in a background isolate with `compute`.
/// - Local storage: see [MyReviewsStore].
class MyReviewsRepository {
  MyReviewsRepository({
    FirebaseFirestore? firestore,
    MyReviewsStore? store,
    DateTime Function()? now,
  }) : _injected = firestore,
       _store = store ?? MyReviewsStore.instance,
       _now = now ?? DateTime.now;

  static final instance = MyReviewsRepository();

  static const nameTtl = Duration(minutes: 30);
  static const _serverTimeout = Duration(seconds: 6);

  final FirebaseFirestore? _injected;
  final MyReviewsStore _store;
  final DateTime Function() _now;

  final Map<String, ({String name, DateTime savedAt})> _names = {};

  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  MyReviewsStore get store => _store;

  /// The student's reviews, as plain maps that can be sent to an isolate.
  Stream<MyReviewsSnapshot> watch(String uid) {
    return _firestore
        .collection('reviews')
        .where('userId', isEqualTo: uid)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) => (
            rows: [for (final doc in snapshot.docs) _row(doc)],
            isFromCache: snapshot.metadata.isFromCache,
          ),
        );
  }

  /// Names for [ids]: memory first, then the phone, then Firestore.
  Future<Map<String, String>> restaurantNames(Set<String> ids) async {
    final names = <String, String>{};
    final now = _now();

    for (final id in ids) {
      final cached = _names[id];
      if (cached != null && now.difference(cached.savedAt) < nameTtl) {
        names[id] = cached.name;
      }
    }

    var missing = ids.difference(names.keys.toSet());
    if (missing.isEmpty) return names;

    final saved = await _store.names(missing);
    names.addAll(saved);
    _remember(saved);
    missing = missing.difference(saved.keys.toSet());
    if (missing.isEmpty) return names;

    // One request per restaurant, all at the same time.
    final fetched = await Future.wait(missing.map(_fetchName));
    final found = {
      for (final entry in fetched)
        if (entry != null) entry.id: entry.name,
    };
    names.addAll(found);
    _remember(found);
    unawaited(_store.saveNames(found));
    return names;
  }

  /// Builds the list and the totals off the UI thread.
  Future<MyReviewsSummary> summarize(
    List<Map<String, Object?>> rows,
    Map<String, String> names,
  ) {
    return compute(MyReviewsSummary.build, (rows: rows, names: names));
  }

  void clearNameCache() => _names.clear();

  void _remember(Map<String, String> names) {
    final now = _now();
    for (final entry in names.entries) {
      _names[entry.key] = (name: entry.value, savedAt: now);
    }
  }

  Future<({String id, String name})?> _fetchName(String id) async {
    if (id.isEmpty || id.contains('/')) return null;
    try {
      final doc = await _firestore
          .collection('restaurants')
          .doc(id)
          .get()
          .timeout(_serverTimeout);
      final name = doc.data()?['name'];
      return name is String && name.isNotEmpty ? (id: id, name: name) : null;
    } on Exception {
      return null;
    }
  }

  static Map<String, Object?> _row(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return {
      'id': doc.id,
      'restaurantId': _string(data['restaurantId']),
      'restaurantName': _string(data['restaurantName']),
      'rating': (data['rating'] as num?)?.round() ?? 0,
      'comment': _string(data['comment']),
      'isPending': doc.metadata.hasPendingWrites,
      'verified': data['verified'] == true,
      'createdAt': _millis(data['createdAt']),
    };
  }

  static String _string(Object? value) => value is String ? value : '';

  /// The Flutter app saves a Firestore timestamp; other clients may save
  /// milliseconds. Null while the server timestamp is pending.
  static int? _millis(Object? value) => switch (value) {
    Timestamp() => value.millisecondsSinceEpoch,
    int() => value,
    num() => value.toInt(),
    _ => null,
  };
}
