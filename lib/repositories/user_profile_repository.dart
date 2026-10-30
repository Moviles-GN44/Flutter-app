import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:uniandes_food/models/app_user.dart';
/// Firestore keeps on the phone (offline) instead of from the server.
typedef ReviewCount = ({int count, bool isFromCache});

/// Reads and writes the signed-in student's profile in Firestore.
///
/// `users/{uid}` is shared with the Kotlin app, which created it with
/// `uid`, `email`, `displayName` and `preferredBuilding`. Writes always use
/// merge so fields this app does not know about are never removed.
class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore}) : _injected = firestore;

  final FirebaseFirestore? _injected;

  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  /// The building code (`ML`, `SD`…) the student chose, if any.
  Future<String?> loadPreferredBuilding(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['preferredBuilding'] as String?;
    } on FirebaseException {
      return null;
    }
  }

  /// Saves [building] and, the first time, the basic profile fields so the
  /// document looks the same as the ones the Kotlin app creates.
  Future<void> savePreferredBuilding(AppUser user, String building) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        if (user.name.isNotEmpty) 'displayName': user.name,
        'preferredBuilding': building,
      }, SetOptions(merge: true));
    } on FirebaseException {
      return;
    }
  }

  /// How many reviews the student has published.
  ///
  /// Offline it emits the count cached on the phone, and the server count as
  /// soon as the connection is back, so the screen updates by itself.
  Stream<ReviewCount> watchReviewCount(String uid) {
    try {
      return _firestore
          .collection('reviews')
          .where('userId', isEqualTo: uid)
          .snapshots(includeMetadataChanges: true)
          .map(
            (snapshot) => (
              count: snapshot.docs.length,
              isFromCache: snapshot.metadata.isFromCache,
            ),
          );
    } on FirebaseException catch (error) {
      return Stream.error(error);
    }
  }
}
