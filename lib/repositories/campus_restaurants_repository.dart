import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:uniandes_food/models/restaurant.dart';

/// Restaurants returned by Firestore, including their data source.
class RestaurantsSnapshot {
  const RestaurantsSnapshot({
    required this.restaurants,
    required this.isFromCache,
  });

  final List<Restaurant> restaurants;
  final bool isFromCache;
}

class CampusRestaurantsRepository {
  CampusRestaurantsRepository({FirebaseFirestore? firestore})
    : _injected = firestore;

  final FirebaseFirestore? _injected;

  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  /// Existing method, kept for compatibility with other screens.
  Stream<List<Restaurant>> watchRestaurants() {
    return watchRestaurantsWithMetadata().map(
      (snapshot) => snapshot.restaurants,
    );
  }

  /// Includes Firestore metadata to identify cached data.

  Stream<RestaurantsSnapshot> watchRestaurantsWithMetadata() {
    try {
      return _firestore
          .collection('restaurants')
          .snapshots(includeMetadataChanges: true)
          .map(
            (snapshot) => RestaurantsSnapshot(
              restaurants: [
                for (final doc in snapshot.docs)
                  Restaurant.fromFirestore(doc.id, doc.data()),
              ],
              isFromCache: snapshot.metadata.isFromCache,
            ),
          );
    } on FirebaseException catch (error) {
      return Stream<RestaurantsSnapshot>.error(error);
    }
  }
}
