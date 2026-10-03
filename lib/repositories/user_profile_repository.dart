import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:uniandes_food/models/app_user.dart';

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
  Future<int?> countReviews(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: uid)
          .get();
      return snapshot.docs.length;
    } on FirebaseException {
      return null;
    }
  }
}
