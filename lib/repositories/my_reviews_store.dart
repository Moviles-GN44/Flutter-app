import 'package:sqflite/sqflite.dart';

import 'package:uniandes_food/models/my_review.dart';

typedef StoredReviews = ({List<Map<String, Object?>> rows, DateTime? syncedAt});

/// Local storage for My Reviews: a SQLite database on the phone.
///
/// Firestore's offline cache keeps the review documents, but not the names of
/// restaurants the student never opened, and it can be cleared by the system.
/// This database keeps the last list the server confirmed, with the
/// restaurant names already resolved, so the view is complete offline even
/// after the app is restarted.
class MyReviewsStore {
  MyReviewsStore({Future<Database> Function()? open})
    : _open = open ?? _openDefault;

  static final instance = MyReviewsStore();

  static const _fileName = 'my_reviews.db';

  final Future<Database> Function() _open;
  Future<Database>? _database;

  Future<Database> get _db => _database ??= _open();

  static Future<Database> _openDefault() async {
    final path = '${await getDatabasesPath()}/$_fileName';
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        final batch = db.batch()
          ..execute('''
            CREATE TABLE my_reviews (
              uid TEXT NOT NULL,
              id TEXT NOT NULL,
              restaurantId TEXT NOT NULL,
              restaurantName TEXT NOT NULL,
              rating INTEGER NOT NULL,
              comment TEXT NOT NULL,
              isPending INTEGER NOT NULL,
              verified INTEGER NOT NULL,
              createdAt INTEGER,
              PRIMARY KEY (uid, id)
            )
          ''')
          ..execute('''
            CREATE TABLE my_reviews_sync (
              uid TEXT PRIMARY KEY,
              syncedAt INTEGER NOT NULL
            )
          ''')
          ..execute('''
            CREATE TABLE restaurant_names (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL
            )
          ''');
        await batch.commit(noResult: true);
      },
    );
  }

  /// The last list saved for [uid], or no rows when nothing was saved yet.
  Future<StoredReviews> load(String uid) async {
    try {
      final db = await _db;
      final rows = await db.query(
        'my_reviews',
        where: 'uid = ?',
        whereArgs: [uid],
      );
      final sync = await db.query(
        'my_reviews_sync',
        where: 'uid = ?',
        whereArgs: [uid],
      );
      final syncedAt = sync.isEmpty ? null : sync.first['syncedAt'] as int?;
      return (
        rows: rows,
        syncedAt: syncedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(syncedAt),
      );
    } on Exception {
      return (rows: const <Map<String, Object?>>[], syncedAt: null);
    }
  }

  /// Replaces the saved list of [uid] in one transaction, so a crash never
  /// leaves half a list on the phone.
  Future<void> replace(
    String uid,
    List<MyReview> reviews,
    DateTime syncedAt,
  ) async {
    try {
      final db = await _db;
      await db.transaction((txn) async {
        await txn.delete('my_reviews', where: 'uid = ?', whereArgs: [uid]);
        final batch = txn.batch();
        for (final review in reviews) {
          batch.insert('my_reviews', {
            'uid': uid,
            ...review.toJson(),
            'isPending': review.isPending ? 1 : 0,
            'verified': review.verified ? 1 : 0,
          });
        }
        batch.insert('my_reviews_sync', {
          'uid': uid,
          'syncedAt': syncedAt.millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        await batch.commit(noResult: true);
      });
    } on Exception {
      return;
    }
  }

  /// Restaurant names saved on the phone, for the ids that have one.
  Future<Map<String, String>> names(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return const {};
    try {
      final db = await _db;
      final rows = await db.query(
        'restaurant_names',
        where: 'id IN (${List.filled(list.length, '?').join(',')})',
        whereArgs: list,
      );
      return {
        for (final row in rows) row['id'] as String: row['name'] as String,
      };
    } on Exception {
      return const {};
    }
  }

  Future<void> saveNames(Map<String, String> names) async {
    if (names.isEmpty) return;
    try {
      final db = await _db;
      final batch = db.batch();
      for (final entry in names.entries) {
        batch.insert('restaurant_names', {
          'id': entry.key,
          'name': entry.value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } on Exception {
      return;
    }
  }
}
