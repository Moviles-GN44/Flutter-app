import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:uniandes_food/models/restaurant.dart';

class CampusRestaurantsRepository {
  CampusRestaurantsRepository({FirebaseFirestore? firestore})
    : _injected = firestore;

  final FirebaseFirestore? _injected;

  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  /// Emits the full list of restaurants every time the `restaurants`
  /// collection changes. Firestore serves the cached copy while offline.
  Stream<List<Restaurant>> watchRestaurants() {
    try {
      return _firestore
          .collection('restaurants')
          .snapshots()
          .map(
            (snapshot) => [
              for (final doc in snapshot.docs)
                Restaurant.fromFirestore(doc.id, doc.data()),
            ],
          );
    } on FirebaseException catch (error) {
      return Stream.error(error);
    }
  }
}
